import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Widget hiển thị icon vương miện VIP trên header
///
/// Có 2 trạng thái:
/// - Chưa VIP: Vương miện màu vàng với animation shimmer hấp dẫn
/// - Đã VIP: Vương miện màu trắng/platinum với viền vàng, tap để xem thông tin gói
class VipCrownIcon extends StatefulWidget {
  /// Trạng thái VIP của user
  final bool isVip;

  /// Thông tin gói VIP (nếu đã VIP)
  final VipInfo? vipInfo;

  /// Callback khi tap vào crown (cho user chưa VIP -> mở màn hình mua VIP)
  final VoidCallback? onUpgradePressed;

  /// Size của icon (default: 28)
  final double size;

  const VipCrownIcon({
    super.key,
    required this.isVip,
    this.vipInfo,
    this.onUpgradePressed,
    this.size = 28,
  });

  @override
  State<VipCrownIcon> createState() => _VipCrownIconState();
}

class _VipCrownIconState extends State<VipCrownIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Shimmer effect animation
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Pulse animation cho crown chưa VIP
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Chạy animation loop cho user chưa VIP
    if (!widget.isVip) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VipCrownIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVip != oldWidget.isVip) {
      if (!widget.isVip) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isVip ? 1.0 : _pulseAnimation.value,
            child: _buildCrownIcon(context),
          );
        },
      ),
    );
  }

  Widget _buildCrownIcon(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: widget.size + 12,
      height: widget.size + 12,
      decoration: BoxDecoration(
        // Background với glow effect
        gradient: widget.isVip
            ? null
            : RadialGradient(
                colors: [
                  AppColors.crownGold.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
        borderRadius: BorderRadius.circular(widget.size / 2 + 6),
      ),
      child: Center(
        child: widget.isVip
            ? _buildVipCrown(isDark)
            : _buildNonVipCrown(isDark),
      ),
    );
  }

  /// Crown cho user chưa VIP - màu vàng với shimmer
  Widget _buildNonVipCrown(bool isDark) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                AppColors.crownGoldDark,
                AppColors.crownGoldLight,
                AppColors.crownGold,
                AppColors.crownGoldLight,
                AppColors.crownGoldDark,
              ],
              stops: [
                0.0,
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value,
                _shimmerAnimation.value + 0.3,
                1.0,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: Icon(
            Icons.workspace_premium_rounded,
            size: widget.size,
            color: AppColors.crownGold,
          ),
        );
      },
    );
  }

  /// Crown cho user VIP - Style đồng bộ (Trắng sáng Platinum viền Vàng)
  /// Sử dụng style này cho cả Light/Dark mode theo yêu cầu
  Widget _buildVipCrown(bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        Container(
          width: widget.size + 6,
          height: widget.size + 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.crownVipBorder.withValues(alpha: 0.6),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        // Crown icon với border vàng - Nền trong suốt
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent, // Luôn trong suốt để nổi bật icon
            border: Border.all(
              color: AppColors.crownVipBorder,
              width: 2.0,
            ),
          ),
          child: ShaderMask(
            shaderCallback: (bounds) {
              // Sử dụng Gradient Dark (Trắng -> Vàng) cho cả 2 mode
              return AppColors.crownVipGradientDark.createShader(bounds);
            },
            child: Icon(
              Icons.workspace_premium_rounded,
              size: widget.size - 4,
              color: AppColors.crownPlatinumShine, // Luôn là màu trắng sáng
            ),
          ),
        ),
      ],
    );
  }

  void _handleTap(BuildContext context) {
    if (widget.isVip && widget.vipInfo != null) {
      // Hiển thị thông tin gói VIP
      _showVipInfoDialog(context);
    } else {
      // Chưa VIP -> mở màn hình upgrade
      widget.onUpgradePressed?.call();
    }
  }

  void _showVipInfoDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vipInfo = widget.vipInfo!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.crownVipBorder.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header với crown
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.crownGold.withOpacity(0.2),
                          AppColors.crownGoldLight.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return AppColors.crownVipGradient.createShader(bounds);
                    },
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // VIP badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.crownGold.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'VIP ${vipInfo.planName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Thông tin chi tiết
              _buildInfoRow(
                context,
                icon: Icons.calendar_today_rounded,
                label: 'Ngày hết hạn',
                value: vipInfo.expiryDate,
                isDark: isDark,
              ),

              const SizedBox(height: 12),

              _buildInfoRow(
                context,
                icon: Icons.timelapse_rounded,
                label: 'Còn lại',
                value: '${vipInfo.daysRemaining} ngày',
                isDark: isDark,
                valueColor: vipInfo.daysRemaining <= 7
                    ? AppColors.warning
                    : AppColors.success,
              ),

              const SizedBox(height: 24),

              // Quyền lợi
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.vipBadgeBackground
                      : AppColors.vipBadgeBackgroundLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: AppColors.crownGold,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Quyền lợi VIP',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...vipInfo.benefits.map(
                      (benefit) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                benefit,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Nút đóng
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.crownGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? (isDark ? Colors.white : Colors.black87),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/// Model chứa thông tin VIP
class VipInfo {
  final String planName;
  final String expiryDate;
  final int daysRemaining;
  final List<String> benefits;

  const VipInfo({
    required this.planName,
    required this.expiryDate,
    required this.daysRemaining,
    required this.benefits,
  });
}
