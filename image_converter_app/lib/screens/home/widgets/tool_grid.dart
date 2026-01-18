import 'package:flutter/material.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

/// Callback type cho khi tool được chọn
typedef OnToolSelected = void Function(String toolId);

/// Widget hiển thị grid các công cụ chuyển đổi
/// Đã được cải thiện với thiết kế đẹp hơn cho Light Mode
class ToolGrid extends StatelessWidget {
  final ThemeData theme;
  final OnToolSelected onToolSelected;

  const ToolGrid({
    super.key,
    required this.theme,
    required this.onToolSelected,
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    
    // Sử dụng màu soft hơn cho Light Mode
    final List<Map<String, dynamic>> tools = [
      {
        'id': 'img_to_pdf',
        'name': lang.imageToPdf ?? "Ảnh sang PDF",
        'icon': Icons.image_rounded,
        'color': isDark ? Colors.redAccent : const Color(0xFFF43F5E),
        'gradient': [const Color(0xFFF43F5E), const Color(0xFFEC4899)],
      },
      {
        'id': 'word_to_pdf',
        'name': lang.wordToPdf ?? "Word sang PDF",
        'icon': Icons.description_rounded,
        'color': isDark ? Colors.blue : const Color(0xFF3B82F6),
        'gradient': [const Color(0xFF3B82F6), const Color(0xFF6366F1)],
      },
      {
        'id': 'excel_to_pdf',
        'name': lang.excelToPdf ?? "Excel sang PDF",
        'icon': Icons.table_chart_rounded,
        'color': isDark ? Colors.green : const Color(0xFF22C55E),
        'gradient': [const Color(0xFF22C55E), const Color(0xFF14B8A6)],
      },
      {
        'id': 'qr_scan',
        'name': lang.qrScan ?? "Quét mã QR",
        'icon': Icons.qr_code_scanner_rounded,
        'color': isDark ? Colors.orange : const Color(0xFFF97316),
        'gradient': [const Color(0xFFF97316), const Color(0xFFFB923C)],
      },
      {
        'id': 'merge_pdf',
        'name': lang.mergePdf ?? "Ghép file PDF",
        'icon': Icons.merge_type_rounded,
        'color': isDark ? Colors.purple : const Color(0xFF8B5CF6),
        'gradient': [const Color(0xFF8B5CF6), const Color(0xFFA855F7)],
      },
      {
        'id': 'compress',
        'name': lang.compressData ?? "Nén dữ liệu",
        'icon': Icons.compress_rounded,
        'color': isDark ? Colors.teal : const Color(0xFF14B8A6),
        'gradient': [const Color(0xFF14B8A6), const Color(0xFF06B6D4)],
      },
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: tools.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) => _buildToolCard(tools[index], isDark),
    );
  }

  Widget _buildToolCard(Map<String, dynamic> tool, bool isDark) {
    final Color mainColor = tool['color'] as Color;
    final List<Color> gradientColors = tool['gradient'] as List<Color>;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onToolSelected(tool['id']),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isDark ? null : Border.all(
              color: mainColor.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.3)
                    : mainColor.withOpacity(0.15),
                blurRadius: isDark ? 8 : 16,
                offset: const Offset(0, 6),
                spreadRadius: isDark ? 0 : -4,
              ),
              if (!isDark) BoxShadow(
                color: Colors.white,
                blurRadius: 10,
                offset: const Offset(-5, -5),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon container với gradient
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: isDark ? null : LinearGradient(
                      colors: [
                        gradientColors[0].withOpacity(0.15),
                        gradientColors[1].withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    color: isDark ? mainColor.withOpacity(0.15) : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: mainColor.withOpacity(isDark ? 0.2 : 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: isDark 
                          ? [mainColor, mainColor]
                          : gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Icon(
                      tool['icon'],
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Text với style cải thiện
                Text(
                  tool['name'],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark 
                        ? Colors.white.withOpacity(0.9) 
                        : Colors.grey[800],
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
