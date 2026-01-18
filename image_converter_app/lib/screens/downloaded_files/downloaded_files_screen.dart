import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

import '../../blocs/downloaded_files_bloc.dart';
import '../../services/local_file_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../l10n/app_localizations.dart';
import '../file_preview_screen.dart';

/// Màn hình hiển thị các file đã tải xuống
/// Hoạt động hoàn toàn OFFLINE
class DownloadedFilesScreen extends StatefulWidget {
  const DownloadedFilesScreen({super.key});

  @override
  State<DownloadedFilesScreen> createState() => _DownloadedFilesScreenState();
}

class _DownloadedFilesScreenState extends State<DownloadedFilesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DownloadedFilesBloc>().add(LoadDownloadedFilesRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = AppLocalizations.of(context)!;

    return BlocConsumer<DownloadedFilesBloc, DownloadedFilesState>(
      listener: _handleBlocListener,
      builder: (context, state) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppColors.backgroundGradientDark
                  : AppColors.backgroundGradientLight,
            ),
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<DownloadedFilesBloc>().add(LoadDownloadedFilesRequested());
                // Đợi một chút để animation refresh hoàn tất
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: AppColors.primary,
              backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildAppBar(isDark, state, lang),
                  _buildBody(state, theme, isDark, lang),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleBlocListener(BuildContext context, DownloadedFilesState state) {
    if (state is DownloadedFilesSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.success,
        ),
      );
    }

    if (state is DownloadedFilesError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════
  //                         APP BAR
  // ════════════════════════════════════════════════════════════════

  Widget _buildAppBar(bool isDark, DownloadedFilesState state, AppLocalizations lang) {
    final isSelectMode = state is DownloadedFilesLoaded && state.isSelectMode;
    final selectedCount = state is DownloadedFilesLoaded ? state.selectedFileIds.length : 0;

    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: AppDimensions.elevation0,
      toolbarHeight: AppDimensions.appBarHeight,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.appBarGradientDark
              : AppColors.appBarGradientLight,
        ),
        child: SafeArea(
          child: Padding(
            padding: AppDimensions.paddingH16,
            child: Row(
              children: [
                // Icon hoặc Back button
                Container(
                  padding: AppDimensions.paddingAll8,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(AppColors.opacity20),
                    borderRadius: AppDimensions.borderRadius12,
                  ),
                  child: Icon(
                    isSelectMode ? Icons.check_box_outlined : Icons.folder_rounded,
                    color: AppColors.white,
                    size: AppDimensions.iconSizeRegular,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),

                // Title
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSelectMode 
                            ? lang.selectedFiles(selectedCount)
                            : lang.downloadedFiles,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: AppTextStyles.weightBold,
                          fontSize: AppTextStyles.fontSize20,
                        ),
                      ),
                      if (!isSelectMode && state is DownloadedFilesLoaded)
                        Text(
                          lang.totalSize(state.totalSize),
                          style: TextStyle(
                            color: AppColors.white.withOpacity(0.8),
                            fontSize: AppTextStyles.fontSize12,
                          ),
                        ),
                    ],
                  ),
                ),

                // Actions
                if (isSelectMode) ...[
                  IconButton(
                    icon: const Icon(Icons.select_all, color: AppColors.white),
                    onPressed: () {
                      context.read<DownloadedFilesBloc>().add(SelectAllFiles());
                    },
                    tooltip: lang.selectAll,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.white),
                    onPressed: selectedCount > 0 ? () => _showDeleteConfirmDialog(lang) : null,
                    tooltip: lang.delete,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.white),
                    onPressed: () {
                      context.read<DownloadedFilesBloc>().add(ToggleSelectMode());
                    },
                    tooltip: lang.cancel,
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.checklist_rounded, color: AppColors.white),
                    onPressed: () {
                      context.read<DownloadedFilesBloc>().add(ToggleSelectMode());
                    },
                    tooltip: lang.selectMultiple,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //                         BODY
  // ════════════════════════════════════════════════════════════════

  Widget _buildBody(
    DownloadedFilesState state,
    ThemeData theme,
    bool isDark,
    AppLocalizations lang,
  ) {
    if (state is DownloadedFilesLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is DownloadedFilesLoaded) {
      if (state.files.isEmpty) {
        return SliverFillRemaining(
          child: _buildEmptyState(isDark, lang),
        );
      }

      return SliverPadding(
        padding: AppDimensions.paddingAll16,
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final file = state.files[index];
              final isSelected = state.selectedFileIds.contains(file.id);
              
              return _buildFileCard(
                file: file,
                isDark: isDark,
                theme: theme,
                isSelectMode: state.isSelectMode,
                isSelected: isSelected,
                lang: lang,
              );
            },
            childCount: state.files.length,
          ),
        ),
      );
    }

    return SliverFillRemaining(
      child: Center(child: Text(lang.loading)),
    );
  }

  Widget _buildEmptyState(bool isDark, AppLocalizations lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon với gradient background
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.blue900.withOpacity(0.3), AppColors.purple400.withOpacity(0.3)]
                    : [AppColors.softBlue.withOpacity(0.1), AppColors.softPurple.withOpacity(0.1)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_off_outlined,
              size: 80,
              color: isDark ? AppColors.grey400 : AppColors.grey500,
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            lang.noFilesYet,
            style: TextStyle(
              fontSize: AppTextStyles.fontSize20,
              fontWeight: AppTextStyles.weightSemiBold,
              color: isDark ? AppColors.white : AppColors.grey800,
            ),
          ),
          const SizedBox(height: 8),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              lang.downloadedFilesHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTextStyles.fontSize14,
                color: isDark ? AppColors.grey400 : AppColors.grey600,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Offline badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.success.withOpacity(0.2)
                  : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.offline_bolt,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  lang.worksOffline,
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard({
    required LocalFile file,
    required bool isDark,
    required ThemeData theme,
    required bool isSelectMode,
    required bool isSelected,
    required AppLocalizations lang,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark.withOpacity(isSelected ? 0.9 : 0.7)
            : AppColors.white.withOpacity(isSelected ? 1 : 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.grey700 : AppColors.grey200),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : AppColors.grey300.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isSelectMode) {
              context.read<DownloadedFilesBloc>().add(ToggleFileSelection(file.id));
            } else {
              _openFile(file, lang);
            }
          },
          onLongPress: () {
            if (!isSelectMode) {
              context.read<DownloadedFilesBloc>().add(ToggleSelectMode());
              context.read<DownloadedFilesBloc>().add(ToggleFileSelection(file.id));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox hoặc Icon
                if (isSelectMode)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) {
                        context.read<DownloadedFilesBloc>().add(ToggleFileSelection(file.id));
                      },
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  )
                else
                  // File type icon with gradient
                  Container(
                    width: 52,
                    height: 52,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      gradient: _getFileTypeGradient(file.type, isDark),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getFileTypeIcon(file.type),
                      color: AppColors.white,
                      size: 26,
                    ),
                  ),

                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          fontWeight: AppTextStyles.weightSemiBold,
                          fontSize: AppTextStyles.fontSize16,
                          color: isDark ? AppColors.white : AppColors.grey800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildInfoChip(
                            file.type.toUpperCase(),
                            isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            file.formattedSize,
                            isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(file.downloadedAt, lang),
                        style: TextStyle(
                          fontSize: AppTextStyles.fontSize12,
                          color: isDark ? AppColors.grey400 : AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action buttons
                if (!isSelectMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.share_rounded,
                          color: isDark ? AppColors.blue300 : AppColors.primary,
                        ),
                        onPressed: () => _shareFile(file, lang),
                        tooltip: lang.shareFile,
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: isDark ? AppColors.grey400 : AppColors.grey600,
                        ),
                        onSelected: (value) => _handleMenuAction(value, file, lang),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'open',
                            child: Row(
                              children: [
                                const Icon(Icons.open_in_new),
                                const SizedBox(width: 12),
                                Text(lang.openFile),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'preview',
                            child: Row(
                              children: [
                                const Icon(Icons.visibility),
                                const SizedBox(width: 12),
                                Text(lang.preview),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                const Icon(Icons.share),
                                const SizedBox(width: 12),
                                Text(lang.shareFile),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline, color: Colors.red),
                                const SizedBox(width: 12),
                                Text(lang.delete, style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.grey700.withOpacity(0.5)
            : AppColors.grey100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTextStyles.fontSize11,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.grey300 : AppColors.grey600,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //                         HELPERS
  // ════════════════════════════════════════════════════════════════

  LinearGradient _getFileTypeGradient(String type, bool isDark) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return LinearGradient(
          colors: isDark
              ? [Colors.red[700]!, Colors.red[900]!]
              : [Colors.red[400]!, Colors.red[600]!],
        );
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
        return LinearGradient(
          colors: isDark
              ? [Colors.green[700]!, Colors.teal[800]!]
              : [Colors.green[400]!, Colors.teal[500]!],
        );
      case 'word':
      case 'docx':
        return LinearGradient(
          colors: isDark
              ? [Colors.blue[700]!, Colors.blue[900]!]
              : [Colors.blue[400]!, Colors.blue[600]!],
        );
      case 'excel':
      case 'xlsx':
        return LinearGradient(
          colors: isDark
              ? [Colors.green[700]!, Colors.green[900]!]
              : [Colors.green[500]!, Colors.green[700]!],
        );
      default:
        return LinearGradient(
          colors: isDark
              ? [AppColors.grey700, AppColors.grey800]
              : [AppColors.grey400, AppColors.grey600],
        );
    }
  }

  IconData _getFileTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      case 'word':
      case 'docx':
        return Icons.description_rounded;
      case 'excel':
      case 'xlsx':
        return Icons.table_chart_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatDate(DateTime date, AppLocalizations lang) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return lang.justNow;
    } else if (diff.inHours < 1) {
      return lang.minutesAgo(diff.inMinutes);
    } else if (diff.inDays < 1) {
      return lang.hoursAgo(diff.inHours);
    } else if (diff.inDays < 7) {
      return lang.daysAgo(diff.inDays);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleMenuAction(String action, LocalFile file, AppLocalizations lang) {
    switch (action) {
      case 'open':
        _openFile(file, lang);
        break;
      case 'preview':
        _previewFile(file);
        break;
      case 'share':
        _shareFile(file, lang);
        break;
      case 'delete':
        _showDeleteSingleConfirmDialog(file, lang);
        break;
    }
  }

  Future<void> _openFile(LocalFile file, AppLocalizations lang) async {
    try {
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(lang.cannotOpenFileError(result.message)),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.openFileError(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _previewFile(LocalFile file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilePreviewScreen(
          filePath: file.path,
          fileName: file.name,
        ),
      ),
    );
  }

  Future<void> _shareFile(LocalFile file, AppLocalizations lang) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: lang.sharedFrom,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.shareError(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDeleteSingleConfirmDialog(LocalFile file, AppLocalizations lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Capture bloc reference before opening dialog
    final bloc = context.read<DownloadedFilesBloc>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 12),
            Text(lang.confirmDeleteTitle),
          ],
        ),
        content: Text(
          lang.confirmDeleteSingle(file.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(lang.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(DeleteFileRequested(file.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(lang.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(AppLocalizations lang) {
    final bloc = context.read<DownloadedFilesBloc>();
    final state = bloc.state;
    if (state is! DownloadedFilesLoaded) return;
    
    final selectedFileIds = state.selectedFileIds.toList();
    final selectedCount = selectedFileIds.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 12),
            Text(lang.confirmDeleteTitle),
          ],
        ),
        content: Text(
          lang.confirmDeleteMultiple(selectedCount),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(lang.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(DeleteMultipleFilesRequested(selectedFileIds));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(lang.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
