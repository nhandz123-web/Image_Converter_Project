import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_view/photo_view.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

/// Màn hình xem trước file (PDF, ảnh) inline trong app
/// Hỗ trợ cả URL remote và local file path
class FilePreviewScreen extends StatefulWidget {
  final String? fileUrl;      // URL của file (để download)
  final String? filePath;     // Đường dẫn local file (đã có sẵn)
  final String fileName;
  final String? fileType;     // 'pdf', 'jpg', 'png', etc. (optional, auto-detect from extension)

  const FilePreviewScreen({
    Key? key,
    this.fileUrl,
    this.filePath,
    required this.fileName,
    this.fileType,
  }) : super(key: key);

  @override
  State<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends State<FilePreviewScreen> {
  bool isLoading = true;
  String? localFilePath;
  String? errorMessage;
  late String _fileType;

  // PDF specific
  int totalPages = 0;
  int currentPage = 0;
  PDFViewController? pdfController;

  @override
  void initState() {
    super.initState();
    // Auto-detect file type from extension if not provided
    _fileType = widget.fileType ?? _getExtensionFromName(widget.fileName);
    _loadFile();
  }

  /// Lấy extension từ tên file
  String _getExtensionFromName(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return 'unknown';
  }

  /// Tải file về cache để hiển thị
  Future<void> _loadFile() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Nếu đã có local file path, sử dụng trực tiếp
      if (widget.filePath != null) {
        final file = File(widget.filePath!);
        if (await file.exists()) {
          setState(() {
            localFilePath = widget.filePath;
            isLoading = false;
          });
          return;
        } else {
          throw Exception('File không tồn tại: ${widget.filePath}');
        }
      }

      // Nếu có URL, download về cache
      if (widget.fileUrl != null) {
        final tempDir = await getTemporaryDirectory();
        final filePath = "${tempDir.path}/${widget.fileName}";
        final file = File(filePath);

        // Kiểm tra file đã có trong cache chưa
        if (!file.existsSync()) {
          print("📥 Downloading file: ${widget.fileUrl}");
          await Dio().download(widget.fileUrl!, filePath);
          print("✅ File downloaded to: $filePath");
        } else {
          print("📂 File already in cache: $filePath");
        }

        setState(() {
          localFilePath = filePath;
          isLoading = false;
        });
      } else {
        throw Exception('Không có file URL hoặc file path');
      }
    } catch (e) {
      print("❌ Error loading file: $e");
      setState(() {
        errorMessage = "Không thể tải file: $e";
        isLoading = false;
      });
    }
  }

  /// Chia sẻ file
  Future<void> _shareFile() async {
    if (localFilePath == null) return;

    await Share.shareXFiles(
      [XFile(localFilePath!)],
      text: 'Chia sẻ: ${widget.fileName}',
    );
  }

  /// Mở file bằng app ngoài
  Future<void> _openExternally() async {
    if (localFilePath == null) return;
    await OpenFilex.open(localFilePath!);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[900],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.grey[900]!, Colors.grey[850]!]
                  : [Colors.grey[900]!, Colors.grey[800]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: AppDimensions.paddingH8,
              child: Row(
                children: [
                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  // Title
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppTextStyles.fontSize14,
                          fontWeight: AppTextStyles.weightMedium,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // Open externally button
                  IconButton(
                    icon: const Icon(Icons.open_in_new, color: AppColors.white),
                    onPressed: _openExternally,
                    tooltip: "Mở bằng app khác",
                  ),
                  // Share button
                  IconButton(
                    icon: const Icon(Icons.share, color: AppColors.white),
                    onPressed: _shareFile,
                    tooltip: "Chia sẻ",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
      // Thanh điều hướng trang cho PDF
      bottomNavigationBar: _isPdf() && totalPages > 1
          ? _buildPdfNavigation()
          : null,
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              "Đang tải file...",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadFile,
                icon: const Icon(Icons.refresh),
                label: const Text("Thử lại"),
              ),
            ],
          ),
        ),
      );
    }

    if (localFilePath == null) {
      return const Center(
        child: Text("Không có file", style: TextStyle(color: Colors.white70)),
      );
    }

    // Hiển thị theo loại file
    if (_isPdf()) {
      return _buildPdfViewer();
    } else if (_isImage()) {
      return _buildImageViewer();
    } else {
      return _buildUnsupportedView();
    }
  }

  /// Xem PDF inline
  Widget _buildPdfViewer() {
    return PDFView(
      filePath: localFilePath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      fitPolicy: FitPolicy.BOTH,
      preventLinkNavigation: false,
      onRender: (pages) {
        setState(() {
          totalPages = pages ?? 0;
        });
      },
      onViewCreated: (controller) {
        pdfController = controller;
      },
      onPageChanged: (page, total) {
        setState(() {
          currentPage = page ?? 0;
          totalPages = total ?? 0;
        });
      },
      onError: (error) {
        print("❌ PDF Error: $error");
        setState(() {
          errorMessage = "Lỗi hiển thị PDF: $error";
        });
      },
      onPageError: (page, error) {
        print("❌ PDF Page Error: $error");
      },
    );
  }

  /// Xem ảnh với zoom/pan
  Widget _buildImageViewer() {
    return PhotoView(
      imageProvider: FileImage(File(localFilePath!)),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 4,
      initialScale: PhotoViewComputedScale.contained,
      heroAttributes: PhotoViewHeroAttributes(tag: widget.fileName),
      loadingBuilder: (context, event) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorBuilder: (context, error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, color: Colors.grey, size: 64),
            const SizedBox(height: 16),
            const Text(
              "Không thể hiển thị ảnh",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  /// View cho file không hỗ trợ
  Widget _buildUnsupportedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, color: Colors.grey, size: 80),
          const SizedBox(height: 16),
          Text(
            widget.fileName,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Định dạng này không hỗ trợ xem trước",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openExternally,
            icon: const Icon(Icons.open_in_new),
            label: const Text("Mở bằng app khác"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Thanh điều hướng trang PDF
  Widget _buildPdfNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Nút trang trước
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: currentPage > 0
                  ? () => pdfController?.setPage(currentPage - 1)
                  : null,
            ),
            // Hiển thị số trang
            Text(
              "Trang ${currentPage + 1} / $totalPages",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            // Nút trang sau
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: currentPage < totalPages - 1
                  ? () => pdfController?.setPage(currentPage + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Kiểm tra có phải PDF không
  bool _isPdf() {
    return _fileType.toLowerCase() == 'pdf';
  }

  /// Kiểm tra có phải ảnh không
  bool _isImage() {
    final imageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
    return imageTypes.contains(_fileType.toLowerCase());
  }
}
