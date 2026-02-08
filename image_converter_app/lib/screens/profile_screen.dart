import 'dart:math';
import 'dart:ui'; // Create for ImageFilter
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
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
import '../theme/app_styles.dart';
import '../theme/app_component_styles.dart';
import '../widgets/app_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
  Future<void> _loadAllData({bool forceRefresh = false}) async {
    int usedBytes = 0;
    int totalBytes = 1073741824; // 1GB mặc định
    double percent = 0.0;
    String name = 'Người dùng';
    String email = '';
    String? photoUrl;
    bool isFromCache = false;

    try {
      final userData = await _authService.getUser(forceRefresh: forceRefresh);
      if (userData != null) {
        name = userData['name'] ?? 'Người dùng';
        email = userData['email'] ?? '';

        if (userData['storage'] != null) {
          final storage = userData['storage'];
          usedBytes = (storage['used_bytes'] as num?)?.toInt() ?? 0;
          totalBytes = (storage['max_bytes'] as num?)?.toInt() ?? 1073741824;

          if (totalBytes > 0) {
            percent = (usedBytes / totalBytes).clamp(0.0, 1.0);
          }
        }

        String? rawPhoto = userData['photo'];
        if (rawPhoto != null && rawPhoto.isNotEmpty) {
           if (rawPhoto.startsWith('http')) {
              photoUrl = rawPhoto;
              if (photoUrl!.contains('localhost')) {
                photoUrl = photoUrl!.replaceFirst('localhost', ApiConfig.host);
              } else if (photoUrl!.contains('127.0.0.1')) {
                 photoUrl = photoUrl!.replaceFirst('127.0.0.1', ApiConfig.host);
              }
           } else {
              photoUrl = '${ApiConfig.baseUrl}/${rawPhoto.replaceAll(RegExp(r'^/+'), '')}';
           }
        }
      }
    } catch (e) {
      print("⚠️ Lỗi lấy user info: $e");
      isFromCache = true;
    }

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

  Future<void> _forceRefresh() async {
    setState(() {
      _isLoading = true;
    });
    await _loadAllData(forceRefresh: true);
  }

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

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoggedOut) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) =>  LoginScreen()),
                (route) => false,
          );
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: AppStyles.homeBackground(isDark),
          child: Stack(
            children: [
              // Background Blobs
              if (!isDark) ...[
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: AppStyles.homeBlob(Colors.blue.withOpacity(0.2)),
                  ),
                ),
                Positioned(
                  bottom: 100,
                  left: -50,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: AppStyles.homeBlob(Colors.purple.withOpacity(0.15), blurRadius: 60),
                  ),
                ),
              ],

              // Main Content with CustomScrollView
              CustomScrollView(
                slivers: [
                   AppHeader(
                    title: lang.myProfile ?? "Hồ sơ của tôi",
                    showLogo: false,
                    showVipCrown: false,
                    showProfileButton: false,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                       IconButton(
                        icon: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDark ? Colors.white : theme.primaryColor,
                                ),
                              )
                            : Icon(Icons.refresh_rounded, color: isDark ? Colors.white : Colors.black87),
                        onPressed: _isLoading ? null : _forceRefresh,
                        tooltip: "Làm mới",
                      ),
                    ],
                   ),

                   SliverPadding(
                     padding: const EdgeInsets.all(16.0),
                     sliver: SliverList(
                       delegate: SliverChildListDelegate([
                         // Profile Info Card
                         _buildProfileInfoCard(isDark, theme, lang),
                         const SizedBox(height: 20),

                         // Storage Card
                         _buildStorageCard(isDark, theme, lang),
                         const SizedBox(height: 24),

                         // Data Source Warning
                         if (_isFromCache)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              children: [
                                Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Đang hiển thị dữ liệu offline",
                                    style: TextStyle(color: Colors.orange, fontSize: 13),
                                  ),
                                )
                              ],
                            ),
                          ),

                         // Menu Items
                         _buildGlassContainer(
                           isDark: isDark,
                           child: Column(
                             children: [
                               _buildProfileItem(
                                  context,
                                  icon: Icons.edit_outlined,
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
                                  isDark: isDark,
                                ),
                                Divider(height: 1, indent: 56, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                                _buildProfileItem(
                                  context,
                                  icon: Icons.settings_outlined,
                                  title: lang.appSettings ?? "Cài đặt ứng dụng",
                                  color: Colors.purple,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                                    );
                                  },
                                  isDark: isDark,
                                ),
                                Divider(height: 1, indent: 56, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                                _buildProfileItem(
                                  context,
                                  icon: Icons.help_outline_rounded,
                                  title: lang.helpAndSupport ?? "Trợ giúp & Hỗ trợ",
                                  color: Colors.orange,
                                  onTap: () {},
                                  isDark: isDark,
                                ),
                             ],
                           )
                         ),

                         const SizedBox(height: 20),

                         // Logout Button
                          _buildGlassContainer(
                           isDark: isDark,
                           child: _buildProfileItem(
                              context,
                              icon: Icons.logout_rounded,
                              title: lang.logout ?? "Đăng xuất",
                              color: Colors.red,
                              isDestructive: true,
                              onTap: () {
                                _showLogoutDialog(context, lang);
                              },
                              isDark: isDark,
                           ),
                         ),

                         const SizedBox(height: 40),
                       ]),
                     ),
                   )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoCard(bool isDark, ThemeData theme, AppLocalizations lang) {
    return _buildGlassContainer(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: AppComponentStyles.glowingAvatarBorder(theme.primaryColor),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: _photoUrl != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: _photoUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                          errorWidget: (context, url, error) {
                            return Icon(Icons.person, size: 40, color: theme.primaryColor);
                          },
                        ),
                      )
                    : Icon(Icons.person, size: 40, color: theme.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isLoading ? (lang.loading ?? "Đang tải...") : _name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _email,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageCard(bool isDark, ThemeData theme, AppLocalizations lang) {
     Color progressColor = _percent > 0.9 ? AppColors.error : const Color(0xFF10B981); // Emerald 500

    return _buildGlassContainer(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: AppComponentStyles.iconContainer(
                        color: Colors.blue,
                        isDark: isDark,
                        borderRadius: 10,
                      ),
                      child: Icon(Icons.cloud_queue_rounded,
                        color: isDark ? Colors.white : Colors.blue,
                        size: 20
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      lang.storageUsed ?? "Dung lượng",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                if (!_isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: AppComponentStyles.badgeContainer(
                      color: progressColor,
                      borderRadius: 12,
                    ),
                    child: Text(
                      "${(_percent * 100).toStringAsFixed(1)}%",
                      style: TextStyle(
                        color: progressColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Progress Bar
            Stack(
              children: [
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: AppComponentStyles.progressTrackBackground(
                    isDark: isDark,
                    borderRadius: 5,
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      height: 10,
                      width: constraints.maxWidth * (_isLoading ? 0 : _percent).clamp(0.0, 1.0),
                      decoration: AppComponentStyles.progressFill(
                        progressColor: progressColor,
                        borderRadius: 5,
                      ),
                    );
                  }
                ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isLoading ? "..." : formatBytes(_usedBytes, 1),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                ),
                Text(
                  _isLoading ? "..." : formatBytes(_totalBytes, 0),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
        required VoidCallback onTap,
        required bool isDark,
        bool isDestructive = false,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        // borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: AppComponentStyles.iconContainer(
                  color: color,
                  isDark: false,
                  borderRadius: 10,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDestructive ? AppColors.error : (isDark ? Colors.white : const Color(0xFF1E293B)),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? Colors.white24 : Colors.grey[300]
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child, required bool isDark}) {
    return AppWidgetHelpers.glassContainer(
      child: child,
      isDark: isDark,
      borderRadius: 24,
    );
  }

  void _showLogoutDialog(BuildContext context, AppLocalizations lang) {
     final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: AppComponentStyles.dialogIconContainer(
                color: AppColors.error,
                borderRadius: 8,
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              lang.confirmLogout ?? "Đăng xuất",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          lang.logoutMessage ?? "Bạn có chắc chắn muốn đăng xuất?",
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              lang.cancel ?? "Hủy",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              lang.logout ?? "Đăng xuất",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
