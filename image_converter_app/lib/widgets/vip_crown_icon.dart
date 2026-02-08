import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// Widget hiển thị icon vương miện VIP trên header
///
/// UI/UX Pro Max Version 2.0:
/// - Liquid Glass Morphism effects
/// - Iridescent shimmer animations
/// - Dynamic particle system (diamonds & stars)
/// - 3D depth with layered shadows
/// - Premium gradient overlays
/// - Smooth micro-interactions
/// - Enhanced VIP dialog with glassmorphism
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
    with TickerProviderStateMixin {
  // === ANIMATION CONTROLLERS ===
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _scaleController;

  // === ANIMATIONS ===
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _iridescentAnimation;

  // === PARTICLE SYSTEM ===
  final List<_ParticleConfig> _particles = [];
  final math.Random _random = math.Random();

  // === INTERACTION STATE ===
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _generateParticles();
    _startAnimations();
  }

  void _initializeControllers() {
    // Main shimmer effect (smooth wave)
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Heartbeat pulse for non-VIP (enticing effect)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Slow rotation for VIP aura
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    // Scale for tap feedback
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  void _initializeAnimations() {
    // Shimmer sweep animation
    _shimmerAnimation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );

    // Organic heartbeat pulse
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.12).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 0.96).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.96, end: 1.05).chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 50,
      ),
    ]).animate(_pulseController);

    // Iridescent color shift
    _iridescentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
  }

  void _generateParticles() {
    _particles.clear();

    // Generate diamond/star particles around the crown
    final int particleCount = widget.isVip ? 8 : 5;

    for (int i = 0; i < particleCount; i++) {
      double angle = (i / particleCount) * 2 * math.pi + _random.nextDouble() * 0.5;
      double distRel = 0.7 + _random.nextDouble() * 0.35;

      _particles.add(_ParticleConfig(
        angle: angle,
        distRel: distRel,
        sizeScale: 0.4 + _random.nextDouble() * 0.6,
        duration: Duration(milliseconds: 1200 + _random.nextInt(800)),
        delay: Duration(milliseconds: _random.nextInt(800)),
        type: widget.isVip
            ? (i % 3 == 0 ? _ParticleType.diamond : _ParticleType.star)
            : _ParticleType.sparkle,
      ));
    }
  }

  void _startAnimations() {
    if (widget.isVip) {
      _shimmerController.repeat();
      _rotationController.repeat();
      _pulseController.stop();
    } else {
      _shimmerController.repeat();
      _pulseController.repeat();
      _rotationController.stop();
    }
  }

  @override
  void didUpdateWidget(VipCrownIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVip != oldWidget.isVip) {
      _generateParticles();
      _startAnimations();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTap(BuildContext context) {
    if (widget.isVip && widget.vipInfo != null) {
      _showVipInfoDialog(context);
    } else {
      widget.onUpgradePressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: () => _handleTap(context),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _shimmerController,
          _pulseController,
          _rotationController,
          _scaleController,
        ]),
        builder: (context, child) {
          double scale = widget.isVip ? 1.0 : _pulseAnimation.value;
          double pressScale = _isPressed ? 0.92 : 1.0;

          return Transform.scale(
            scale: scale * pressScale,
            child: _buildCrownBody(context),
          );
        },
      ),
    );
  }

  Widget _buildCrownBody(BuildContext context) {
    final containerSize = widget.size + 20; // Original size
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: containerSize,
      height: containerSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Layer 1: Rotating Aura (VIP only)
          if (widget.isVip) _buildRotatingAura(containerSize, isDark),

          // Layer 2: Main Crown Icon
          _buildCrownIcon(context, isDark),

          // Layer 3: Shimmer Overlay
          _buildShimmerOverlay(containerSize),

          // Layer 4: Particles (Stars/Diamonds)
          ..._buildParticles(containerSize),
        ],
      ),
    );
  }


  /// Rotating rainbow aura for VIP
  Widget _buildRotatingAura(double size, bool isDark) {
    final auraOpacity = isDark ? 0.12 : 0.2; // Stronger in light mode
    return RotationTransition(
      turns: _rotationController,
      child: Container(
        width: size + 8,
        height: size + 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              Colors.transparent,
              AppColors.iridescentPink.withOpacity(auraOpacity),
              Colors.transparent,
              AppColors.iridescentPurple.withOpacity(auraOpacity),
              Colors.transparent,
              AppColors.iridescentBlue.withOpacity(auraOpacity),
              Colors.transparent,
              AppColors.iridescentGold.withOpacity(auraOpacity),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  /// Main crown icon with gradient
  Widget _buildCrownIcon(BuildContext context, bool isDark) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        if (widget.isVip) {
          // Diamond/Platinum gradient with iridescent effect
          // Use darker colors in light mode for visibility
          final baseColors = isDark
              ? [
                  AppColors.platinumGlow,
                  Color.lerp(
                    AppColors.iridescentBlue,
                    AppColors.iridescentPurple,
                    _iridescentAnimation.value,
                  )!,
                  AppColors.platinumShine,
                  Color.lerp(
                    AppColors.iridescentPurple,
                    AppColors.iridescentPink,
                    _iridescentAnimation.value,
                  )!,
                  AppColors.platinumGlow,
                ]
              : [
                  // Light mode: more saturated colors
                  AppColors.iridescentPurple,
                  Color.lerp(
                    AppColors.iridescentBlue,
                    AppColors.iridescentCyan,
                    _iridescentAnimation.value,
                  )!,
                  AppColors.iridescentPink,
                  Color.lerp(
                    AppColors.iridescentPurple,
                    AppColors.iridescentBlue,
                    _iridescentAnimation.value,
                  )!,
                  AppColors.iridescentPurple,
                ];

          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: baseColors,
            stops: [
              0.0,
              _shimmerAnimation.value.clamp(0.0, 1.0) * 0.3,
              0.5,
              0.7 + _shimmerAnimation.value.clamp(0.0, 1.0) * 0.15,
              1.0,
            ],
          ).createShader(bounds);
        } else {
          // Premium gold gradient with shimmer
          // Use darker/richer gold in light mode
          final goldColors = isDark
              ? [
                  AppColors.luxuryGoldDeep,
                  AppColors.luxuryGoldRich,
                  AppColors.luxuryGoldShine,
                  AppColors.luxuryGoldPrimary,
                  AppColors.luxuryGoldDeep,
                ]
              : [
                  // Light mode: amber/bronze tones for visibility
                  const Color(0xFF8B6914), // Darker bronze
                  AppColors.luxuryGoldDeep,
                  AppColors.luxuryGoldRich,
                  AppColors.luxuryGoldPrimary,
                  const Color(0xFF8B6914), // Darker bronze
                ];

          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: goldColors,
            stops: [
              0.0,
              (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
              _shimmerAnimation.value.clamp(0.0, 1.0),
              (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
              1.0,
            ],
          ).createShader(bounds);
        }
      },
      child: Icon(
        Icons.workspace_premium_rounded,
        size: widget.size,
        color: Colors.white,
      ),
    );
  }

  /// Shimmer overlay for extra shine
  Widget _buildShimmerOverlay(double size) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: math.pi / 6,
          child: ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.4),
                  Colors.white.withOpacity(0.0),
                  Colors.transparent,
                ],
                stops: [
                  0.0,
                  (_shimmerAnimation.value - 0.2).clamp(0.0, 1.0),
                  _shimmerAnimation.value.clamp(0.0, 1.0),
                  (_shimmerAnimation.value + 0.2).clamp(0.0, 1.0),
                  1.0,
                ],
              ).createShader(bounds);
            },
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(shape: BoxShape.circle),
            ),
          ),
        );
      },
    );
  }

  /// Particle system (stars, diamonds, sparkles)
  List<Widget> _buildParticles(double containerSize) {
    return _particles.map((config) {
      return _ParticleWidget(
        key: ValueKey('particle_${config.hashCode}'),
        config: config,
        parentSize: containerSize,
        isVip: widget.isVip,
      );
    }).toList();
  }

  // ══════════════════════════════════════════════════════════════════
  //                        VIP INFO DIALOG
  // ══════════════════════════════════════════════════════════════════

  void _showVipInfoDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vipInfo = widget.vipInfo!;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _VipDialogContent(
          animation: animation,
          vipInfo: vipInfo,
          isDark: isDark,
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//                        PARTICLE SYSTEM COMPONENTS
// ══════════════════════════════════════════════════════════════════════════

enum _ParticleType { star, diamond, sparkle }

class _ParticleConfig {
  final double angle;
  final double distRel;
  final double sizeScale;
  final Duration duration;
  final Duration delay;
  final _ParticleType type;

  _ParticleConfig({
    required this.angle,
    required this.distRel,
    required this.sizeScale,
    required this.duration,
    required this.delay,
    required this.type,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ParticleConfig &&
          angle == other.angle &&
          distRel == other.distRel &&
          sizeScale == other.sizeScale &&
          type == other.type;

  @override
  int get hashCode =>
      angle.hashCode ^
      distRel.hashCode ^
      sizeScale.hashCode ^
      type.hashCode;
}

class _ParticleWidget extends StatefulWidget {
  final _ParticleConfig config;
  final double parentSize;
  final bool isVip;

  const _ParticleWidget({
    super.key,
    required this.config,
    required this.parentSize,
    required this.isVip,
  });

  @override
  State<_ParticleWidget> createState() => _ParticleWidgetState();
}

class _ParticleWidgetState extends State<_ParticleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.config.duration,
      vsync: this,
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 0.8), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.0), weight: 30),
    ]).animate(_controller);

    _rotateAnimation = Tween<double>(begin: 0.0, end: math.pi * 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    Future.delayed(widget.config.delay, () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double r = (widget.parentSize / 2) * widget.config.distRel;
    double x = r * math.cos(widget.config.angle);
    double y = r * math.sin(widget.config.angle);
    double particleSize = 6 * widget.config.sizeScale;

    return Positioned(
      left: (widget.parentSize / 2) + x - particleSize / 2,
      top: (widget.parentSize / 2) + y - particleSize / 2,
      width: particleSize * 2,
      height: particleSize * 2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value * 0.9,
            child: Transform.scale(
              scale: _scaleAnimation.value * widget.config.sizeScale,
              child: Transform.rotate(
                angle: widget.config.type == _ParticleType.star
                    ? _rotateAnimation.value * 0.5
                    : _rotateAnimation.value,
                child: _buildParticleShape(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticleShape() {
    final color = widget.isVip
        ? _getVipParticleColor()
        : AppColors.luxuryGoldShine;

    switch (widget.config.type) {
      case _ParticleType.diamond:
        return CustomPaint(
          size: const Size(12, 12),
          painter: _DiamondPainter(color: color),
        );
      case _ParticleType.star:
        return Icon(
          Icons.star_rounded,
          size: 10,
          color: color,
        );
      case _ParticleType.sparkle:
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
    }
  }

  Color _getVipParticleColor() {
    final colors = [
      AppColors.iridescentPink,
      AppColors.iridescentPurple,
      AppColors.iridescentBlue,
      AppColors.platinumGlow,
      AppColors.iridescentGold,
    ];
    return colors[widget.config.angle.toInt() % colors.length];
  }
}

/// Custom diamond shape painter
class _DiamondPainter extends CustomPainter {
  final Color color;

  _DiamondPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height / 2);
    path.close();

    canvas.drawPath(path, paint);

    // Inner shine
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final shinePath = Path();
    shinePath.moveTo(size.width / 2, size.height * 0.15);
    shinePath.lineTo(size.width * 0.65, size.height / 2);
    shinePath.lineTo(size.width / 2, size.height * 0.35);
    shinePath.lineTo(size.width * 0.35, size.height / 2);
    shinePath.close();

    canvas.drawPath(shinePath, shinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════════════════════════
//                           VIP DIALOG CONTENT
// ══════════════════════════════════════════════════════════════════════════

class _VipDialogContent extends StatefulWidget {
  final Animation<double> animation;
  final VipInfo vipInfo;
  final bool isDark;

  const _VipDialogContent({
    required this.animation,
    required this.vipInfo,
    required this.isDark,
  });

  @override
  State<_VipDialogContent> createState() => _VipDialogContentState();
}

class _VipDialogContentState extends State<_VipDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        constraints: const BoxConstraints(maxWidth: 360),
        child: Material(
          color: Colors.transparent,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: widget.animation,
              curve: Curves.easeOutBack,
            ),
            child: FadeTransition(
              opacity: widget.animation,
              child: _buildDialogBody(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogBody() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: widget.isDark ? const Color(0xFF1A1A2E) : Colors.white,
        border: Border.all(
          color: AppColors.luxuryGoldPrimary.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.luxuryGoldPrimary.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Crown Badge
            _buildCrownBadge(),
            const SizedBox(height: 16),

            // VIP Title
            _buildVipTitle(),
            const SizedBox(height: 20),

            // Info Cards
            _buildInfoCards(),
            const SizedBox(height: 20),

            // Benefits List
            _buildBenefitsList(),
            const SizedBox(height: 20),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCrownBadge() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE55C),
            Color(0xFFFFD700),
            Color(0xFFDAA520),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.luxuryGoldPrimary.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.5),
                Colors.transparent,
              ],
              stops: [
                (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                _shimmerController.value.clamp(0.0, 1.0),
                (_shimmerController.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds),
            child: const Center(
              child: Icon(
                Icons.workspace_premium_rounded,
                size: 38,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVipTitle() {
    return Column(
      children: [
        Text(
          '✨ THÀNH VIÊN VIP ✨',
          style: TextStyle(
            fontSize: 11,
            color: widget.isDark
                ? AppColors.luxuryGoldLight
                : AppColors.luxuryGoldDeep,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFB8860B),
              Color(0xFFDAA520),
              Color(0xFFFFD700),
              Color(0xFFDAA520),
            ],
          ).createShader(bounds),
          child: Text(
            widget.vipInfo.planName.toUpperCase(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.event_available_rounded,
            label: 'Hết hạn',
            value: widget.vipInfo.expiryDate,
            color: AppColors.iridescentBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.timer_rounded,
            label: 'Còn lại',
            value: '${widget.vipInfo.daysRemaining} ngày',
            color: AppColors.luxuryGoldPrimary,
            isHighlight: true,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: isHighlight
            ? Border.all(color: color.withOpacity(0.4), width: 1)
            : null,
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: widget.isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isHighlight
                  ? color
                  : (widget.isDark ? Colors.white : Colors.black87),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (widget.isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: widget.vipInfo.benefits.map((benefit) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    benefit,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Close Button
        Expanded(
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: (widget.isDark ? Colors.white : Colors.black)
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Đóng',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Extend Button
        Expanded(
          flex: 2,
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to extend VIP screen
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDAA520), Color(0xFFFFD700)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.luxuryGoldPrimary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Gia hạn VIP',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//                              VIP INFO MODEL
// ══════════════════════════════════════════════════════════════════════════

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
