import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import thư viện lưu trữ
import 'package:image_converter_app/l10n/app_localizations.dart';
import 'services/auth_service.dart';
import 'blocs/auth_bloc.dart';
import 'blocs/language_cubit.dart';
import 'blocs/font_size_cubit.dart';
import 'blocs/theme_cubit.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart'; // Import HomeScreen
import 'blocs/home_bloc.dart';

void main() async {
  // 1. Đảm bảo Flutter binding đã sẵn sàng để gọi code bất đồng bộ
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load các cài đặt đã lưu từ SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('is_dark') ?? false; // Mặc định là Sáng (false)
  final languageCode = prefs.getString('language_code') ?? 'vi'; // Mặc định Tiếng Việt
  final fontSize = prefs.getDouble('font_size') ?? 1.0; // Mặc định 1.0

  runApp(MyApp(
    isDark: isDark,
    languageCode: languageCode,
    fontSize: fontSize,
  ));
}

class MyApp extends StatelessWidget {
  // Các biến để nhận giá trị đã load
  final bool isDark;
  final String languageCode;
  final double fontSize;

  const MyApp({
    super.key,
    required this.isDark,
    required this.languageCode,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => AuthService()),
      ],
      child: MultiBlocProvider(
        providers: [
          // AUTH BLOC: Vừa tạo ra là bắt check token ngay lập tức (add event)
          BlocProvider(
            create: (context) => AuthBloc(context.read<AuthService>())..add(CheckAuthRequested()),
          ),
          // Truyền giá trị đã load vào các Cubit
          BlocProvider(create: (context) => LanguageCubit(languageCode: languageCode)),
          BlocProvider(create: (context) => FontSizeCubit(initialSize: fontSize)),
          BlocProvider(create: (context) => ThemeCubit(isDark: isDark)),
          BlocProvider(create: (context) => HomeBloc()..add(LoadHistoryRequested())),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return BlocBuilder<LanguageCubit, Locale>(
              builder: (context, locale) {
                return BlocBuilder<FontSizeCubit, double>(
                  builder: (context, fontScale) {
                    return MaterialApp(
                      title: 'ShiftSpeed',
                      debugShowCheckedModeBanner: false,

                      // Theme & Locale & Font
                      themeMode: themeMode,
                      theme: ThemeData.light(useMaterial3: true),
                      darkTheme: ThemeData.dark(useMaterial3: true),
                      locale: locale,
                      localizationsDelegates: const [
                        AppLocalizations.delegate,
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                      supportedLocales: const [
                        Locale('vi'),
                        Locale('en'),
                      ],
                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(fontScale),
                          ),
                          child: child!,
                        );
                      },

                      // --- LOGIC CHỌN MÀN HÌNH KHỞI ĐỘNG ---
                      // Dùng BlocBuilder của AuthBloc để quyết định màn hình nào hiện ra đầu tiên
                      home: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is AuthSuccess) {
                            return HomeScreen(); // Đã đăng nhập -> Vào Home
                          }
                          // Nếu đang check hoặc chưa đăng nhập -> Vào Login
                          return LoginScreen();
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}