import 'dart:io';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Danh sách các thông báo tạo động lực cho ngày mới
  final List<String> _morningMessages = [
    "🌅 Chào buổi sáng! Chúc bạn một ngày tàn đầy năng lượng và hiệu quả! 💪", // Morning
    "✨ Ngày mới tuyệt vời nha! Đừng quên bạn là phiên bản 'Pro Max' của chính mình! ✨", // Motivational
    "🍀 Hôm nay của bạn thế nào? Hy vọng mọi điều suôn sẻ sẽ đến với bạn! 🍀", // Hopeful
    "🔥 Năng lượng tích cực đã được nạp đầy! Chúc bạn bứt phá mọi mục tiêu hôm nay! 🚀", // Energetic
    "🌟 Cố lên nha! Mọi nỗ lực của bạn sẽ sớm đơm hoa kết trái! 🌟", // Encouraging
    "☕ Bắt đầu ngày mới với nụ cười trên môi nhé! Chúc bạn hái ra tiền hôm nay! 💰", // Fun/Wealth
    "🌈 Hãy để ngày hôm nay trở thành kiệt tác của bạn! Chúc bạn thành công! 🎨", // Creative
  ];

  Future<void> init() async {
    // 1. Cấu hình Timezone
    tz.initializeTimeZones();
    
    // Tự động lấy múi giờ của thiết bị để set location chính xác
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      print("Could not get local timezone: $e");
      // Fallback nếu lỗi: Thử dùng 'Asia/Ho_Chi_Minh' hoặc mặc định UTC
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      } catch (_) {}
    }

    // 2. Cấu hình Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // 3. Cấu hình iOS
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      // onDidReceiveLocalNotification removed on newer versions (handled via stream/callback)
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // 4. Khởi tạo plugin
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Xử lý khi user tap vào thông báo (nếu cần)
        print('User tapped on notification: ${response.payload}');
      },
    );

    // 5. Yêu cầu quyền (quan trọng cho Android 13+)
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      // await androidImplementation?.requestExactAlarmsPermission(); // Nếu cần chính xác từng giây (thường không cần cho daily greeting)
    } else if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  /// Lên lịch thông báo chào buổi sáng hàng ngày
  Future<void> scheduleDailyMorningGreeting({
    int hour = 7, // Mặc định 7h07 sáng (số may mắn)
    int minute = 7,
  }) async {
    // Chọn ngẫu nhiên một câu chúc
    final random = Random();
    final message = _morningMessages[random.nextInt(_morningMessages.length)];

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: 0,
      title: 'Chào ngày mới! 👋',
      body: message,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'morning_greeting_v2', // Channel ID MỚI - buộc Android tạo lại channel
          'Chào Ngày Mới', // Channel Name
          channelDescription: 'Thông báo chào buổi sáng hàng ngày',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''), // Để hiện text dài
          sound: RawResourceAndroidNotificationSound('morning_greeting'), // Âm thanh tuỳ chỉnh
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'morning_greeting.wav', // Âm thanh tuỳ chỉnh cho iOS
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Lặp lại theo thời gian (giờ:phút) hàng ngày
    );
    
    print("Đã lên lịch chào buổi sáng lúc $hour:$minute với lời chúc: $message");
  }

  /// Tính toán thời gian cho lần thông báo tiếp theo
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Demo: Gửi thông báo ngay lập tức để test
  Future<void> showInstantGreeting() async {
    final random = Random();
    final message = _morningMessages[random.nextInt(_morningMessages.length)];

    await flutterLocalNotificationsPlugin.show(
      id: 1,
      title: 'Demo Chào ngày mới! 👋',
      body: message,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'morning_greeting_v2', // Channel ID MỚI
          'Chào Ngày Mới',
          channelDescription: 'Thông báo chào buổi sáng hàng ngày',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('morning_greeting'), // Âm thanh tuỳ chỉnh
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'morning_greeting.wav', // Âm thanh tuỳ chỉnh cho iOS
        ),
      ),
    );
  }
}
