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
  // ✅ Sử dụng ApiConfig thay vì hardcode IP
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

  /// ✅ SỬA: Dùng API route thay vì storage/ symlink
  String _getFullUrl(String? path) {
    if (path == null || path.isEmpty) return "";

    // 1. Nếu đã là link đầy đủ (có http) thì trả về luôn
    if (path.startsWith('http')) return path;

    // 2. Xử lý path sạch (bỏ dấu / ở đầu nếu có)
    String cleanPath = path.startsWith('/') ? path.substring(1) : path;

    // 3. Logic ghép đường dẫn chuẩn Laravel Storage
    // Nếu path chưa có chữ 'storage', thì thêm vào.
    // Ví dụ DB lưu: "convert/converted/file.pdf"
    // Link đúng phải là: "http://10.85.33.12:8000/storage/convert/converted/file.pdf"

    if (!cleanPath.startsWith('storage/')) {
      return "${baseUrl}storage/$cleanPath";
    }

    return "$baseUrl$cleanPath";
  }

  // --- HÀM TẢI FILE VÀO THƯ MỤC RIÊNG CỦA APP ---
  Future<void> _downloadAndOpenFile(String url, String fileName, AppLocalizations lang) async {
    setState(() => isDownloading = true);

    try {
      // --- BẮT ĐẦU: LOGIC KIỂM TRA QUYỀN MỚI ---
      bool hasPermission = false;

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        // Nếu là Android 13 (SDK 33) trở lên: KHÔNG CẦN xin quyền ghi file vào thư mục Download
        if (androidInfo.version.sdkInt >= 33) {
          hasPermission = true;
        } else {
          // Nếu là Android 12 trở xuống: Phải xin quyền Storage
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
          hasPermission = status.isGranted;
        }
      } else {
        // iOS thì mặc định OK (lưu vào Documents của App)
        hasPermission = true;
      }
      // --- KẾT THÚC: LOGIC KIỂM TRA QUYỀN ---

      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bạn cần cấp quyền bộ nhớ để tải file"), backgroundColor: Colors.orange),
        );
        setState(() => isDownloading = false);
        // Mở cài đặt để user cấp quyền thủ công nếu họ lỡ từ chối vĩnh viễn
        openAppSettings();
        return;
      }

      // --- TIẾN HÀNH TẢI FILE VÀO THƯ MỤC RIÊNG CỦA APP ---
      // Tạo thư mục riêng cho app thay vì lưu vào Downloads công khai
      const String appFolderName = 'SnapPDF_Files';
      Directory appDir;

      if (Platform.isAndroid) {
        // Lưu vào thư mục Documents của app (an toàn hơn)
        appDir = await getApplicationDocumentsDirectory();
      } else {
        appDir = await getApplicationDocumentsDirectory();
      }

      // Tạo thư mục con cho app
      final appFilesDir = Directory('${appDir.path}/$appFolderName');
      if (!await appFilesDir.exists()) {
        await appFilesDir.create(recursive: true);
      }

      String savePath = '${appFilesDir.path}/$fileName';

      // Xử lý trùng tên file (tự động thêm số đếm)
      int count = 1;
      String finalPath = savePath;
      while (File(finalPath).existsSync()) {
        final nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));
        final ext = fileName.substring(fileName.lastIndexOf('.'));
        finalPath = '${appFilesDir.path}/$nameWithoutExt ($count)$ext';
        count++;
      }

      // ✅ Debug: In ra URL để kiểm tra
      print("📥 Downloading from URL: $url");
      print("💾 Saving to: $finalPath");

      await Dio().download(url, finalPath);

      // ✅ MỚI: Lưu file vào LocalFileService để hiển thị trong tab "File đã tải"
      final localFileService = LocalFileService();
      final fileType = fileName.contains('.')
          ? fileName.split('.').last.toLowerCase()
          : 'unknown';
      final savedFile = await localFileService.addExistingFile(
        filePath: finalPath,
        fileName: fileName,
        fileType: fileType,
        originalName: widget.document['name']?.toString(),
      );

      if (savedFile != null) {
        print("✅ File đã được lưu vào danh sách Downloaded Files: ${savedFile.name}");
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã lưu vào: SnapPDF_Files/${finalPath.split('/').last}"),
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
      print("❌ Lỗi tải: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tải file: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
  }

  // --- HÀM CHIA SẺ ---
  Future<void> _shareFile(String url, String fileName) async {
    setState(() => isDownloading = true);
    try {
      // Lưu vào thư mục cache (tạm thời) để chia sẻ
      final tempDir = await getTemporaryDirectory();
      final tempPath = "${tempDir.path}/$fileName";

      print("📤 Sharing file from URL: $url");
      await Dio().download(url, tempPath);

      if (!mounted) return;
      // Dùng Share.shareXFiles (bản mới nhất của share_plus)
      final result = await Share.shareXFiles(
          [XFile(tempPath)],
          text: 'Chia sẻ tài liệu từ Image Converter'
      );

      if (result.status == ShareResultStatus.success) {
        print("✅ Đã chia sẻ thành công");
      }
    } catch (e) {
      print("❌ Lỗi khi chia sẻ: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi chia sẻ"), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
  }

  // --- HÀM XEM TRƯỚC FILE (INLINE TRONG APP) ---
  void _previewFile(String url, String fileName, AppLocalizations lang) {
    // Lấy file type từ extension
    String fileType = 'pdf';
    if (fileName.contains('.')) {
      fileType = fileName.split('.').last.toLowerCase();
    }

    // Mở màn hình preview inline
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilePreviewScreen(
          fileUrl: url,
          fileName: fileName,
          fileType: fileType,
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String currentName, AppLocalizations lang) {
    TextEditingController _nameController = TextEditingController(text: currentName);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadius20),
        backgroundColor: isDark ? AppColors.grey900 : AppColors.white,
        title: Row(
          children: [
            Icon(Icons.edit_rounded, color: theme.primaryColor),
            const SizedBox(width: AppDimensions.spacing10),
            Text(
              lang.renameFile ?? "Đổi tên file",
              style: TextStyle(color: isDark ? AppColors.white : AppColors.black87),
            ),
          ],
        ),
        content: TextField(
          controller: _nameController,
          style: TextStyle(color: isDark ? AppColors.white : AppColors.black87),
          decoration: InputDecoration(
            labelText: lang.newName ?? "Tên mới",
            labelStyle: TextStyle(color: AppTheme.getSecondaryTextColor(isDark)),
            prefixIcon: Icon(Icons.description_rounded, color: AppTheme.getSecondaryTextColor(isDark)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              lang.cancel ?? "Hủy",
              style: TextStyle(color: AppTheme.getSecondaryTextColor(isDark)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                context.read<HomeBloc>().add(
                    RenameDocumentRequested(widget.document['id'], _nameController.text)
                );
                setState(() {
                  widget.document['name'] = _nameController.text;
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadius10),
            ),
            child: Text(lang.save ?? "Lưu"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, AppLocalizations lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadius20),
        backgroundColor: isDark ? AppColors.grey900 : AppColors.white,
        title: Text(lang.confirmDelete ?? "Xóa file?", style: TextStyle(color: isDark ? AppColors.white : AppColors.black)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              context.read<HomeBloc>().add(DeleteDocumentRequested(widget.document['id']));
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
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

    // ✅ CRITICAL FIX: Safe DateTime parsing với try-catch
    String formattedDate;
    try {
      final createdAt = document['created_at'];
      if (createdAt == null || createdAt.toString().isEmpty) {
        formattedDate = 'Không xác định';
      } else {
        final date = DateTime.parse(createdAt.toString());
        formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
      }
    } catch (e) {
      formattedDate = 'Không xác định';
      print('⚠️ Lỗi parse DateTime: $e');
    }

    final int sizeBytes = document['size'] ?? 0;
    String sizeStr = sizeBytes > 1024 * 1024
        ? "${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB"
        : "${(sizeBytes / 1024).toStringAsFixed(2)} KB";

    final pdfUrl = _getFullUrl(document['path']);

    return Scaffold(
      backgroundColor: isDark ? AppColors.grey900 : AppColors.grey50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: theme.primaryColor,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.delete_rounded, color: Colors.white),
                  onPressed: () => _showDeleteConfirm(context, lang),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.getPrimaryGradient(isDark),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 40),
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 15),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            // SỬA LỖI: Đổi 'original_name' thành 'name' và thêm giá trị mặc định
                            document['name']?.toString() ?? "Không có tên file",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(50),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: theme.primaryColor,
                    indicatorWeight: 3,
                    labelColor: isDark ? Colors.white : theme.primaryColor,
                    unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
                    tabs: [
                      Tab(
                        icon: Icon(Icons.picture_as_pdf_rounded),
                        text: lang.pdfResult ?? "Kết quả PDF",
                      ),
                      Tab(
                        icon: Icon(Icons.image_rounded),
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
            _buildPdfTab(context, document, sizeStr, formattedDate, pdfUrl, lang, theme, isDark),
            _buildImageTab(document, lang, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfTab(
      BuildContext context,
      Map<String, dynamic> document,
      String sizeStr,
      String formattedDate,
      String pdfUrl,
      AppLocalizations lang,
      ThemeData theme,
      bool isDark,
      ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.picture_as_pdf_rounded, size: 80, color: Colors.red),
                SizedBox(height: 15),
                Text(
                  lang.pdfReady ?? "File PDF đã sẵn sàng",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  lang.tapDownloadToView ?? "Nhấn nút bên dưới để tải về",
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 25),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.description_rounded, color: Colors.blue, size: 24),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.fileName ?? "Tên file",
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              document['name']?.toString() ?? "Không có tên file",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_rounded, color: Colors.blue),
                        onPressed: () => _showRenameDialog(
                          context,
                          document['name']?.toString() ?? '',
                          lang,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                _buildModernInfoRow(Icons.sd_storage_rounded, lang.fileSize ?? "Dung lượng", sizeStr, Colors.orange),
                Divider(height: 1, indent: 70, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                _buildModernInfoRow(Icons.calendar_today_rounded, lang.createdDate ?? "Ngày tạo", formattedDate, Colors.green),
                Divider(height: 1, indent: 70, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                _buildModernInfoRow(Icons.check_circle_rounded, lang.status ?? "Trạng thái", (document['status'] ?? 'completed') == 'completed' ? (lang.completed ?? 'Hoàn thành') : (lang.processing ?? 'Đang xử lý'), (document['status'] ?? 'completed') == 'completed' ? Colors.green : Colors.orange),
              ],
            ),
          ),
          SizedBox(height: 25),

          // --- NÚT DOWNLOAD VÀ NÚT SHARE ---
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Nút Download
                Expanded(
                  flex: 4,
                  child: _buildModernDownloadButton(pdfUrl, document['name']?.toString() ?? "Không có tên file", lang, theme),
                ),
                SizedBox(width: 10),
                // Nút Xem trước (inline trong app)
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () => _previewFile(pdfUrl, document['name']?.toString() ?? "file.pdf", lang),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Icon(Icons.visibility_rounded, size: 24),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                // Nút Share
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 58,
                    child: ElevatedButton(
                      onPressed: isDownloading ? null : () => _shareFile(pdfUrl, document['name']?.toString() ?? "Không có tên file"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                        foregroundColor: theme.primaryColor,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: theme.primaryColor.withOpacity(0.5)),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: isDownloading
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.share_rounded, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDownloadButton(
      String url,
      String fileName,
      AppLocalizations lang,
      ThemeData theme,
      ) {
    return ElevatedButton(
      onPressed: isDownloading ? null : () => _downloadAndOpenFile(url, fileName, lang),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: theme.primaryColor.withOpacity(0.5),
        padding: EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isDownloading)
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          else
            Icon(Icons.download_rounded, size: 24),
          SizedBox(width: 12),
          Text(
            isDownloading ? (lang.downloading ?? "...") : (lang.downloadAndOpen ?? "Tải về"),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// ✅ HÀM BUILD IMAGE TAB - Hiển thị TẤT CẢ ảnh gốc từ storage
  Widget _buildImageTab(Map<String, dynamic> document, AppLocalizations lang, bool isDark) {
    // 1. Tạo list ảnh để hiển thị
    List<String> imagePaths = [];

    // 2. Ưu tiên lấy từ source_images_paths (array chứa TẤT CẢ ảnh gốc)
    var sourceImagesPaths = document['source_images_paths'];
    if (sourceImagesPaths != null && sourceImagesPaths is List && sourceImagesPaths.isNotEmpty) {
      for (var path in sourceImagesPaths) {
        if (path != null && path.toString().isNotEmpty) {
          imagePaths.add(path.toString());
        }
      }
      print("📷 Source Images Paths: $imagePaths");
    }

    // 3. Fallback: Nếu không có source_images_paths, thử lấy input_path (ảnh đầu tiên)
    if (imagePaths.isEmpty) {
      var inputPath = document['input_path'];
      if (inputPath != null && inputPath.toString().isNotEmpty) {
        imagePaths.add(inputPath.toString());
        print("📷 Fallback to Input Path: $inputPath");
      }
    }

    // 4. Fallback cuối: Nếu file hiện tại là ảnh, hiển thị chính nó
    if (imagePaths.isEmpty &&
        (document['type'] == 'jpg' || document['type'] == 'png' || document['type'] == 'jpeg')) {
      var path = document['path'];
      if (path != null && path.toString().isNotEmpty) {
        imagePaths.add(path.toString());
        print("📷 Fallback to current file path: $path");
      }
    }

    // 5. Nếu list rỗng -> Hiện thông báo
    if (imagePaths.isEmpty) {
      return _buildEmptyState(
          Icons.image_not_supported_rounded,
          lang.noOriginalImage ?? "Không tìm thấy ảnh gốc"
      );
    }

    // 6. Hiển thị danh sách ảnh
    return Container(
      color: isDark ? Colors.black : Colors.grey[900],
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: imagePaths.length,
        separatorBuilder: (_, __) => const SizedBox(height: 25),
        itemBuilder: (context, index) {
          // Hàm này sẽ tự thêm "http://IP/storage/..." vào trước
          final imgUrl = _getFullUrl(imagePaths[index]);
          print("🖼️ Loading URL: $imgUrl");

          return Column(
            children: [
              // Header đếm số trang (nếu có nhiều ảnh)
              if (imagePaths.length > 1)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)
                  ),
                  child: Text(
                      "${lang.image ?? "Ảnh"} ${index + 1} / ${imagePaths.length}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                ),

              // Khung hiển thị ảnh với Lazy Loading + Caching
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  height: 400, // Đặt chiều cao cố định để không bị lỗi layout
                  decoration: BoxDecoration(
                    color: Colors.black, // Nền đen cho ảnh nổi bật
                    boxShadow: [
                      BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5)),
                    ],
                  ),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    // ✅ Sử dụng CachedImageWidget thay vì Image.network
                    child: CachedImageWidget(
                      imageUrl: imgUrl,
                      height: 400,
                      fit: BoxFit.contain, // Đảm bảo ảnh hiển thị trọn vẹn
                      showProgressIndicator: true,
                      fadeInDuration: const Duration(milliseconds: 300),
                      placeholderColor: Colors.black,
                      errorWidget: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_rounded, color: Colors.grey, size: 50),
                            const SizedBox(height: 8),
                            Text("Lỗi tải ảnh", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: isDark ? Colors.grey[600] : Colors.grey[400]),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
