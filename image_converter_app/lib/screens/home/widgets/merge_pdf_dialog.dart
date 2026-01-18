import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../../../blocs/home_bloc.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

/// Dialog chọn file PDF để merge
/// Hiển thị dưới dạng ModalBottomSheet
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: AppDimensions.borderRadiusTop25,
      ),
      child: Column(
        children: [
          // ═══════════ DRAG HANDLE ═══════════
          _buildDragHandle(),

          // ═══════════ HEADER ═══════════
          _buildHeader(lang),

          // ═══════════ PDF LIST ═══════════
          Expanded(child: _buildPdfList(lang)),

          // ═══════════ SELECTED FILES PREVIEW ═══════════
          if (selectedIds.isNotEmpty) _buildSelectedPreview(lang),

          // ═══════════ HELPER TEXT ═══════════
          if (selectedIds.length < 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                lang.selectAtLeast2Files ?? "Please select at least 2 files",
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // ═══════════ MERGE BUTTON ═══════════
          _buildMergeButton(lang),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.spacing12),
      width: AppDimensions.dragHandleWidth,
      height: AppDimensions.dragHandleHeight,
      decoration: BoxDecoration(
        color: AppColors.grey300,
        borderRadius: AppDimensions.borderRadius2,
      ),
    );
  }

  Widget _buildHeader(AppLocalizations lang) {
    return Padding(
      padding: AppDimensions.paddingAll20,
      child: Column(
        children: [
          Text(
            lang.mergePdf ?? "Merge PDF",
            style: AppTextStyles.h3,
          ),
          if (selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.spacing8),
              child: Text(
                "${lang.mergeOrderSelected ?? "Selected"}: ${selectedIds.length} ${lang.filesSelected ?? "files"}",
                style: TextStyle(
                  fontSize: AppTextStyles.fontSize13,
                  color: AppColors.grey600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPdfList(AppLocalizations lang) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HistoryLoaded) {
          final pdfFiles = state.documents.where((d) {
            final fileName =
                (d['name'] ?? d['original_name'] ?? '').toString().toLowerCase();
            return d['type'] == 'pdf' || fileName.endsWith('.pdf');
          }).toList();

          if (pdfFiles.isEmpty) {
            return _buildEmptyState(lang);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: pdfFiles.length,
            itemBuilder: (context, index) {
              final doc = pdfFiles[index];
              return _buildPdfItem(doc, lang);
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: AppDimensions.iconSizeMassive,
            color: AppColors.grey400,
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Text(
            lang.noPdfFiles ?? "No PDF files available",
            style: TextStyle(color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfItem(Map<String, dynamic> doc, AppLocalizations lang) {
    final docId = doc['id'];
    final bool isSelected = selectedIds.contains(docId);
    final int selectionOrder =
        isSelected ? selectedIds.indexOf(docId) + 1 : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.purple.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.purple : Colors.grey.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // PDF Icon
                Container(
                  padding: AppDimensions.paddingAll8,
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(AppColors.opacity10),
                    borderRadius: AppDimensions.borderRadius8,
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: AppColors.red,
                    size: AppDimensions.iconSizeRegular,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),

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
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (isSelected)
                        Text(
                          "${lang.orderNumber ?? "Order"}: $selectionOrder",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.purple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),

                // Selection Badge
                _buildSelectionBadge(isSelected, selectionOrder),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBadge(bool isSelected, int order) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isSelected ? Colors.purple : Colors.grey.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.purple : Colors.grey.withOpacity(0.5),
          width: 2,
        ),
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
            : Icon(
                Icons.add,
                size: 18,
                color: Colors.grey[600],
              ),
      ),
    );
  }

  Widget _buildSelectedPreview(AppLocalizations lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${lang.mergeOrder ?? "Merge order"}:",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
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
                      return _buildSelectedChip(doc, index);
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

  Widget _buildSelectedChip(Map<String, dynamic> doc, int index) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: Colors.purple,
            child: Text(
              "${index + 1}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              doc['name']?.toString() ??
                  doc['original_name']?.toString() ??
                  'No name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMergeButton(AppLocalizations lang) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: selectedIds.length < 2 ? 0 : 4,
        ),
        onPressed: selectedIds.length < 2
            ? null
            : () {
                context.read<HomeBloc>().add(MergePdfsRequested(selectedIds));
                Navigator.pop(context);
              },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.merge_type),
            const SizedBox(width: 8),
            Text(
              "${lang.mergeNow ?? "Merge now"} (${selectedIds.length})",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
