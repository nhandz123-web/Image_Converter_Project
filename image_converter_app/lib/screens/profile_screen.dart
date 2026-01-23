import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../services/document_service.dart';
import '../services/auth_service.dart';
import '../blocs/auth_bloc.dart';
import '../config/api_config.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DocumentService _documentService = DocumentService();
  final AuthService _authService = AuthService();

  // Biến lưu dữ liệu dung lượng
  bool _isLoading = true;
  bool _isFromCache = false; // Đánh dấu data từ cache
  int _usedBytes = 0;
  int _totalBytes = 1073741824; // Mặc định 1GB nếu chưa load được
  double _percent = 0.0;
  String _name = "Đang tải...";
  String _email = "";
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  /// Load tất cả dữ liệu (user info, storage)
  /// [forceRefresh] - Bắt buộc load từ API, bỏ qua cache
  Future<void> _loadAllData({bool forceRefresh = false}) async {
    // Khởi tạo giá trị mặc định
    int usedBytes = 0;
    int totalBytes = 1073741824; // 1GB mặc định
    double percent = 0.0;
    String name = 'Người dùng';
    String email = '';
    String? photoUrl;
    bool isFromCache = false;

    // Gọi API lấy thông tin User (bao gồm storage)
    try {
      final userData = await _authService.getUser(forceRefresh: forceRefresh);
      if (userData != null) {
        name = userData['name'] ?? 'Người dùng';
        email = userData['email'] ?? '';
        
        // Parse storage info từ user data
        if (userData['storage'] != null) {
          final storage = userData['storage'];
          // Convert an toàn từ dynamic
          usedBytes = (storage['used_bytes'] as num?)?.toInt() ?? 0;
          totalBytes = (storage['max_bytes'] as num?)?.toInt() ?? 1073741824;
          
          // Tính phần trăm
          if (totalBytes > 0) {
            percent = (usedBytes / totalBytes).clamp(0.0, 1.0);
          }
        }
        
        // Parse photo
        String? rawPhoto = userData['photo'];
        if (rawPhoto != null && rawPhoto.isNotEmpty) {
           if (rawPhoto.startsWith('http')) {
              photoUrl = rawPhoto;
           } else {
              // Fix relative path
              photoUrl = '${ApiConfig.baseUrl}/${rawPhoto.replaceAll(RegExp(r'^/+'), '')}';
           }
        }
      }
    } catch (e) {
      print("⚠️ Lỗi lấy user info: $e");
      isFromCache = true;
    }

    // Cập nhật UI
    if (mounted) {
      setState(() {
        _usedBytes = usedBytes;
        _totalBytes = totalBytes;
        _percent = percent;
        _name = name;
        _email = email;
        _photoUrl = photoUrl;
        _isFromCache = isFromCache;
        _isLoading = false;
      });
    }
  }

  /// Force refresh data từ API
  Future<void> _forceRefresh() async {
    setState(() {
      _isLoading = true;
    });
    await _loadAllData(forceRefresh: true);
  }

  // Hàm format số bytes sang MB/GB cho dễ đọc
  String formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + ' ' + suffixes[i];
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Logic màu sắc thanh tiến trình
    Color progressColor = _percent > 0.9 ? AppColors.red : AppColors.orange;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoggedOut) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        // --- AppBar sử dụng AppHeader ---
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
                          lang.myProfile ?? "Hồ sơ của tôi",
                          style: const TextStyle(
                            fontWeight: AppTextStyles.weightBold,
                            color: AppColors.white,
                            fontSize: AppTextStyles.fontSize20,
                          ),
                        ),
                      ),
                    ),
                    // Refresh button
                    IconButton(
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Icon(Icons.refresh, color: AppColors.white),
                      onPressed: _isLoading ? null : _forceRefresh,
                      tooltip: "Làm mới",
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // --- HEADER với Gradient cho cả Light & Dark mode ---
              Container(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacing30),
                decoration: BoxDecoration(
                  gradient: isDark ? AppColors.welcomeCardGradientDark : AppColors.welcomeCardGradientLight,
                  borderRadius: AppDimensions.borderRadiusBottom30,
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        padding: AppDimensions.paddingAll4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withOpacity(AppColors.opacity30),
                        ),
                        child: CircleAvatar(
                          radius: AppDimensions.avatarSizeRegular,
                          backgroundColor: isDark ? AppColors.grey800 : AppColors.white,
                          backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                          child: _photoUrl == null 
                              ? Icon(Icons.person, size: AppDimensions.iconSizeHuge, color: isDark ? AppColors.white : theme.primaryColor)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing16),
                    Text(
                      _isLoading ? (lang.loading ?? "Đang tải...") : _name,
                      style: const TextStyle(fontSize: AppTextStyles.fontSize22, fontWeight: AppTextStyles.weightBold, color: AppColors.white),
                    ),
                    Text(
                      _email,
                      style: const TextStyle(fontSize: AppTextStyles.fontSize14, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacing20),

              // --- THANH DUNG LƯỢNG (DATA THẬT) - ĐÃ SỮA MÀU ---
              Padding(
                padding: AppDimensions.paddingH20,
                child: Container(
                  padding: AppDimensions.paddingAll20,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: AppDimensions.borderRadius20,
                    boxShadow: [
                      BoxShadow(color: AppColors.black.withOpacity(AppColors.opacity05), blurRadius: AppDimensions.blurRadius10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lang.storageUsed ?? "Dung lượng đã dùng",
                            style: TextStyle(
                              fontWeight: AppTextStyles.weightBold,
                              color: isDark ? AppColors.white : AppColors.black,
                            ),
                          ),
                          _isLoading
                              ? const SizedBox(width: AppDimensions.iconSizeMedium, height: AppDimensions.iconSizeMedium, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(
                            "${formatBytes(_usedBytes, 2)} / ${formatBytes(_totalBytes, 0)}",
                            style: TextStyle(
                              color: isDark ? AppColors.blue300 : theme.primaryColor,
                              fontWeight: AppTextStyles.weightBold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacing10),
                      ClipRRect(
                        borderRadius: AppDimensions.borderRadius10,
                        child: _isLoading
                            ? const LinearProgressIndicator(minHeight: AppDimensions.progressBarHeight)
                            : LinearProgressIndicator(
                          value: _percent,
                          backgroundColor: isDark ? AppColors.grey800 : AppColors.grey200,
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                          minHeight: AppDimensions.progressBarHeight,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing8),
                      Text(
                        _isLoading
                            ? (lang.calculating ?? "Đang tính toán...")
                            : "${lang.youHaveUsed ?? "Bạn đã dùng"} ${(_percent * 100).toStringAsFixed(1)}% ${lang.storage ?? "dung lượng"}.",
                        style: TextStyle(
                          fontSize: AppTextStyles.fontSize12,
                          color: AppTheme.getSecondaryTextColor(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spacing20),

              // --- MENU ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildProfileItem(
                      context,
                      lang: lang,
                      theme: theme,
                      icon: Icons.person_outline,
                      title: lang.editProfile ?? "Chỉnh sửa thông tin",
                      color: Colors.blue,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(currentName: _name),
                          ),
                        );
                        if (result == true) {
                          _loadAllData();
                        }
                      },
                    ),
                    _buildProfileItem(
                      context,
                      lang: lang,
                      theme: theme,
                      icon: Icons.settings_outlined,
                      title: lang.appSettings ?? "Cài đặt ứng dụng",
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SettingsScreen()),
                        );
                      },
                    ),
                    _buildProfileItem(
                      context,
                      lang: lang,
                      theme: theme,
                      icon: Icons.help_outline,
                      title: lang.helpAndSupport ?? "Trợ giúp & Hỗ trợ",
                      color: Colors.orange,
                      onTap: () {},
                    ),
                    SizedBox(height: 20),
                    _buildProfileItem(
                      context,
                      lang: lang,
                      theme: theme,
                      icon: Icons.logout,
                      title: lang.logout ?? "Đăng xuất",
                      color: Colors.red,
                      isDestructive: true,
                      onTap: () {
                        _showLogoutDialog(context, lang);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(
      BuildContext context, {
        required AppLocalizations lang,
        required ThemeData theme,
        required IconData icon,
        required String title,
        required Color color,
        required VoidCallback onTap,
        bool isDestructive = false,
      }) {
    return Card(
      elevation: AppDimensions.elevation0,
      margin: const EdgeInsets.only(bottom: AppDimensions.spacing10),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadius15),
      child: ListTile(
        leading: Container(
          padding: AppDimensions.paddingAll10,
          decoration: BoxDecoration(
            color: color.withOpacity(AppColors.opacity10),
            borderRadius: AppDimensions.borderRadius10,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: AppTextStyles.weightSemiBold, color: isDestructive ? AppColors.red : null),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: AppDimensions.iconSizeMedium, color: AppColors.grey),
        onTap: onTap,
      ),
    );
  }

  // Dialog xác nhận đăng xuất
  void _showLogoutDialog(BuildContext context, AppLocalizations lang) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadius20),
        title: Text(
          lang.confirmLogout ?? "Xác nhận đăng xuất",
          style: const TextStyle(fontWeight: AppTextStyles.weightBold),
        ),
        content: Text(
          lang.logoutMessage ?? "Bạn có chắc chắn muốn đăng xuất?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              lang.cancel ?? "Hủy",
              style: TextStyle(color: AppColors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(
                borderRadius: AppDimensions.borderRadius10,
              ),
            ),
            child: Text(
              lang.logout ?? "Đăng xuất",
              style: const TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
