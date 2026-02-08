import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';

import '../blocs/auth_bloc.dart';
import 'register_screen.dart';
import 'main_screen.dart'; // ✅ Import MainScreen với Bottom Navigation
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/app_safe_body.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(lang.loginSuccess ?? "Đăng nhập thành công!"),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: AppDimensions.borderRadius10,
                ),
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          }
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: AppDimensions.borderRadius10,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: AppTheme.getPrimaryGradient(isDark),
            ),
            child: AppSafeBody(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo và tiêu đề
                Container(
                  padding: AppDimensions.paddingAll20,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(AppColors.opacity15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_open_rounded,
                    size: AppDimensions.iconSizeGiant,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing30),
                Text(
                  lang.login ?? "Đăng nhập",
                  style: AppTextStyles.h1.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: AppDimensions.spacing8),
                Text(
                  lang.welcomeBack ?? "Chào mừng bạn quay trở lại",
                  style: TextStyle(
                    fontSize: AppTextStyles.fontSize16,
                    color: AppColors.white.withOpacity(AppColors.opacity80),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing40),

                // Card chứa form
                Container(
                  padding: AppDimensions.paddingAll24,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: AppDimensions.borderRadius20,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(AppColors.opacity10),
                        blurRadius: AppDimensions.blurRadius20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Email field
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: AppTextStyles.fontSize16),
                        decoration: InputDecoration(
                          labelText: lang.email ?? "Email",
                          hintText: lang.enterEmail ?? "Nhập email của bạn",
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing16),

                      // Password field
                      TextField(
                        controller: _passController,
                        obscureText: !_isPasswordVisible,
                        style: const TextStyle(fontSize: AppTextStyles.fontSize16),
                        decoration: InputDecoration(
                          labelText: lang.password ?? "Mật khẩu",
                          hintText: lang.enterPassword ?? "Nhập mật khẩu",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing12),

                      // Quên mật khẩu
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implement forgot password
                          },
                          child: Text(
                            lang.forgotPassword ?? "Quên mật khẩu?",
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: AppTextStyles.weightSemiBold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing8),

                      // Nút đăng nhập
                      SizedBox(
                        width: double.infinity,
                        height: AppDimensions.buttonHeightLarge,
                        child: ElevatedButton(
                          onPressed: state is AuthLoading
                              ? null
                              : () {
                            // Validate trước khi gửi
                            final email = _emailController.text.trim();
                            final password = _passController.text;

                            if (email.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(lang.fillAllFields ?? "Vui lòng nhập đủ thông tin"),
                                  backgroundColor: AppColors.warning,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppDimensions.borderRadius10,
                                  ),
                                ),
                              );
                              return;
                            }

                            context.read<AuthBloc>().add(
                              LoginRequested(email, password),
                            );
                          },
                          child: state is AuthLoading
                              ? const SizedBox(
                            height: AppDimensions.iconSizeRegular,
                            width: AppDimensions.iconSizeRegular,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : Text(
                            lang.login ?? "Đăng nhập",
                            style: AppTextStyles.buttonLarge,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.spacing24),

                // Đăng ký
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      lang.noAccount ?? "Chưa có tài khoản?",
                      style: TextStyle(
                        color: AppColors.white.withOpacity(AppColors.opacity90),
                        fontSize: AppTextStyles.fontSize15,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        lang.registerNow ?? "Đăng ký ngay",
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: AppTextStyles.fontSize15,
                          fontWeight: AppTextStyles.weightBold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.spacing20),
              ],
            ),
          ),
          );
        },
      ),
    );
  }
}