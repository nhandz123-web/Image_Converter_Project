import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../../../blocs/home_bloc.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_styles.dart';
import '../../../theme/app_component_styles.dart';

/// Dialog chọn file PDF để merge
/// Style: Glassmorphism Modern
class MergePdfDialog extends StatefulWidget {
  const MergePdfDialog({super.key});

  /// Hiển thị dialog và trả về danh sách ID đã chọn
  static void show(BuildContext context) {
    // Load lại history trước khi hiển thị
    context.read<HomeBloc>().add(LoadHistoryRequested());
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => const MergePdfDialog(),
    );
  }

  @override
  State<MergePdfDialog> createState() => _MergePdfDialogState();
}

class _MergePdfDialogState extends State<MergePdfDialog> {
  List<int> selectedIds = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: AppComponentStyles.modalGlass(
            isDark: isDark,
            borderRadius: 30,
          ),
          child: Column(
            children: [
              // ═══════════ DRAG HANDLE ═══════════
              _buildDragHandle(isDark),

              // ═══════════ HEADER ═══════════
              _buildHeader(lang, isDark),

              // ═══════════ PDF LIST ═══════════
              Expanded(child: _buildPdfList(lang, isDark)),

              // ═══════════ SELECTED FILES PREVIEW ═══════════
              if (selectedIds.isNotEmpty) _buildSelectedPreview(lang, isDark),

              // ═══════════ HELPER TEXT ═══════════
              if (selectedIds.length < 2)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text(
                        lang.selectAtLeast2Files ?? "Vui lòng chọn ít nhất 2 file để ghép",
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              // ═══════════ MERGE BUTTON ═══════════
              _buildMergeButton(lang, isDark),
              
              SizedBox(height: MediaQuery.of(context).padding.bottom + 10), // Safe area
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: AppComponentStyles.dragHandle(isDark),
    );
  }

  Widget _buildHeader(AppLocalizations lang, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Text(
            lang.mergePdf ?? "Ghép file PDF",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          if (selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: AppComponentStyles.badgeContainer(
                  color: AppColors.primary,
                  borderRadius: 20,
                ),
                child: Text(
                  "${lang.selectedFiles(selectedIds.length)}",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPdfList(AppLocalizations lang, bool isDark) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HistoryLoaded) {
          final pdfFiles = state.documents.where((d) {
            final fileName =
                (d['name'] ?? d['original_name'] ?? '').toString().toLowerCase();
            return d['type'] == 'pdf' || fileName.endsWith('.pdf');
          }).toList();

          if (pdfFiles.isEmpty) {
            return _buildEmptyState(lang, isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: pdfFiles.length,
            itemBuilder: (context, index) {
              final doc = pdfFiles[index];
              return _buildPdfItem(doc, lang, isDark);
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations lang, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppComponentStyles.emptyStateIcon(
              isDark: isDark,
              size: 80,
            ),
            child: Icon(
              Icons.picture_as_pdf_outlined,
              size: 48,
              color: isDark ? Colors.white24 : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            lang.noPdfFiles ?? "Không có file PDF nào",
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Hãy tạo hoặc tải thêm file PDF để ghép",
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfItem(Map<String, dynamic> doc, AppLocalizations lang, bool isDark) {
    final docId = doc['id'];
    final bool isSelected = selectedIds.contains(docId);
    final int selectionOrder = isSelected ? selectedIds.indexOf(docId) + 1 : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              final id = docId as int;
              if (isSelected) {
                selectedIds.remove(id);
              } else {
                selectedIds.add(id);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: AppComponentStyles.pdfItemCard(
              isDark: isDark,
              isSelected: isSelected,
              borderRadius: 16,
            ),
            child: Row(
              children: [
                // PDF Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: AppComponentStyles.pdfIconDecoration(borderRadius: 12),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Color(0xFFF43F5E),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // File Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc['name']?.toString() ??
                            doc['original_name']?.toString() ??
                            'No name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                         // Size handling
                         doc['size'] != null 
                            ? (doc['size'] is int 
                                ? (doc['size'] < 1024 
                                    ? '${doc['size']} B' 
                                    : (doc['size'] < 1024 * 1024 
                                        ? '${(doc['size'] / 1024).toStringAsFixed(1)} KB' 
                                        : '${(doc['size'] / (1024 * 1024)).toStringAsFixed(2)} MB'))
                                : doc['size'].toString())
                            : 'Unknown size',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection Badge
                _buildSelectionBadge(isSelected, selectionOrder, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBadge(bool isSelected, int order, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28,
      height: 28,
      decoration: AppComponentStyles.selectionBadge(
        isSelected: isSelected,
        isDark: isDark,
      ),
      child: Center(
        child: isSelected
            ? Text(
                "$order",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildSelectedPreview(AppLocalizations lang, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sort_rounded, size: 16, color: isDark ? Colors.white54 : Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                "${lang.mergeOrder ?? "Thứ tự ghép"}:",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                if (state is HistoryLoaded) {
                  return Row(
                    children: List.generate(selectedIds.length, (index) {
                      final docId = selectedIds[index];
                      final doc = state.documents.firstWhere(
                        (d) => d['id'] == docId,
                        orElse: () => {'name': lang.unknown ?? 'Unknown'},
                      );
                      return _buildSelectedChip(doc, index, isDark);
                    }),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedChip(Map<String, dynamic> doc, int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: AppComponentStyles.selectedChip(isDark: isDark),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "${index + 1}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              doc['name']?.toString() ??
                  doc['original_name']?.toString() ??
                  'No name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMergeButton(AppLocalizations lang, bool isDark) {
    final isDisabled = selectedIds.length < 2;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: isDisabled ? null : AppComponentStyles.mergeButtonShadow(borderRadius: 16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: isDark ? Colors.white10 : Colors.grey[300],
            disabledForegroundColor: isDark ? Colors.white38 : Colors.grey[500],
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          onPressed: isDisabled
              ? null
              : () {
                  context.read<HomeBloc>().add(MergePdfsRequested(selectedIds));
                  Navigator.pop(context);
                },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.merge_type_rounded, size: 24),
              const SizedBox(width: 12),
              Text(
                "${lang.mergeNow ?? "Gộp ngay"} (${selectedIds.length})",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
