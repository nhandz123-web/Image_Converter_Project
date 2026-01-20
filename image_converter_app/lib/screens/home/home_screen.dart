import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../../blocs/home_bloc.dart';
import '../all_documents_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../edit_image/edit_image_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';

// ✅ Import các widget đã tách
import 'widgets/widgets.dart';
import '../../widgets/app_header.dart';
import '../../widgets/vip_crown_icon.dart';

/// Màn hình Home chính của ứng dụng
///
/// ĐÃ REFACTOR: Tách thành các widget con để dễ maintain
/// - WelcomeCard: Card chào mừng
/// - ToolGrid: Grid các công cụ
/// - HistoryList: Danh sách lịch sử
/// - MergePdfDialog: Dialog gộp PDF
/// - ImageSourceModal: Modal chọn nguồn ảnh
/// - FileNameDialog: Dialog đặt tên file
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Image picker
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // ✅ REMOVED: Không cần load ở đây vì HomeBloc đã tự load trong main.dart
    // context.read<HomeBloc>().add(LoadHistoryRequested());
  }

  // ════════════════════════════════════════════════════════════════
  //                         BUILD METHOD
  // ════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = AppLocalizations.of(context)!;

    return BlocConsumer<HomeBloc, HomeState>(
      listener: _handleBlocListener,
      builder: (context, state) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppColors.backgroundGradientDark
                  : AppColors.backgroundGradientLight,
            ),
            child: Stack(
              children: [
                // Main content
                RefreshIndicator(
                  onRefresh: () async {
                    context.read<HomeBloc>().add(LoadHistoryRequested(forceRefresh: true));
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      AppHeader(
                        title: lang.appName,
                        isVip: true, // TODO: Lấy từ AuthBloc/User state
                        vipInfo: const VipInfo(
                          planName: 'Premium',
                          expiryDate: '25/02/2026',
                          daysRemaining: 37,
                          benefits: [
                            'Chuyển đổi không giới hạn',
                            'Không quảng cáo',
                            'Dung lượng lưu trữ 50GB',
                            'Hỗ trợ ưu tiên 24/7',
                            'Tính năng nâng cao',
                          ],
                        ),
                        onUpgradePressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tính năng mua VIP đang phát triển'),
                              backgroundColor: AppColors.info,
                            ),
                          );
                        },
                      ),
                      _buildBody(state, theme, isDark, lang),
                    ],
                  ),
                ),

                // Loading overlay
                if (state is HomeLoading)
                  LoadingOverlay(theme: theme),
              ],
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  //                         BODY
  // ════════════════════════════════════════════════════════════════

  Widget _buildBody(HomeState state, ThemeData theme, bool isDark, AppLocalizations lang) {
    return SliverPadding(
      padding: AppDimensions.paddingAll16,
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Welcome Card
          WelcomeCard(isDark: isDark),
          const SizedBox(height: AppDimensions.spacing24),

          // Popular Tools Section
          SectionTitle(theme: theme, title: lang.popularTools ?? "Công cụ phổ biến"),
          const SizedBox(height: AppDimensions.spacing16),
          ToolGrid(
            theme: theme,
            onToolSelected: (toolId) => _handleToolSelected(toolId, lang, theme),
          ),
          const SizedBox(height: AppDimensions.spacing24),

          // Recent Documents Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionTitle(theme: theme, title: lang.recentDocuments ?? "Tài liệu gần đây"),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AllDocumentsScreen()),
                ),
                child: Text(lang.viewAll ?? "Xem tất cả"),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),

          // History List
          HistoryList(state: state, theme: theme, maxItems: 5),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //                         EVENT HANDLERS
  // ════════════════════════════════════════════════════════════════

  void _handleBlocListener(BuildContext context, HomeState state) {
    final lang = AppLocalizations.of(context)!;

    if (state is HomeSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.success,
        ),
      );
      context.read<HomeBloc>().add(LoadHistoryRequested(forceRefresh: true));
    }

    if (state is HomeFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleToolSelected(String toolId, AppLocalizations lang, ThemeData theme) {
    switch (toolId) {
      case 'img_to_pdf':
        ImageSourceModal.show(
          context: context,
          onCameraSelected: _pickFromCamera,
          onGallerySelected: _pickFromGallery,
        );
        break;

      case 'merge_pdf':
        MergePdfDialog.show(context);
        break;

      case 'word_to_pdf':
      case 'excel_to_pdf':
      case 'qr_scan':
      case 'compress':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Tính năng đang phát triển"),
            backgroundColor: Colors.blue,
          ),
        );
        break;
    }
  }

  // ════════════════════════════════════════════════════════════════
  //                         IMAGE PICKING
  // ════════════════════════════════════════════════════════════════

  Future<void> _pickFromCamera() async {
    final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (photo != null) {
      _goToEditScreen([File(photo.path)]);
    }
  }

  Future<void> _pickFromGallery() async {
    final images = await _picker.pickMultiImage(imageQuality: 90);
    if (images.isNotEmpty) {
      _goToEditScreen(images.map((e) => File(e.path)).toList());
    }
  }

  void _goToEditScreen(List<File> images) async {
    final editedFiles = await Navigator.push<List<File>>(
      context,
      MaterialPageRoute(builder: (_) => EditImageScreen(images: images)),
    );

    if (editedFiles != null && editedFiles.isNotEmpty && mounted) {
      final fileName = await FileNameDialog.show(context);

      if (mounted) {
        context.read<HomeBloc>().add(
          UploadEditedImagesEvent(editedFiles, outputName: fileName),
        );
      }
    }
  }
}
