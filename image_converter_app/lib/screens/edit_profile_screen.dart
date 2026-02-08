import 'package:flutter/material.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;

  const EditProfileScreen({Key? key, required this.currentName}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  late TextEditingController _nameController;
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPass = true;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String name = _nameController.text.trim();
      String? newPass = _newPassController.text.isNotEmpty ? _newPassController.text : null;
      String? currentPass = _currentPassController.text.isNotEmpty ? _currentPassController.text : null;

      // ✅ Kiểm tra xem có thay đổi gì không
      bool isNameChanged = name != widget.currentName;
      bool isPassChanged = newPass != null && newPass.isNotEmpty;

      if (!isNameChanged && !isPassChanged) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noChanges ?? "Không có thay đổi nào!"),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadius10),
            ),
          );
        }
        return;
      }

      await _authService.updateProfile(
        name: name,
        currentPassword: currentPass,
        newPassword: newPass,
      );
      
      // Cache invalidated inside updateProfile in AuthService

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.updateSuccess ?? "Cập nhật thành công!"),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadius10),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadius10),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(isDark),
      // --- AppBar sử dụng style thống nhất ---
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.getPrimaryGradient(isDark),
          ),
          child: SafeArea(
            child: Padding(
              padding: AppDimensions.paddingH16,
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  // Title
                  Expanded(
                    child: Center(
                      child: Text(
                        lang.editProfile ?? "Chỉnh sửa hồ sơ",
                        style: const TextStyle(
                          fontWeight: AppTextStyles.weightBold,
                          color: AppColors.white,
                          fontSize: AppTextStyles.fontSize20,
                        ),
                      ),
                    ),
                  ),
                  // Placeholder để cân bằng layout
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.paddingAll20,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECTION: Thông tin cơ bản ---
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    lang.basicInfo ?? "Thông tin cơ bản",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),

              // Input: Họ và tên
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: lang.fullName ?? "Họ và tên",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.cardColor,
                    prefixIcon: Container(
                      margin: EdgeInsets.all(12),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.person, color: Colors.blue, size: 20),
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty
                      ? (lang.pleaseEnterName ?? "Vui lòng nhập tên")
                      : null,
                ),
              ),

              SizedBox(height: 30),

              // --- SECTION: Đổi mật khẩu ---
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    lang.changePassword ?? "Đổi mật khẩu",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                lang.changePasswordHint ?? "Nhập mật khẩu cũ để xác thực nếu muốn đổi mật khẩu mới",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),

              SizedBox(height: 15),

              // Input: Mật khẩu hiện tại
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _currentPassController,
                  obscureText: _obscureCurrentPass,
                  decoration: InputDecoration(
                    labelText: lang.currentPassword ?? "Mật khẩu hiện tại",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.cardColor,
                    prefixIcon: Container(
                      margin: EdgeInsets.all(12),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.vpn_key, color: Colors.orange, size: 20),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPass ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscureCurrentPass = !_obscureCurrentPass),
                    ),
                  ),
                  validator: (val) {
                    if (_newPassController.text.isNotEmpty && (val == null || val.isEmpty)) {
                      return lang.needCurrentPassword ?? "Cần nhập mật khẩu cũ để xác thực";
                    }
                    return null;
                  },
                ),
              ),

              SizedBox(height: 15),

              // Input: Mật khẩu mới
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _newPassController,
                  obscureText: _obscureNewPass,
                  decoration: InputDecoration(
                    labelText: lang.newPasswordOptional ?? "Mật khẩu mới (Tùy chọn)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.cardColor,
                    prefixIcon: Container(
                      margin: EdgeInsets.all(12),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.lock_outline, color: Colors.green, size: 20),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPass ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                    ),
                  ),
                  validator: (val) {
                    if (val != null && val.isNotEmpty && val.length < 6) {
                      return lang.passwordMinLength ?? "Mật khẩu phải từ 6 ký tự";
                    }
                    return null;
                  },
                ),
              ),

              SizedBox(height: 15),

              // Input: Nhập lại mật khẩu mới
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _confirmPassController,
                  obscureText: _obscureConfirmPass,
                  decoration: InputDecoration(
                    labelText: lang.confirmNewPassword ?? "Nhập lại mật khẩu mới",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.cardColor,
                    prefixIcon: Container(
                      margin: EdgeInsets.all(12),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.check_circle_outline, color: Colors.purple, size: 20),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPass ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                    ),
                  ),
                  validator: (val) {
                    if (_newPassController.text.isNotEmpty && val != _newPassController.text) {
                      return lang.passwordNotMatch ?? "Mật khẩu xác nhận không khớp";
                    }
                    return null;
                  },
                ),
              ),

              SizedBox(height: 40),

              // Button: Lưu thay đổi
              Container(
                width: double.infinity,
                height: AppDimensions.buttonHeightLarge,
                decoration: BoxDecoration(
                  gradient: AppTheme.getPrimaryGradient(isDark),
                  borderRadius: AppDimensions.borderRadius15,
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(AppColors.opacity30),
                      blurRadius: AppDimensions.blurRadius15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimensions.borderRadius15,
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : Text(
                    lang.saveChanges ?? "Lưu thay đổi",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}