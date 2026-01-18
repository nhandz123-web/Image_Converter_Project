import 'package:flutter/material.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

/// Widget hiển thị section title với thanh dọc bên trái
class SectionTitle extends StatelessWidget {
  final ThemeData theme;
  final String title;

  const SectionTitle({
    super.key,
    required this.theme,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: AppDimensions.spacing4,
          height: AppDimensions.spacing20,
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: AppDimensions.borderRadius2,
          ),
        ),
        const SizedBox(width: AppDimensions.spacing10),
        Text(
          title,
          style: TextStyle(
            fontSize: AppTextStyles.fontSize18,
            fontWeight: AppTextStyles.weightBold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }
}

/// Widget hiển thị loading overlay
class LoadingOverlay extends StatelessWidget {
  final ThemeData theme;

  const LoadingOverlay({
    super.key,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: AppDimensions.paddingAll20,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: AppDimensions.borderRadius15,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppDimensions.spacing15),
              Text(lang.processing ?? "Đang xử lý..."),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget hiển thị nút modal (Camera/Gallery)
class ModalButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final ThemeData theme;
  final VoidCallback onTap;

  const ModalButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: AppDimensions.paddingV20,
        decoration: BoxDecoration(
          color: color.withOpacity(AppColors.opacity10),
          borderRadius: AppDimensions.borderRadius15,
          border: Border.all(color: color.withOpacity(AppColors.opacity30)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: AppDimensions.iconSizeXXLarge),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: AppTextStyles.weightBold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
