import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_styles.dart';

/// Widget hiển thị card chào mừng trên màn hình Home
/// Style: Glassmorphism Modern
class WelcomeCard extends StatelessWidget {
  final bool isDark;

  const WelcomeCard({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    
    return ClipRRect(
      borderRadius: AppDimensions.borderRadius24,
      child: Stack(
        children: [
          // Background với Gradient
          Container(
            height: 180, // Chiều cao cố định để đảm bảo hiển thị đẹp
            decoration: AppStyles.welcomeCardBackground(isDark),
          ),

          // Decorative Blobs (Vòng trang trí mờ ảo)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: AppStyles.decorativeBlob(isDark),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: AppStyles.decorativeBlob(isDark),
            ),
          ),

          // Glass Effect Layer (Lớp kính mờ)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
                decoration: AppStyles.glassContainer(isDark),
              ),
            ),
          ),

          // Main Content
          Padding(
            padding: AppDimensions.paddingAll24,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting Tag
                      Container(
                        padding: AppDimensions.paddingH12V6,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: AppStyles.greetingTag,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("👋", style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              lang.welcomeMessage ?? "Xin chào!",
                              style: AppStyles.welcomeGreeting,
                            ),
                          ],
                        ),
                      ),
                      
                      // Hero Text
                      Text(
                        lang.chooseToolBelow ?? "Công cụ chuyển đổi\nđa năng của bạn",
                        style: AppStyles.welcomeTitle,
                      ),
                    ],
                  ),
                ),
                
                // 3D/Glass Icon minh hoạ bên phải
                Container(
                  width: 80,
                  height: 80,
                  decoration: AppStyles.iconGlassDecoration(isDark),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
