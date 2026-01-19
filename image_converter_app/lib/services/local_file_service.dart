import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

/// Model đại diện cho một file đã tải xuống
class LocalFile {
  final String id;
  final String name;
  final String path;
  final String type; // 'pdf', 'image', etc.
  final int size; // bytes
  final DateTime downloadedAt;
  final String? originalName;
  final String? thumbnailPath;

  LocalFile({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.downloadedAt,
    this.originalName,
    this.thumbnailPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'type': type,
    'size': size,
    'downloadedAt': downloadedAt.toIso8601String(),
    'originalName': originalName,
    'thumbnailPath': thumbnailPath,
  };

  factory LocalFile.fromJson(Map<String, dynamic> json) => LocalFile(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    path: json['path'] ?? '',
    type: json['type'] ?? 'unknown',
    size: json['size'] ?? 0,
    downloadedAt: DateTime.tryParse(json['downloadedAt'] ?? '') ?? DateTime.now(),
    originalName: json['originalName'],
    thumbnailPath: json['thumbnailPath'],
  );

  /// Kiểm tra file có tồn tại trên thiết bị không
  bool get exists => File(path).existsSync();
  /// Format kích thước file
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

/// Service quản lý các file đã tải xuống cục bộ
/// Hoạt động hoàn toàn offline
class LocalFileService {
  static const String _storageKey = 'downloaded_files';
  static const String _downloadsFolderName = 'SnapPDF_Files';

  /// Lấy thư mục lưu trữ downloads
  Future<Directory> get _downloadsDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory(p.join(appDir.path, _downloadsFolderName));

    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    return downloadsDir;
  }

  /// Lấy danh sách file đã tải xuống với pagination
  /// [limit] - số file tối đa trả về (mặc định 20)
  /// [offset] - vị trí bắt đầu (mặc định 0)
  Future<List<LocalFile>> getDownloadedFiles({int limit = 20, int offset = 0}) async {
    try {
      final allFiles = await _getAllFilesInternal();
      
      // Apply pagination
      if (offset >= allFiles.length) {
        return [];
      }

      final endIndex = (offset + limit) > allFiles.length ? allFiles.length : (offset + limit);
      return allFiles.sublist(offset, endIndex);
    } catch (e) {
      print('❌ [LocalFileService] Error loading files: $e');
      return [];
    }
  }

  /// ✅ OPTIMIZED: Lấy files với stats trong một lần đọc duy nhất
  /// Tránh đọc SharedPreferences và parse JSON nhiều lần
  Future<({List<LocalFile> files, int totalSize, int totalCount})> getFilesWithStats({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final allFiles = await _getAllFilesInternal();
      
      // Tính totalSize từ tất cả files
      final totalSize = allFiles.fold<int>(0, (sum, file) => sum + file.size);
      final totalCount = allFiles.length;
      
      // Apply pagination
      List<LocalFile> paginatedFiles;
      if (offset >= allFiles.length) {
        paginatedFiles = [];
      } else {
        final endIndex = (offset + limit) > allFiles.length ? allFiles.length : (offset + limit);
        paginatedFiles = allFiles.sublist(offset, endIndex);
      }

      return (files: paginatedFiles, totalSize: totalSize, totalCount: totalCount);
    } catch (e) {
      print('❌ [LocalFileService] Error loading files with stats: $e');
      return (files: <LocalFile>[], totalSize: 0, totalCount: 0);
    }
  }

  /// ✅ INTERNAL: Đọc và parse tất cả files một lần
  /// Được cache trong một request để tránh đọc lại
  Future<List<LocalFile>> _getAllFilesInternal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final List<dynamic> jsonList = json.decode(jsonString);
    final allFiles = jsonList
        .map((item) => LocalFile.fromJson(item as Map<String, dynamic>))
        .where((file) => file.exists) // Chỉ trả về file còn tồn tại
        .toList();

    // Sắp xếp theo thời gian tải xuống mới nhất
    allFiles.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));

    return allFiles;
  }

  /// Lấy tổng số file đã tải xuống (để tính hasMore)
  Future<int> getTotalFileCount() async {
    try {
      final allFiles = await _getAllFilesInternal();
      return allFiles.length;
    } catch (e) {
      print('❌ [LocalFileService] Error getting file count: $e');
      return 0;
    }
  }

  /// Lưu file vào local storage và thêm vào danh sách
  Future<LocalFile?> saveFile({
    required String sourceUrl,
    required String fileName,
    required String fileType,
    required List<int> bytes,
    String? originalName,
  }) async {
    try {
      final downloadsDir = await _downloadsDirectory;
      final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
      final extension = _getExtension(fileType);
      final safeFileName = _sanitizeFileName(fileName);
      final finalFileName = '${safeFileName}_$uniqueId$extension';
      final filePath = p.join(downloadsDir.path, finalFileName);

      // Lưu file
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Tạo LocalFile object
      final localFile = LocalFile(
        id: uniqueId,
        name: fileName,
        path: filePath,
        type: fileType,
        size: bytes.length,
        downloadedAt: DateTime.now(),
        originalName: originalName,
      );

      // Thêm vào danh sách đã lưu
      await _addFileToStorage(localFile);

      return localFile;
    } catch (e) {
      print('❌ [LocalFileService] Error saving file: $e');
      return null;
    }
  }

  /// Thêm file đã có sẵn vào danh sách quản lý
  Future<LocalFile?> addExistingFile({
    required String filePath,
    required String fileName,
    required String fileType,
    String? originalName,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ [LocalFileService] File does not exist: $filePath');
        return null;
      }

      final stat = await file.stat();
      final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();

      final localFile = LocalFile(
        id: uniqueId,
        name: fileName,
        path: filePath,
        type: fileType,
        size: stat.size,
        downloadedAt: DateTime.now(),
        originalName: originalName,
      );

      await _addFileToStorage(localFile);
      return localFile;
    } catch (e) {
      print('❌ [LocalFileService] Error adding existing file: $e');
      return null;
    }
  }

  /// Xóa file khỏi storage và local
  Future<bool> deleteFile(String fileId) async {
    try {
      final files = await getDownloadedFiles();
      final fileToDelete = files.firstWhere(
        (f) => f.id == fileId,
        orElse: () => throw Exception('File not found'),
      );

      // Xóa file thực tế
      final file = File(fileToDelete.path);
      if (await file.exists()) {
        await file.delete();
      }

      // Xóa khỏi storage
      await _removeFileFromStorage(fileId);

      return true;
    } catch (e) {
      print('❌ [LocalFileService] Error deleting file: $e');
      return false;
    }
  }

  /// Xóa nhiều file
  Future<int> deleteFiles(List<String> fileIds) async {
    int deletedCount = 0;
    for (final id in fileIds) {
      if (await deleteFile(id)) {
        deletedCount++;
      }
    }
    return deletedCount;
  }

  /// Lấy tổng dung lượng đã sử dụng
  Future<int> getTotalSize() async {
    final files = await getDownloadedFiles();
    return files.fold<int>(0, (sum, file) => sum + file.size);
  }

  /// Format tổng dung lượng
  Future<String> getFormattedTotalSize() async {
    final total = await getTotalSize();
    if (total < 1024) return '$total B';
    if (total < 1024 * 1024) return '${(total / 1024).toStringAsFixed(1)} KB';
    return '${(total / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Xóa tất cả file
  Future<void> clearAll() async {
    try {
      final files = await getDownloadedFiles();

      // Xóa từng file
      for (final localFile in files) {
        final file = File(localFile.path);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Xóa storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      print('❌ [LocalFileService] Error clearing all files: $e');
    }
  }

  // ======================== PRIVATE METHODS ========================

  Future<void> _addFileToStorage(LocalFile file) async {
    final prefs = await SharedPreferences.getInstance();
    final files = await getDownloadedFiles();

    // Thêm file mới vào đầu danh sách
    files.insert(0, file);

    final jsonString = json.encode(files.map((f) => f.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  Future<void> _removeFileFromStorage(String fileId) async {
    final prefs = await SharedPreferences.getInstance();
    final files = await getDownloadedFiles();

    files.removeWhere((f) => f.id == fileId);

    final jsonString = json.encode(files.map((f) => f.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  String _getExtension(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return '.pdf';
      case 'image':
      case 'jpg':
      case 'jpeg':
        return '.jpg';
      case 'png':
        return '.png';
      case 'word':
      case 'docx':
        return '.docx';
      case 'excel':
      case 'xlsx':
        return '.xlsx';
      default:
        return '';
    }
  }

  String _sanitizeFileName(String fileName) {
    // Loại bỏ ký tự không hợp lệ
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .substring(0, fileName.length > 50 ? 50 : fileName.length);
  }
}
