import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

import '../../blocs/downloaded_files_bloc.dart';
import '../../services/local_file_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_component_styles.dart';
import '../../l10n/app_localizations.dart';
import '../file_preview_screen.dart';
import '../../widgets/app_header.dart';

/// Màn hình hiển thị các file đã tải xuống
/// Hoạt động hoàn toàn OFFLINE
/// Updated: UI synced with Home Screen (Glassmorphism, colors, AppHeader)
class DownloadedFilesScreen extends StatefulWidget {
  const DownloadedFilesScreen({super.key});

  @override
  State<DownloadedFilesScreen> createState() => _DownloadedFilesScreenState();
}

class _DownloadedFilesScreenState extends State<DownloadedFilesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<DownloadedFilesBloc>().add(LoadDownloadedFilesRequested());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Kiểm tra nếu scroll gần cuối thì load thêm
  bool _onScrollNotification(ScrollNotification scrollInfo) {
    if (scrollInfo is ScrollEndNotification) {
      final metrics = scrollInfo.metrics;
      // Khi scroll còn cách cuối 200px thì load thêm
      if (metrics.pixels >= metrics.maxScrollExtent - 200) {
        final state = context.read<DownloadedFilesBloc>().state;
        if (state is DownloadedFilesLoaded && state.hasMore && !state.isLoadingMore) {
          context.read<DownloadedFilesBloc>().add(LoadMoreFilesRequested());
        }
      }
    }
    return false;
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
            decoration: AppStyles.homeBackground(isDark),
            child: Stack(
              children: [
                // Background Blobs (Decoration for Glass Effect)
                if (!isDark) ...[
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: AppStyles.homeBlob(Colors.blue.withOpacity(0.2)),
                    ),
                  ),
                  Positioned(
                    bottom: 100,
                    left: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: AppStyles.homeBlob(Colors.purple.withOpacity(0.15), blurRadius: 60),
                    ),
                  ),
                ],

                // Main Content
                RefreshIndicator(
                  onRefresh: () async {
                    context.read<DownloadedFilesBloc>().add(LoadDownloadedFilesRequested());
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  color: AppColors.primary,
                  backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScrollNotification,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        _buildAppBar(isDark, state, lang),
                        
                        // Summary info row
                        if (state is DownloadedFilesLoaded && !state.isSelectMode && state.files.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), // Adjusted padding
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.folder_open_rounded,
                                    size: 16,
                                    color: isDark ? Colors.white54 : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${state.files.length} files • ${state.totalSize}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white54 : Colors.grey[600],
                                    ),
                                  ),
                                  const Spacer(),
                                  InkWell(
                                    onTap: () {
                                      context.read<DownloadedFilesBloc>().add(ToggleSelectMode());
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Text(
                                        lang.selectMultiple,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        _buildBody(state, theme, isDark, lang),
                        
                        // Loading indicator
                        if (state is DownloadedFilesLoaded && state.isLoadingMore)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                          
                        // Bottom padding
                        const SliverToBoxAdapter(child: SizedBox(height: 80)),
                      ],
                    ),
                  ),
                ),
              ],
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

    return AppHeader(
      title: isSelectMode 
          ? lang.selectedFiles(selectedCount) 
          : lang.downloadedFiles,
      showLogo: !isSelectMode,
      showVipCrown: !isSelectMode, 
      showProfileButton: !isSelectMode,
      leading: isSelectMode 
          ? IconButton(
              icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87),
              onPressed: () {
                 context.read<DownloadedFilesBloc>().add(ToggleSelectMode());
              },
            )
          : null,
      actions: isSelectMode 
          ? [
              IconButton(
                icon: Icon(Icons.select_all, color: isDark ? Colors.white : Colors.black87),
                onPressed: () {
                  context.read<DownloadedFilesBloc>().add(SelectAllFiles());
                },
                tooltip: lang.selectAll,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: selectedCount > 0 ? () => _showDeleteConfirmDialog(lang) : null,
                tooltip: lang.delete,
              ),
            ]
          : null,
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
          // Icon styled like HistoryList empty state
          Container(
            width: 80,
            height: 80,
            decoration: AppComponentStyles.emptyStateIcon(isDark: isDark),
            child: Icon(
              Icons.folder_off_outlined,
              size: 32,
              color: isDark ? Colors.white54 : Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            lang.noFilesYet,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              lang.downloadedFilesHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.grey[500],
              ),
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
    // Determine colors
    final bool isPdf = file.type.toLowerCase().contains('pdf');
    final Color iconColor = isPdf
        ? (isDark ? const Color(0xFFF43F5E) : const Color(0xFFE11D48)) // Rose
        : (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)); // Blue

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: AppComponentStyles.fileCard(
              isDark: isDark,
              isSelected: isSelected,
              borderRadius: 20,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
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
                      // Checkbox for selection mode
                      if (isSelectMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Transform.scale(
                            scale: 1.2,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (_) {
                                context.read<DownloadedFilesBloc>().add(ToggleFileSelection(file.id));
                              },
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: BorderSide(
                                color: isDark ? Colors.white54 : Colors.grey[400]!,
                                width: 1.5,
                              ),
                            ),
                          ),
                        )
                      else
                        // Icon with Gradient Background
                        Container(
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: AppComponentStyles.iconGradientContainer(
                            gradientColors: [iconColor, iconColor],
                            borderRadius: 14,
                          ),
                          child: Icon(
                            isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                            color: iconColor,
                            size: 24,
                          ),
                        ),

                      // File Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _buildInfoChip(
                                  file.type.toUpperCase(),
                                  isDark,
                                  isPdf,
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.sd_storage_rounded,
                                  size: 12,
                                  color: isDark ? Colors.white38 : Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  file.formattedSize,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white38 : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: isDark ? Colors.white38 : Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _formatDate(file.downloadedAt, lang),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white38 : Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // More actions
                      if (!isSelectMode)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: isDark ? Colors.white38 : Colors.grey[500],
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: isDark ? AppColors.cardDark : AppColors.white,
                          elevation: 4,
                          onSelected: (value) => _handleMenuAction(value, file, lang),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'open',
                              child: Row(
                                children: [
                                  Icon(Icons.open_in_new, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 12),
                                  Text(lang.openFile),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'preview',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_outlined, color: AppColors.secondary, size: 20),
                                  const SizedBox(width: 12),
                                  Text(lang.preview),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(Icons.share_outlined, color: AppColors.success, size: 20),
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
                                  const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  const SizedBox(width: 12),
                                  Text(lang.delete, style: const TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, bool isDark, bool isPdf) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: AppComponentStyles.infoChip(
        isDark: isDark,
        isPdf: isPdf,
        borderRadius: 4,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isPdf
            ? (isDark ? Colors.red[200] : Colors.red[700])
            : (isDark ? Colors.blue[200] : Colors.blue[700]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //                         HELPERS
  // ════════════════════════════════════════════════════════════════

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
      return '${date.day}/${date.month}';
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
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: lang.sharedFrom,
      );
      if (result.status == ShareResultStatus.success) {
        // Success
      }
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
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
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
              foregroundColor: Colors.white,
            ),
            child: Text(lang.delete),
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
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(lang.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Send the list of IDs
              bloc.add(DeleteMultipleFilesRequested(selectedFileIds));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(lang.delete),
          ),
        ],
      ),
    );
  }
}
