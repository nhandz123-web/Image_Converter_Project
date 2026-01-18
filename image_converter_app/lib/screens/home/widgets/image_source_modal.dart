import 'package:flutter/material.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';

/// Modal bottom sheet để chọn nguồn ảnh (Camera hoặc Gallery)
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
    final lang = AppLocalizations.of(context)!;

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: AppDimensions.paddingAll20,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: AppDimensions.borderRadiusTop25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: AppDimensions.dragHandleWidth,
                height: AppDimensions.dragHandleHeight,
                margin: const EdgeInsets.only(bottom: AppDimensions.spacing20),
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: AppDimensions.borderRadius2,
                ),
              ),
              
              // Title
              const Text(
                "Chọn nguồn ảnh",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing20),
              
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: lang.camera ?? "Máy ảnh",
                    color: AppColors.blue,
                    onTap: () {
                      Navigator.pop(ctx);
                      onCameraSelected();
                    },
                  ),
                  _SourceButton(
                    icon: Icons.photo_library_rounded,
                    label: lang.gallery ?? "Thư viện",
                    color: AppColors.green,
                    onTap: () {
                      Navigator.pop(ctx);
                      onGallerySelected();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.spacing20),
            ],
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
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppDimensions.borderRadius15,
      child: Container(
        width: 120,
        padding: AppDimensions.paddingV20,
        decoration: BoxDecoration(
          color: color.withOpacity(AppColors.opacity10),
          borderRadius: AppDimensions.borderRadius15,
          border: Border.all(color: color.withOpacity(AppColors.opacity30)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: AppDimensions.iconSizeXXLarge),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
