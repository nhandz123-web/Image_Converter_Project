import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../screens/profile_screen.dart';
import 'vip_crown_icon.dart';

/// Widget Header dùng chung cho các màn hình trong app
/// Style: Glassmorphism Modern Header (Frosted Glass)
class AppHeader extends StatelessWidget {
  /// Tiêu đề hiển thị (nếu null sẽ dùng tên app)
  final String? title;

  /// Hiển thị logo hay không
  final bool showLogo;

  /// Hiển thị VIP crown hay không
  final bool showVipCrown;

  /// Hiển thị nút profile hay không
  final bool showProfileButton;

  /// Widget tùy chỉnh ở bên trái (thay thế logo)
  final Widget? leading;

  /// Các action buttons bổ sung (trước VIP crown và profile)
  final List<Widget>? actions;

  /// Callback khi nhấn nút back (nếu có sẽ hiển thị nút back)
  final VoidCallback? onBackPressed;

  /// Trạng thái VIP của user
  final bool isVip;

  /// Thông tin gói VIP (nếu đã VIP)
  final VipInfo? vipInfo;

  /// Callback khi nhấn upgrade VIP
  final VoidCallback? onUpgradePressed;

  /// Chiều cao của header
  final double height;

  /// Floating behavior cho SliverAppBar
  final bool floating;

  /// Pinned behavior cho SliverAppBar
  final bool pinned;

  const AppHeader({
    super.key,
    this.title,
    this.showLogo = true,
    this.showVipCrown = true,
    this.showProfileButton = true,
    this.leading,
    this.actions,
    this.onBackPressed,
    this.isVip = false,
    this.vipInfo,
    this.onUpgradePressed,
    this.height = 70, // Giảm height một chút để thanh thoát hơn
    this.floating = true,
    this.pinned = true,
  });

  @override
  Widget build(BuildContext context) {
    // Sử dụng theme để xác định dark mode
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      floating: floating,
      pinned: pinned,
      elevation: 0,
      toolbarHeight: height,
      backgroundColor: Colors.transparent, // Trong suốt để thấy background
      automaticallyImplyLeading: false,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Hiệu ứng mờ mạnh
          child: Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.black.withOpacity(0.5) 
                  : Colors.white.withOpacity(0.7), // Lớp phủ màu bán trong suốt
              border: Border(
                bottom: BorderSide(
                  color: isDark 
                      ? Colors.white.withOpacity(0.1) 
                      : Colors.black.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Leading widget (Logo hoặc Back button hoặc custom)
                      _buildLeading(context, isDark),

                      const SizedBox(width: 12),

                      // Title
                      Expanded(
                        child: Text(
                          title ?? 'Image Converter',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Custom actions
                      if (actions != null) ...actions!,

                      // VIP Crown Icon
                      if (showVipCrown) ...[
                        VipCrownIcon(
                          isVip: isVip,
                          vipInfo: vipInfo,
                          onUpgradePressed: onUpgradePressed ?? () {},
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Profile button or Avatar
                      if (showProfileButton)
                        _buildProfileButton(context, isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Trả về AppBar thường (không phải Sliver) để dùng với Scaffold
  PreferredSizeWidget toAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: build(context), // Cần bọc trong CustomScrollView hoặc dùng Widget khác nếu không dùng Sliver
    );
  }

  Widget _buildLeading(BuildContext context, bool isDark) {
    if (leading != null) return leading!;

    if (onBackPressed != null) {
      return InkWell(
        onTap: onBackPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
        ),
      );
    }

    if (showLogo) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [Colors.blue.shade400, Colors.blue.shade600] 
                : [Colors.blue.shade500, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.flash_on_rounded,
          color: Colors.white,
          size: 20,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildProfileButton(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen()),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(2), // Border width
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
          child: Icon(
            Icons.person_rounded,
            color: isDark ? Colors.white70 : Colors.grey[600],
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Extension để dễ dàng tạo AppHeader với các preset
extension AppHeaderPresets on AppHeader {
  static AppHeader home({
    required bool isVip,
    VipInfo? vipInfo,
     VoidCallback? onUpgradePressed,
  }) {
    return AppHeader(
      showLogo: true,
      showVipCrown: true,
      showProfileButton: true,
      isVip: isVip,
      vipInfo: vipInfo,
      onUpgradePressed: onUpgradePressed,
    );
  }

  static AppHeader detail({
    required String title,
    required VoidCallback onBackPressed,
    bool showVipCrown = false,
    bool showProfileButton = false,
  }) {
    return AppHeader(
      title: title,
      showLogo: false,
      onBackPressed: onBackPressed,
      showVipCrown: showVipCrown,
      showProfileButton: showProfileButton,
    );
  }

  static AppHeader simple({
    required String title,
    required VoidCallback onBackPressed,
  }) {
    return AppHeader(
      title: title,
      showLogo: false,
      showVipCrown: false,
      showProfileButton: false,
      onBackPressed: onBackPressed,
    );
  }
}
