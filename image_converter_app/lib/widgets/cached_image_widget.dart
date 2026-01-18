import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';

/// Widget wrapper cho CachedNetworkImage với các tiện ích tích hợp sẵn:
/// - Lazy loading (chỉ load khi widget visible)
/// - Disk caching tự động
/// - Placeholder với shimmer effect
/// - Error widget tùy chỉnh
/// - Fade animation khi load xong
class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;
  final Color? placeholderColor;
  final bool showProgressIndicator;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.placeholderColor,
    this.showProgressIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: const Duration(milliseconds: 100),
      
      // Placeholder trong lúc loading
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(isDark),
      
      // Progress indicator
      progressIndicatorBuilder: showProgressIndicator 
          ? (context, url, downloadProgress) => _buildProgressIndicator(downloadProgress, isDark)
          : null,
      
      // Error widget khi load thất bại
      errorWidget: (context, url, error) => errorWidget ?? _buildDefaultErrorWidget(isDark),
    );

    // Wrap với ClipRRect nếu có borderRadius
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Placeholder mặc định với shimmer effect
  Widget _buildDefaultPlaceholder(bool isDark) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: placeholderColor ?? (isDark ? AppColors.grey800 : AppColors.grey200),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: _ShimmerLoading(
          isLoading: true,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey700 : AppColors.grey300,
              borderRadius: borderRadius,
            ),
          ),
        ),
      ),
    );
  }

  /// Progress indicator với phần trăm
  Widget _buildProgressIndicator(DownloadProgress progress, bool isDark) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : AppColors.grey200,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: progress.progress,
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? AppColors.blue300 : AppColors.primary,
                ),
                backgroundColor: isDark ? AppColors.grey700 : AppColors.grey300,
              ),
            ),
            if (progress.progress != null) ...[
              const SizedBox(height: 8),
              Text(
                '${(progress.progress! * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.grey400 : AppColors.grey600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Error widget mặc định
  Widget _buildDefaultErrorWidget(bool isDark) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : AppColors.grey200,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_rounded,
              size: 48,
              color: isDark ? AppColors.grey600 : AppColors.grey400,
            ),
            const SizedBox(height: 8),
            Text(
              'Không thể tải ảnh',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.grey500 : AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading effect
class _ShimmerLoading extends StatefulWidget {
  final bool isLoading;
  final Widget child;

  const _ShimmerLoading({
    required this.isLoading,
    required this.child,
  });

  @override
  State<_ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<_ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
  }

  @override
  void dispose() {
    // ✅ CRITICAL FIX: Stop animation trước khi dispose để tránh memory leak
    _shimmerController.stop();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: isDark
                  ? [
                      AppColors.grey800,
                      AppColors.grey700,
                      AppColors.grey800,
                    ]
                  : [
                      AppColors.grey200,
                      AppColors.grey100,
                      AppColors.grey200,
                    ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + _shimmerController.value * 2, 0.0),
              end: Alignment(1.0 + _shimmerController.value * 2, 0.0),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Extension cho việc clear cache
extension CachedImageHelper on CachedImageWidget {
  /// Clear cache của một ảnh cụ thể
  static Future<void> clearCacheForUrl(String url) async {
    await CachedNetworkImage.evictFromCache(url);
  }
  
  /// Clear toàn bộ cache (cẩn thận khi sử dụng)
  // static Future<void> clearAllCache() async {
  //   await DefaultCacheManager().emptyCache();
  // }
}
