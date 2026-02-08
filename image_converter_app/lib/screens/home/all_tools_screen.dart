import 'package:flutter/material.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import 'widgets/tool_grid.dart';

class AllToolsScreen extends StatelessWidget {
  final Function(String) onToolSelected;

  const AllToolsScreen({
    super.key,
    required this.onToolSelected,
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          lang.popularTools ?? "Tất cả công cụ",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: ClipRect(
          child: Container(
            color: isDark 
                ? Colors.black.withOpacity(0.5) 
                : Colors.white.withOpacity(0.5),
            child: const SizedBox.expand(),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.backgroundGradientDark
              : AppColors.backgroundGradientLight,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.chooseToolBelow ?? "Chọn công cụ bạn muốn sử dụng",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Hiển thị tất cả tools (không limit)
                ToolGrid(
                  theme: theme,
                  onToolSelected: (toolId) {
                    onToolSelected(toolId);
                    // Có thể pop screen này sau khi chọn nếu muốn behavior giống như menu
                    // Navigator.pop(context); 
                  },
                  limit: null, 
                ),
                
                // Khoảng trống dưới cùng để tránh bị che bởi navigation bar nếu có
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
