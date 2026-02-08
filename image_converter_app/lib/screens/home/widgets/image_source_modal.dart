import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_styles.dart';
import '../../../theme/app_component_styles.dart';

/// Modal bottom sheet để chọn nguồn ảnh (Camera hoặc Gallery)
/// Style: Glassmorphism Modern
class ImageSourceModal extends StatelessWidget {
  final VoidCallback onCameraSelected;
  final VoidCallback onGallerySelected;

  const ImageSourceModal({
    super.key,
    required this.onCameraSelected,
    required this.onGallerySelected,
  });

  /// Hiển thị modal và xử lý selection
  static Future<void> show({
    required BuildContext context,
    required VoidCallback onCameraSelected,
    required VoidCallback onGallerySelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = AppLocalizations.of(context)!;

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Để modal linh hoạt chiều cao hơn
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              decoration: AppComponentStyles.bottomSheetGlass(
                isDark: isDark,
                borderRadius: 30,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: AppComponentStyles.dragHandle(isDark),
                  ),
                  
                  // Title
                  Text(
                    lang.chooseImageFrom ?? "Chọn nguồn ảnh",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _SourceButton(
                        icon: Icons.camera_alt_rounded,
                        label: lang.camera ?? "Máy ảnh",
                        color: AppColors.blue, // Blue
                        gradientColors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                        onTap: () {
                          Navigator.pop(ctx);
                          onCameraSelected();
                        },
                        isDark: isDark,
                      ),
                      _SourceButton(
                        icon: Icons.photo_library_rounded,
                        label: lang.gallery ?? "Thư viện",
                        color: AppColors.green, // Green
                        gradientColors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
                        onTap: () {
                          Navigator.pop(ctx);
                          onGallerySelected();
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(); // Không dùng trực tiếp, dùng static show()
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final bool isDark;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.gradientColors,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Container
          Container(
            width: 80,
            height: 80,
            decoration: AppComponentStyles.iconGradientContainer(
              gradientColors: gradientColors,
              borderRadius: 24,
              withBorder: true,
              withShadow: true,
            ),
            child: Icon(
              icon,
              color: gradientColors[1],
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          
          // Label
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
