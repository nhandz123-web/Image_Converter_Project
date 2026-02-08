import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';

/// Class quản lý dữ liệu các công cụ
class ToolData {
  static List<Map<String, dynamic>> getTools(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return [
      {
        'id': 'img_to_pdf',
        'name': lang.imageToPdf ?? "Ảnh sang PDF",
        'icon': Icons.image_rounded,
        'color': const Color(0xFFF43F5E),
        'gradient': [const Color(0xFFF43F5E), const Color(0xFFEC4899)],
      },
      {
        'id': 'merge_pdf',
        'name': lang.mergePdf ?? "Ghép file PDF",
        'icon': Icons.merge_type_rounded,
        'color': const Color(0xFF8B5CF6),
        'gradient': [const Color(0xFF8B5CF6), const Color(0xFFA855F7)],
      },
      {
        'id': 'split_pdf',
        'name': lang.splitPdf ?? "Tách PDF",
        'icon': Icons.call_split_rounded,
        'color': const Color(0xFF06B6D4),
        'gradient': [const Color(0xFF06B6D4), const Color(0xFF0EA5E9)],
      },
      {
        'id': 'word_to_pdf',
        'name': lang.wordToPdf ?? "Word sang PDF",
        'icon': Icons.description_rounded,
        'color': const Color(0xFF3B82F6),
        'gradient': [const Color(0xFF3B82F6), const Color(0xFF6366F1)],
      },
      {
        'id': 'excel_to_pdf',
        'name': lang.excelToPdf ?? "Excel sang PDF",
        'icon': Icons.table_chart_rounded,
        'color': const Color(0xFF22C55E),
        'gradient': [const Color(0xFF22C55E), const Color(0xFF14B8A6)],
      },
      {
        'id': 'qr_scan',
        'name': lang.qrScan ?? "Quét mã QR",
        'icon': Icons.qr_code_scanner_rounded,
        'color': const Color(0xFFF97316),
        'gradient': [const Color(0xFFF97316), const Color(0xFFFB923C)],
      },
      {
        'id': 'compress',
        'name': lang.compress ?? "Nén file",
        'icon': Icons.compress_rounded,
        'color': const Color(0xFF10B981),
        'gradient': [const Color(0xFF10B981), const Color(0xFF34D399)],
      },
    ];
  }
}

/// Callback type cho khi tool được chọn
typedef OnToolSelected = void Function(String toolId);

/// Widget hiển thị grid các công cụ chuyển đổi
/// Style: Glassmorphism Modern
class ToolGrid extends StatelessWidget {
  final ThemeData theme;
  final OnToolSelected onToolSelected;
  final int? limit; // Giới hạn số lượng hiển thị

  const ToolGrid({
    super.key,
    required this.theme,
    required this.onToolSelected,
    this.limit,
  });

  @override
  Widget build(BuildContext context) {
    final allTools = ToolData.getTools(context);
    final tools = limit != null && limit! < allTools.length 
        ? allTools.take(limit!).toList() 
        : allTools;
    final isDark = theme.brightness == Brightness.dark;

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
    final List<Color> gradientColors = tool['gradient'] as List<Color>;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onToolSelected(tool['id']),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withOpacity(0.08) 
                    : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withOpacity(0.1) 
                      : Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withOpacity(0.2) 
                        : Colors.blue.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            gradientColors[0].withOpacity(0.15),
                            gradientColors[1].withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: gradientColors[0].withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Icon(
                          tool['icon'],
                          size: 28,
                          color: Colors.white, // Color is ignored by ShaderMask
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Text
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
                            : const Color(0xFF1E293B), // Slate-800
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}