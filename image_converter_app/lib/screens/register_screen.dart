import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../blocs/auth_bloc.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/app_safe_body.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _selectedBirthday;  

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // 👈 THÊM: Hàm chọn ngày sinh
  Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  // 👈 THÊM: Format ngày sinh
  String _formatBirthday(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatBirthdayDisplay(DateTime? date) {
    if (date == null) return 'Chọn ngày sinh';
    return '${date.day}/${date.month}/${date.year}';
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
                content: Text(lang.registerSuccess ?? "Đăng ký thành công!"),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: AppDimensions.borderRadius10,
                ),
              ),
            );
            Navigator.pop(context);
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
              children: [
                // AppBar tùy chỉnh
                Padding(
                  padding: AppDimensions.paddingH8V8,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Nội dung chính
                // Use Flexible instead of Expanded because AppSafeBody already handles scrolling
                // and we want the content to take available space but be scrollable
                Padding(
                  padding: AppDimensions.paddingH24,
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
                          Icons.person_add_rounded,
                          size: AppDimensions.iconSizeLarge,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing20),
                      Text(
                        lang.register ?? "Đăng ký",
                        style: const TextStyle(
                          fontSize: AppTextStyles.fontSize28,
                          fontWeight: AppTextStyles.weightBold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing24),

                      // Card chứa form
                      Container(
                        padding: AppDimensions.paddingAll20,
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
                            // Họ tên
                            _buildTextField(
                              controller: _nameController,
                              label: lang.fullName ?? "Họ và tên",
                              hint: "Nhập họ và tên",
                              icon: Icons.person_outline,
                              isDark: isDark,
                              theme: theme,
                            ),
                            const SizedBox(height: AppDimensions.spacing14),

                            // Email
                            _buildTextField(
                              controller: _emailController,
                              label: lang.email ?? "Email",
                              hint: "Nhập email",
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              isDark: isDark,
                              theme: theme,
                            ),
                            SizedBox(height: 14),

                            // 👈 THÊM: Số điện thoại
                            _buildTextField(
                              controller: _phoneController,
                              label: "Số điện thoại",
                              hint: "Nhập số điện thoại",
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              isDark: isDark,
                              theme: theme,
                            ),
                            const SizedBox(height: AppDimensions.spacing14),

                            // 👈 THÊM: Địa chỉ
                            _buildTextField(
                              controller: _addressController,
                              label: "Địa chỉ",
                              hint: "Nhập địa chỉ",
                              icon: Icons.location_on_outlined,
                              isDark: isDark,
                              theme: theme,
                            ),
                            const SizedBox(height: AppDimensions.spacing14),

                            // 👈 THÊM: Ngày sinh
                            GestureDetector(
                              onTap: () => _selectBirthday(context),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[850] : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.cake_outlined, color: Colors.grey[600]),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _selectedBirthday != null
                                            ? _formatBirthdayDisplay(_selectedBirthday)
                                            : "Chọn ngày sinh",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _selectedBirthday != null
                                              ? null
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacing14),

                            // Mật khẩu
                            _buildPasswordField(
                              controller: _passController,
                              label: lang.password ?? "Mật khẩu",
                              hint: "Nhập mật khẩu",
                              isVisible: _isPasswordVisible,
                              onToggle: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              isDark: isDark,
                              theme: theme,
                            ),
                            SizedBox(height: 14),

                            // Nhập lại mật khẩu
                            _buildPasswordField(
                              controller: _confirmPassController,
                              label: lang.confirmPassword ?? "Nhập lại mật khẩu",
                              hint: "Nhập lại mật khẩu",
                              isVisible: _isConfirmPasswordVisible,
                              onToggle: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                              isDark: isDark,
                              theme: theme,
                            ),
                            SizedBox(height: 24),

                            // Nút đăng ký
                            SizedBox(
                              width: double.infinity,
                              height: AppDimensions.buttonHeightLarge,
                              child: ElevatedButton(
                                onPressed: state is AuthLoading
                                    ? null
                                    : () => _onRegisterPressed(context, lang),
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
                                  lang.register ?? "Đăng ký",
                                  style: AppTextStyles.buttonLarge,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppDimensions.spacing20),

                      // Đã có tài khoản
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            lang.haveAccount ?? "Đã có tài khoản?",
                            style: TextStyle(color: AppColors.white.withOpacity(AppColors.opacity90)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              lang.loginNow ?? "Đăng nhập ngay",
                              style: const TextStyle(
                                color: AppColors.white,
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
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  // 👈 Widget helper cho TextField thường
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    required ThemeData theme,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: AppTextStyles.fontSize16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }

  // 👈 Widget helper cho Password field
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
    required bool isDark,
    required ThemeData theme,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      style: const TextStyle(fontSize: AppTextStyles.fontSize16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: onToggle,
        ),
      ),
    );
  }

  // 👈 CẬP NHẬT: Hàm xử lý đăng ký
  void _onRegisterPressed(BuildContext context, AppLocalizations lang) {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passController.text;
    final confirmPass = _confirmPassController.text;
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    // Validate
    if (name.isEmpty || email.isEmpty || password.isEmpty ||
        phone.isEmpty || address.isEmpty || _selectedBirthday == null) {
      _showSnackBar(context, "Vui lòng nhập đầy đủ thông tin", Colors.orange);
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar(context, "Email không hợp lệ", Colors.orange);
      return;
    }

    if (password.length < 6) {
      _showSnackBar(context, "Mật khẩu phải có ít nhất 6 ký tự", Colors.orange);
      return;
    }

    if (password != confirmPass) {
      _showSnackBar(context, lang.passwordNotMatch ?? "Mật khẩu không khớp", Colors.orange);
      return;
    }

    if (!_isValidPhone(phone)) {
      _showSnackBar(context, "Số điện thoại không hợp lệ", Colors.orange);
      return;
    }

    // Gửi event đăng ký
    context.read<AuthBloc>().add(RegisterRequested(
      fullname: name,
      email: email,
      password: password,
      // confirmPassword: confirmPass,
      phone: phone,
      address: address,
      birthday: _formatBirthday(_selectedBirthday),
    ));
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadius10),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^[0-9]{10,11}$').hasMatch(phone);
  }
}