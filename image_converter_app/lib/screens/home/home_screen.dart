import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../../blocs/auth_bloc.dart';
import '../../blocs/home_bloc.dart';
import '../login_screen.dart';
import '../all_documents_screen.dart';
import '../profile_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../edit_image/edit_image_screen.dart'; // ✅ Import từ thư mục mới
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

// ✅ Import các widget đã tách
import 'widgets/widgets.dart';

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
    context.read<HomeBloc>().add(LoadHistoryRequested());
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
                      _buildAppBar(isDark, lang),
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
  //                         APP BAR
  // ════════════════════════════════════════════════════════════════

  Widget _buildAppBar(bool isDark, AppLocalizations lang) {
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
                // Logo
                Container(
                  padding: AppDimensions.paddingAll8,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(AppColors.opacity20),
                    borderRadius: AppDimensions.borderRadius12,
                  ),
                  child: const Icon(
                    Icons.flash_on_rounded,
                    color: AppColors.white,
                    size: AppDimensions.iconSizeRegular,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),

                // Title
                Expanded(
                  child: Text(
                    lang.appName,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: AppTextStyles.weightBold,
                      fontSize: AppTextStyles.fontSize22,
                    ),
                  ),
                ),

                // Profile button
                IconButton(
                  icon: const Icon(Icons.person_rounded, color: AppColors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfileScreen()),
                  ),
                ),
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
