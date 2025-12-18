import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../blocs/home_bloc.dart';
import 'dart:convert';

class FileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> document;

  const FileDetailScreen({Key? key, required this.document}) : super(key: key);

  @override
  State<FileDetailScreen> createState() => _FileDetailScreenState();
}

class _FileDetailScreenState extends State<FileDetailScreen> with SingleTickerProviderStateMixin {
  bool isDownloading = false;
  late TabController _tabController;

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
    if (path == null) return "";
    if (path.startsWith('http')) return path;
    return "http://10.224.9.12:8000/storage/$path";
  }

  void _showRenameDialog(BuildContext context, String currentName, AppLocalizations lang) {
    TextEditingController _nameController = TextEditingController(text: currentName);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Row(
          children: [
            Icon(Icons.edit_rounded, color: theme.primaryColor),
            SizedBox(width: 10),
            Text(
              lang.renameFile ?? "Đổi tên file",
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
          ],
        ),
        content: TextField(
          controller: _nameController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: lang.newName ?? "Tên mới",
            labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primaryColor),
            ),
            prefixIcon: Icon(Icons.description_rounded, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            filled: true,
            fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              lang.cancel ?? "Hủy",
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                context.read<HomeBloc>().add(
                    RenameDocumentRequested(widget.document['id'], _nameController.text)
                );
                setState(() {
                  widget.document['original_name'] = _nameController.text;
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(lang.save ?? "Lưu"),
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

    // Tính toán dữ liệu
    final date = DateTime.parse(document['created_at']);
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

    final int sizeBytes = document['size'] ?? 0;
    String sizeStr = sizeBytes > 1024 * 1024
        ? "${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB"
        : "${(sizeBytes / 1024).toStringAsFixed(2)} KB";

    final pdfUrl = _getFullUrl(document['path']);

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
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
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [Color(0xFF1A237E), Color(0xFF0D47A1)]
                          : [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
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
                            document['original_name'],
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
                    labelStyle: TextStyle(fontWeight: FontWeight.w600),
                    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
                    overlayColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                        if (states.contains(MaterialState.pressed)) {
                          return theme.primaryColor.withOpacity(0.1);
                        }
                        if (states.contains(MaterialState.hovered)) {
                          return theme.primaryColor.withOpacity(0.05);
                        }
                        return null;
                      },
                    ),
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
            // TAB 1: PDF
            _buildPdfTab(context, document, sizeStr, formattedDate, pdfUrl, lang, theme, isDark),
            // TAB 2: Ảnh gốc
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

          // PDF Preview Card
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

          // Info Card
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
                // File name with edit button
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
                              document['original_name'],
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
                          document['original_name'],
                          lang,
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                // Info rows
                _buildModernInfoRow(
                  Icons.sd_storage_rounded,
                  lang.fileSize ?? "Dung lượng",
                  sizeStr,
                  Colors.orange,
                ),
                Divider(height: 1, indent: 70, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                _buildModernInfoRow(
                  Icons.calendar_today_rounded,
                  lang.createdDate ?? "Ngày tạo",
                  formattedDate,
                  Colors.green,
                ),
                Divider(height: 1, indent: 70, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                _buildModernInfoRow(
                  Icons.check_circle_rounded,
                  lang.status ?? "Trạng thái",
                  document['status'] == 'completed'
                      ? (lang.completed ?? 'Hoàn thành')
                      : (lang.processing ?? 'Đang xử lý'),
                  document['status'] == 'completed' ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ),

          SizedBox(height: 25),

          // Download Button
          _buildModernDownloadButton(pdfUrl, document['original_name'], lang, theme),

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
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: isDownloading ? null : () => _downloadAndOpenFile(url, fileName, lang),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: theme.primaryColor.withOpacity(0.5),
          disabledForegroundColor: Colors.white70,
          padding: EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isDownloading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(Icons.download_rounded, size: 24),
            SizedBox(width: 12),
            Text(
              isDownloading
                  ? (lang.downloading ?? "Đang tải...")
                  : (lang.downloadAndOpen ?? "Tải xuống & Mở file"),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTab(Map<String, dynamic> document, AppLocalizations lang, bool isDark) {
    var rawPath = document['original_path'];

    if (rawPath == null) {
      return _buildEmptyState(
        Icons.image_not_supported_rounded,
        lang.noOriginalImage ?? "Không tìm thấy ảnh gốc",
      );
    }

    List<String> imagePaths = [];
    try {
      List<dynamic> parsedList = jsonDecode(rawPath);
      imagePaths = parsedList.map((e) => e.toString()).toList();
    } catch (e) {
      imagePaths.add(rawPath.toString());
    }

    if (imagePaths.isEmpty) {
      return _buildEmptyState(
        Icons.folder_open_rounded,
        lang.oldFileNoImage ?? "File này cũ quá nên không có lưu ảnh gốc!",
      );
    }

    return Container(
      color: isDark ? Colors.black : Colors.grey[900],
      child: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: imagePaths.length,
        separatorBuilder: (_, __) => SizedBox(height: 25),
        itemBuilder: (context, index) {
          final imgUrl = _getFullUrl(imagePaths[index]);
          return Column(
            children: [
              if (imagePaths.length > 1)
                Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${lang.image ?? "Ảnh"} ${index + 1}",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: InteractiveViewer(
                  clipBehavior: Clip.none,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imgUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[800],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_rounded, color: Colors.white54, size: 50),
                          SizedBox(height: 10),
                          Text(
                            lang.imageError ?? "Lỗi tải ảnh",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
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
          Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndOpenFile(String url, String fileName, AppLocalizations lang) async {
    setState(() => isDownloading = true);
    try {
      String savePath;

      if (Platform.isAndroid) {
        savePath = "/storage/emulated/0/Download/$fileName";
      } else {
        final dir = await getApplicationDocumentsDirectory();
        savePath = "${dir.path}/$fileName";
      }

      await Dio().download(url, savePath);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${lang.downloadedTo ?? "Đã tải về"}: Download/$fileName"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      await OpenFilex.open(savePath);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.downloadError ?? "Lỗi tải file hoặc thiếu quyền truy cập"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      print("Download error: $e");
    } finally {
      if (mounted) {
        setState(() => isDownloading = false);
      }
    }
  }

  void _showDeleteConfirm(BuildContext context, AppLocalizations lang) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text(
              lang.confirmDelete ?? "Xác nhận xóa",
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
          ],
        ),
        content: Text(
          lang.confirmDeleteMessage ?? "Bạn có chắc muốn xóa file này không?",
          style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              lang.cancel ?? "Hủy",
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<HomeBloc>().add(DeleteDocumentRequested(widget.document['id']));
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(lang.delete ?? "Xóa"),
          ),
        ],
      ),
    );
  }
}