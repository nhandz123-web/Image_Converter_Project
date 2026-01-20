import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../screens/profile_screen.dart';
import 'vip_crown_icon.dart';

/// Widget Header dùng chung cho các màn hình trong app
///
/// Hỗ trợ 2 dạng:
/// - SliverAppBar (cho CustomScrollView) - mặc định
/// - AppBar thường (cho Scaffold)
///
/// Các tùy chọn:
/// - [title]: Tiêu đề hiển thị (mặc định: null, sẽ dùng app name)
/// - [showLogo]: Hiển thị logo hay không (mặc định: true)
/// - [showVipCrown]: Hiển thị VIP crown hay không (mặc định: true)
/// - [showProfileButton]: Hiển thị nút profile hay không (mặc định: true)
/// - [leading]: Widget tùy chỉnh ở bên trái (thay thế logo)
/// - [actions]: Các action buttons bổ sung
/// - [onBackPressed]: Nếu có, sẽ hiển thị nút back thay vì logo
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
    this.height = 80,
    this.floating = true,
    this.pinned = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      floating: floating,
      pinned: pinned,
      elevation: AppDimensions.elevation0,
      toolbarHeight: height,
      automaticallyImplyLeading: false,
      flexibleSpace: _buildHeaderContent(context, isDark),
    );
  }

  /// Trả về AppBar thường (không phải Sliver) để dùng với Scaffold
  PreferredSizeWidget toAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: _buildHeaderContent(context, isDark),
    );
  }

  Widget _buildHeaderContent(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.appBarGradientDark
            : AppColors.appBarGradientLight,
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: AppDimensions.paddingH16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Leading widget (Logo hoặc Back button hoặc custom)
                _buildLeading(context),

                const SizedBox(width: AppDimensions.spacing12),

                // Title
                Expanded(
                  child: Text(
                    title ?? 'Image Converter',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: AppTextStyles.weightBold,
                      fontSize: AppTextStyles.fontSize20,
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
                    onUpgradePressed: onUpgradePressed ?? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tính năng mua VIP đang phát triển'),
                          backgroundColor: AppColors.info,
                        ),
                      );
                    },
                    size: 26,
                  ),
                  const SizedBox(width: 4),
                ],

                // Profile button
                if (showProfileButton)
                  IconButton(
                    icon: const Icon(Icons.person_rounded, color: AppColors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProfileScreen()),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    // Custom leading widget
    if (leading != null) {
      return leading!;
    }

    // Back button
    if (onBackPressed != null) {
      return Container(
        padding: AppDimensions.paddingAll8,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(AppColors.opacity20),
          borderRadius: AppDimensions.borderRadius12,
        ),
        child: InkWell(
          onTap: onBackPressed,
          borderRadius: AppDimensions.borderRadius12,
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.white,
            size: AppDimensions.iconSizeRegular,
          ),
        ),
      );
    }

    // Logo (default)
    if (showLogo) {
      return Container(
        padding: AppDimensions.paddingAll8,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(AppColors.opacity20),
          borderRadius: AppDimensions.borderRadius12,
        ),
        child: const Icon(
          Icons.flash_on_rounded,
          color: AppColors.white,
          size: AppDimensions.iconSizeRegular,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Extension để dễ dàng tạo AppHeader với các preset
extension AppHeaderPresets on AppHeader {
  /// Header cho trang chính (Home) - đầy đủ tính năng
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

  /// Header cho trang chi tiết - có nút back
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

  /// Header đơn giản - chỉ có title và back
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
