import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../blocs/home_bloc.dart';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'file_preview_screen.dart'; // Màn hình xem trước file inline
import '../widgets/cached_image_widget.dart'; // Lazy loading images
import '../config/api_config.dart'; // ✅ Import ApiConfig
import '../services/local_file_service.dart'; // ✅ Import LocalFileService để lưu file đã tải
import 'dart:ui'; // For Glassmorphism

class FileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> document;

  const FileDetailScreen({Key? key, required this.document}) : super(key: key);

  @override
  State<FileDetailScreen> createState() => _FileDetailScreenState();
}

class _FileDetailScreenState extends State<FileDetailScreen> with SingleTickerProviderStateMixin {
  bool isDownloading = false;
  bool isPreviewing = false;
  late TabController _tabController;
  final String baseUrl = '${ApiConfig.baseUrl}/';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getFullUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    String cleanPath = path.startsWith('/') ? path.substring(1) : path;
    if (!cleanPath.startsWith('storage/')) {
      return "${baseUrl}storage/$cleanPath";
    }
    return "$baseUrl$cleanPath";
  }

  Future<void> _downloadAndOpenFile(String url, String fileName,
      AppLocalizations lang) async {
    setState(() => isDownloading = true);
    try {
      bool hasPermission = false;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          hasPermission = true;
        } else {
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
          hasPermission = status.isGranted;
        }
      } else {
        hasPermission = true;
      }

      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bạn cần cấp quyền bộ nhớ để tải file"),
              backgroundColor: Colors.orange),
        );
        setState(() => isDownloading = false);
        openAppSettings();
        return;
      }

      const String appFolderName = 'SnapPDF_Files';
      Directory appDir = await getApplicationDocumentsDirectory();
      final appFilesDir = Directory('${appDir.path}/$appFolderName');
      if (!await appFilesDir.exists()) {
        await appFilesDir.create(recursive: true);
      }

      String savePath = '${appFilesDir.path}/$fileName';
      int count = 1;
      String finalPath = savePath;
      while (File(finalPath).existsSync()) {
        final nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));
        final ext = fileName.substring(fileName.lastIndexOf('.'));
        finalPath = '${appFilesDir.path}/$nameWithoutExt ($count)$ext';
        count++;
      }

      await Dio().download(url, finalPath);

      final localFileService = LocalFileService();
      final fileType = fileName.contains('.') ? fileName
          .split('.')
          .last
          .toLowerCase() : 'unknown';
      await localFileService.addExistingFile(
        filePath: finalPath,
        fileName: fileName,
        fileType: fileType,
        originalName: widget.document['name']?.toString(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã lưu vào: SnapPDF_Files/${finalPath
              .split('/')
              .last}"),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: "MỞ NGAY",
            textColor: AppColors.white,
            onPressed: () => OpenFilex.open(finalPath),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Lỗi tải file: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
  }

  Future<void> _shareFile(String url, String fileName) async {
    setState(() => isDownloading = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = "${tempDir.path}/$fileName";
      await Dio().download(url, tempPath);

      if (!mounted) return;
      await Share.shareXFiles(
          [XFile(tempPath)], text: 'Chia sẻ tài liệu từ Image Converter');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Lỗi khi chia sẻ"), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
  }

  void _previewFile(String url, String fileName, AppLocalizations lang) {
    String fileType = 'pdf';
    if (fileName.contains('.')) {
      fileType = fileName
          .split('.')
          .last
          .toLowerCase();
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FilePreviewScreen(
              fileUrl: url,
              fileName: fileName,
              fileType: fileType,
            ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String currentName,
      AppLocalizations lang) {
    TextEditingController _nameController = TextEditingController(
        text: currentName);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            title: Row(
              children: [
                Icon(Icons.edit_rounded, color: theme.primaryColor),
                const SizedBox(width: 10),
                Text(lang.renameFile ?? "Đổi tên file", style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
            content: TextField(
              controller: _nameController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: lang.newName ?? "Tên mới",
                labelStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey),
                prefixIcon: Icon(Icons.description_rounded,
                    color: isDark ? Colors.white54 : Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey)),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(lang.cancel ?? "Hủy", style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty) {
                    context.read<HomeBloc>().add(RenameDocumentRequested(
                        widget.document['id'], _nameController.text));
                    setState(() {
                      widget.document['name'] = _nameController.text;
                    });
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(lang.save ?? "Lưu"),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirm(BuildContext context, AppLocalizations lang) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            title: Text(lang.confirmDelete ?? "Xóa file?", style: TextStyle(
                color: isDark ? Colors.white : Colors.black87)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                  child: Text("Hủy", style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey))),
              ElevatedButton(
                onPressed: () {
                  context.read<HomeBloc>().add(
                      DeleteDocumentRequested(widget.document['id']));
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444), // Red 500
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Xóa"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final document = widget.document;

    String formattedDate;
    try {
      final createdAt = document['created_at'];
      if (createdAt == null || createdAt
          .toString()
          .isEmpty) {
        formattedDate = 'Không xác định';
      } else {
        final date = DateTime.parse(createdAt.toString());
        formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
      }
    } catch (e) {
      formattedDate = 'Không xác định';
    }

    final int sizeBytes = document['size'] ?? 0;
    String sizeStr = sizeBytes > 1024 * 1024
        ? "${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB"
        : "${(sizeBytes / 1024).toStringAsFixed(2)} KB";

    final pdfUrl = _getFullUrl(document['path']);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B)
            ], // Slate 900, Slate 800
          )
              : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF1F5F9),
              Color(0xFFE2E8F0)
            ], // Slate 100, Slate 200 for cleaner light mode
          ),
        ),
        child: Stack(
          children: [
            // Background Blobs
            if (!isDark) ...[
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3B82F6).withOpacity(0.1), // Blue 500
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.15),
                        blurRadius: 80,
                        spreadRadius: 20,
                      )
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                left: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFA855F7).withOpacity(0.05),
                    // Purple 500
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA855F7).withOpacity(0.1),
                        blurRadius: 60,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                ),
              ),
            ],

            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 220,
                    // Tăng height để thoáng hơn
                    floating: false,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    // Trong suốt để thấy nền
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withOpacity(0.2) : Colors
                            .white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white
                            .withOpacity(0.05) : const Color(0xFFE2E8F0),
                            width: 1),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: isDark ? Colors.white : const Color(
                                0xFF0F172A), size: 20), // Slate 900
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withOpacity(0.2) : Colors
                              .white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white
                              .withOpacity(0.05) : const Color(0xFFE2E8F0),
                              width: 1),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete_rounded, color: Color(
                              0xFFEF4444), size: 22), // Red 500
                          onPressed: () => _showDeleteConfirm(context, lang),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.transparent : Colors
                                  .transparent,
                            ),
                            child: SafeArea(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withOpacity(
                                          0.05) : Colors.white.withOpacity(0.4),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? Colors.white
                                            .withOpacity(0.1) : Colors.white
                                            .withOpacity(0.6),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isDark ? Colors.black
                                              .withOpacity(0.2) : Colors.blue
                                              .withOpacity(0.1),
                                          blurRadius: 20,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.picture_as_pdf_rounded,
                                      size: 48,
                                      color: isDark
                                          ? const Color(0xFFF43F5E)
                                          : const Color(0xFFE11D48),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24),
                                    child: Text(
                                      document['name']?.toString() ??
                                          "Không có tên file",
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(60),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withOpacity(0.2) : Colors
                              .white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : Colors
                                .white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              if (!isDark)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          indicatorPadding: const EdgeInsets.all(4),
                          labelColor: isDark ? Colors.white : const Color(
                              0xFF0F172A),
                          unselectedLabelColor: isDark
                              ? Colors.white54
                              : const Color(0xFF64748B),
                          labelStyle: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                          tabs: [
                            Tab(
                              icon: const Icon(
                                  Icons.picture_as_pdf_rounded, size: 20),
                              text: lang.pdfResult ?? "Kết quả PDF",
                            ),
                            Tab(
                              icon: const Icon(Icons.image_rounded, size: 20),
                              text: lang.originalImage ?? "Ảnh gốc",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildPdfTab(
                      context,
                      document,
                      sizeStr,
                      formattedDate,
                      pdfUrl,
                      lang,
                      theme,
                      isDark),
                  _buildImageTab(document, lang, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    required bool isDark,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors
                  .white.withOpacity(0.8), // Updated opacity
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : const Color(
                    0xFFE2E8F0).withOpacity(0.5), // Slate 200
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.2) : const Color(
                      0xFF64748B).withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildPdfTab(BuildContext context,
      Map<String, dynamic> document,
      String sizeStr,
      String formattedDate,
      String pdfUrl,
      AppLocalizations lang,
      ThemeData theme,
      bool isDark,) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Status Card
            _buildGlassCard(
              isDark: isDark,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFFF43F5E).withOpacity(0.1)
                          : const Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                        Icons.check_circle_rounded,
                        size: 40,
                        color: isDark ? const Color(0xFFF43F5E) : const Color(
                            0xFFE11D48)
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lang.pdfReady ?? "File PDF đã sẵn sàng",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(
                          0xFF0F172A), // Slate 900
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lang.tapDownloadToView ??
                        "Bạn có thể tải về hoặc xem trước ngay",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      // Slate 500
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // File Info Card
            _buildGlassCard(
              isDark: isDark,
              child: Column(
                children: [
                  _buildModernInfoRow(
                    Icons.description_rounded,
                    lang.fileName ?? "Tên file",
                    document['name']?.toString() ?? "file.pdf",
                    isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                    // Blue 400 / 600
                    isDark,
                    isEdit: true,
                    onEdit: () =>
                        _showRenameDialog(
                            context, document['name']?.toString() ?? '', lang),
                  ),
                  Divider(height: 1,
                      indent: 60,
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  _buildModernInfoRow(
                    Icons.sd_storage_rounded,
                    lang.fileSize ?? "Dung lượng",
                    sizeStr,
                    isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                    // Amber 400 / 600
                    isDark,
                  ),
                  Divider(height: 1,
                      indent: 60,
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  _buildModernInfoRow(
                    Icons.calendar_today_rounded,
                    lang.createdDate ?? "Ngày tạo",
                    formattedDate,
                    isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                    // Green 400 / 600
                    isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isDownloading ? null : () =>
                        _downloadAndOpenFile(
                            pdfUrl, document['name']?.toString() ?? "file.pdf",
                            lang),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: theme.primaryColor.withOpacity(0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isDownloading)
                          const SizedBox(width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2,
                                  color: Colors.white))
                        else
                          const Icon(Icons.download_rounded, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          isDownloading ? (lang.downloading ?? "...") : (lang
                              .download ?? "Tải về"),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _previewFile(
                            pdfUrl, document['name']?.toString() ?? "file.pdf",
                            lang),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white,
                      foregroundColor: isDark ? Colors.white : theme
                          .primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isDark ? BorderSide.none : BorderSide(color: theme
                            .primaryColor.withOpacity(0.2)),
                      ),
                      elevation: 0,
                    ),
                    child: const Icon(Icons.visibility_rounded, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isDownloading ? null : () =>
                        _shareFile(
                            pdfUrl, document['name']?.toString() ?? "file.pdf"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white,
                      foregroundColor: isDark ? Colors.white : theme
                          .primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isDark ? BorderSide.none : BorderSide(color: theme
                            .primaryColor.withOpacity(0.2)),
                      ),
                      elevation: 0,
                    ),
                    child: const Icon(Icons.share_rounded, size: 22),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value,
      Color color, bool isDark, {bool isEdit = false, VoidCallback? onEdit}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    // Slate 500
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(
                        0xFF0F172A), // Slate 900
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isEdit)
            IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit_rounded,
                  color: isDark ? Colors.white38 : Colors.grey[400], size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
              message, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildImageTab(Map<String, dynamic> document, AppLocalizations lang,
      bool isDark) {
    List<String> imagePaths = [];
    var sourceImagesPaths = document['source_images_paths'];
    if (sourceImagesPaths != null && sourceImagesPaths is List &&
        sourceImagesPaths.isNotEmpty) {
      for (var path in sourceImagesPaths) {
        if (path != null && path
            .toString()
            .isNotEmpty) {
          imagePaths.add(path.toString());
        }
      }
    }

    if (imagePaths.isEmpty) {
      var inputPath = document['input_path'];
      if (inputPath != null && inputPath
          .toString()
          .isNotEmpty) {
        imagePaths.add(inputPath.toString());
      }
    }

    if (imagePaths.isEmpty &&
        (document['type'] == 'jpg' || document['type'] == 'png' ||
            document['type'] == 'jpeg')) {
      var path = document['path'];
      if (path != null && path
          .toString()
          .isNotEmpty) {
        imagePaths.add(path.toString());
      }
    }

    if (imagePaths.isEmpty) {
      return _buildEmptyState(
          Icons.image_not_supported_rounded,
          lang.noOriginalImage ?? "Không tìm thấy ảnh gốc"
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: imagePaths.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final imgUrl = _getFullUrl(imagePaths[index]);
        return _buildGlassCard(
          isDark: isDark,
          child: Column(
            children: [
              if (imagePaths.length > 1)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors
                              .black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Trang ${index + 1}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              CachedImageWidget(
                imageUrl: imgUrl,
                width: double.infinity,
                height: 300,
                fit: BoxFit.contain,

              ),
            ],
          ),
        );
      },
    );
  }
}
