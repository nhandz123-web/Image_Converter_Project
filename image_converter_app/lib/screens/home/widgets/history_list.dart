import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../../../blocs/home_bloc.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../file_detail_screen.dart';

/// Widget hiển thị danh sách tài liệu gần đây
/// Đã được cải thiện với thiết kế đẹp hơn cho Light Mode
class HistoryList extends StatelessWidget {
  final HomeState state;
  final ThemeData theme;
  final int maxItems;

  const HistoryList({
    super.key,
    required this.state,
    required this.theme,
    this.maxItems = 5,
  });

  bool get isDark => theme.brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    if (state is HistoryLoaded) {
      final historyState = state as HistoryLoaded;
      if (historyState.documents.isEmpty) {
        return _buildEmptyState(lang);
      }

      final displayDocs = historyState.documents.take(maxItems).toList();

      return Column(
        children: [
          // Cache indicator
          if (historyState.isFromCache)
            _buildCacheIndicator(context, lang, historyState.cacheTime),
          
          // Document list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayDocs.length,
            itemBuilder: (context, index) {
              final doc = displayDocs[index];
              return _buildDocumentItem(context, doc, lang);
            },
          ),
        ],
      );
    }
    
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState(AppLocalizations lang) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.grey[800] 
                  : AppColors.softPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_open_rounded,
              size: 48,
              color: isDark ? Colors.grey[400] : AppColors.softPurple,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            lang.noFiles ?? "Chưa có file nào",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Bắt đầu bằng cách chọn công cụ ở trên",
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheIndicator(
    BuildContext context,
    AppLocalizations lang,
    DateTime? cacheTime,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacing12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.orange.withOpacity(0.15) 
            : AppColors.softOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? Colors.orange.withOpacity(0.3) 
              : AppColors.softOrange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded, 
            size: 16, 
            color: isDark ? Colors.orange[300] : AppColors.softOrange,
          ),
          const SizedBox(width: 8),
          Text(
            cacheTime != null
                ? "Offline • ${_formatCacheTime(cacheTime)}"
                : "Đang dùng cache",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.orange[300] : AppColors.softOrange,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () {
              context.read<HomeBloc>().add(LoadHistoryRequested(forceRefresh: true));
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.orange.withOpacity(0.2) 
                    : AppColors.softOrange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.refresh_rounded, 
                size: 14, 
                color: isDark ? Colors.orange[300] : AppColors.softOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(
    BuildContext context,
    Map<String, dynamic> doc,
    AppLocalizations lang,
  ) {
    String fileName = doc['name']?.toString() ?? "Không tên";

    bool isPdf = (doc['type'] == 'pdf') ||
        fileName.toLowerCase().endsWith('.pdf');

    String dateDisplay = "";
    if (doc['created_at'] != null) {
      String rawDate = doc['created_at'].toString();
      dateDisplay = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
    }

    final Color iconColor = isPdf 
        ? (isDark ? Colors.redAccent : const Color(0xFFF43F5E))
        : (isDark ? Colors.blue : const Color(0xFF3B82F6));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? null : Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.2) 
                : iconColor.withOpacity(0.08),
            blurRadius: isDark ? 8 : 16,
            offset: const Offset(0, 4),
            spreadRadius: isDark ? 0 : -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FileDetailScreen(document: doc)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: iconColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName, 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateDisplay,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.grey[800] 
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCacheTime(DateTime cacheTime) {
    final now = DateTime.now();
    final diff = now.difference(cacheTime);

    if (diff.inMinutes < 1) {
      return "vừa xong";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes} phút trước";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} giờ trước";
    } else {
      return "${diff.inDays} ngày trước";
    }
  }
}
