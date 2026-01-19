import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import 'dart:async';
import 'services/auth_service.dart';
import 'blocs/auth_bloc.dart';
import 'blocs/language_cubit.dart';
import 'blocs/font_size_cubit.dart';
import 'blocs/theme_cubit.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'blocs/home_bloc.dart';
import 'theme/app_theme.dart';

/// Global BlocObserver để log và handle errors từ tất cả Blocs
class AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    print('❌ [${bloc.runtimeType}] Error: $error');
    print('📍 StackTrace: $stackTrace');
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    print('🔄 [${bloc.runtimeType}] ${transition.currentState.runtimeType} → ${transition.nextState.runtimeType}');
    super.onTransition(bloc, transition);
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    print('📣 [${bloc.runtimeType}] Event: ${event.runtimeType}');
    super.onEvent(bloc, event);
  }
}

void main() async {
  // 1. Đảm bảo Flutter binding đã sẵn sàng để gọi code bất đồng bộ
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Setup Global Error Handler
  FlutterError.onError = (FlutterErrorDetails details) {
    print('❌ [FlutterError] ${details.exceptionAsString()}');
    print('📍 ${details.stack}');
    // Không crash app, chỉ log lỗi
  };

  // 3. Setup BlocObserver để monitor tất cả Blocs
  Bloc.observer = AppBlocObserver();

  // 4. Load các cài đặt đã lưu từ SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('is_dark') ?? false; // Mặc định là Sáng (false)
  final languageCode = prefs.getString('language_code') ?? 'vi'; // Mặc định Tiếng Việt
  final fontSize = prefs.getDouble('font_size') ?? 1.0; // Mặc định 1.0

  // 5. Wrap runApp với error zone để catch async errors
  runZonedGuarded(
    () {
      runApp(MyApp(
        isDark: isDark,
        languageCode: languageCode,
        fontSize: fontSize,
      ));
    },
    (error, stackTrace) {
      print('❌ [ZoneError] Uncaught error: $error');
      print('📍 StackTrace: $stackTrace');
      // Có thể gửi lỗi lên server analytics ở đây (Firebase Crashlytics, Sentry, v.v.)
    },
  );
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
        // ✅ WARNING FIX: Tách thành widget riêng để tối ưu rebuild
        child: const AppWrapper(),
      ),
    );
  }
}

/// Widget wrapper để lắng nghe các Cubit settings
/// Tách riêng để code gọn hơn và dễ maintain
class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Sử dụng context.watch thay vì nested BlocBuilder
    final themeMode = context.watch<ThemeCubit>().state;
    final locale = context.watch<LanguageCubit>().state;
    final fontScale = context.watch<FontSizeCubit>().state;

    return MaterialApp(
      title: 'ẢnhPDF+',
      debugShowCheckedModeBanner: false,

      // Theme & Locale & Font
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
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
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthSuccess) {
            return const MainScreen(); // ✅ Đã đăng nhập -> Vào MainScreen với Bottom Nav
          }
          // Nếu đang check hoặc chưa đăng nhập -> Vào Login
          return LoginScreen();
        },
      ),
    );
  }
}
