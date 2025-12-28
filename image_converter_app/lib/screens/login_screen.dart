import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';

import '../blocs/auth_bloc.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';

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
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          }
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Color(0xFF1A237E), Color(0xFF0D47A1)]
                    : [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo và tiêu đề
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_open_rounded,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 30),
                        Text(
                          lang.login ?? "Đăng nhập",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          lang.welcomeBack ?? "Chào mừng bạn quay trở lại",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: 40),

                        // Card chứa form
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Email field
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: lang.email ?? "Email",
                                  hintText: lang.enterEmail ?? "Nhập email của bạn",
                                  prefixIcon: Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: theme.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.grey[850]
                                      : Colors.grey[50],
                                ),
                              ),
                              SizedBox(height: 16),

                              // Password field
                              TextField(
                                controller: _passController,
                                obscureText: !_isPasswordVisible,
                                style: TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: lang.password ?? "Mật khẩu",
                                  hintText: lang.enterPassword ?? "Nhập mật khẩu",
                                  prefixIcon: Icon(Icons.lock_outline),
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
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: theme.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.grey[850]
                                      : Colors.grey[50],
                                ),
                              ),
                              SizedBox(height: 12),

                              // Quên mật khẩu
                               Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // Chuyển hướng đến màn hình Quên mật khẩu
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                                    );
                                  },
                                  child: Text(
                                    lang.forgotPassword ?? "Quên mật khẩu?",
                                    style: TextStyle(
                                      color: theme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),

                              // Nút đăng nhập
                              SizedBox(
                                width: double.infinity,
                                height: 56,
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
                                          backgroundColor: Colors.orange,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    context.read<AuthBloc>().add(
                                      LoginRequested(email, password),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: state is AuthLoading
                                      ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                      : Text(
                                    lang.login ?? "Đăng nhập",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24),

                        // Đăng ký
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              lang.noAccount ?? "Chưa có tài khoản?",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 15,
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}