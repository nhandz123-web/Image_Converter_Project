import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import 'network_service.dart';

class DocumentService {
  // ✅ Sử dụng ApiConfig thay vì hardcode IP
  final String _apiUrl = ApiConfig.apiUrl;
  final _storage = const FlutterSecureStorage();

  // ✅ Network Service để kiểm tra kết nối mạng
  final NetworkService _networkService = NetworkService.getInstance();

  // Helper lấy headers
  Future<Map<String, String>> _getAuthHeaders() async {
    String? token = await _storage.read(key: 'auth_token');
    if (token == null) throw Exception('Bạn chưa đăng nhập');
    return ApiConfig.authHeaders(token);
  }
  // ==================== CONVERT API ====================

  /// Upload ảnh và convert sang PDF
  /// Backend: POST /api/ với images[] array
  /// [imageFiles] - Danh sách file ảnh
  /// [quality] - Chất lượng nén (low, medium, high, original)
  /// [outputName] - Tên file output tùy chỉnh (không bắt buộc)
  Future<Map<String, dynamic>?> uploadImages(
      List<File> imageFiles, {
        String quality = 'medium',
        String? outputName,
      }) async {
    try {
      // ✅ Kiểm tra mạng trước khi gọi API
      await _networkService.ensureConnectivity();

      String? token = await _storage.read(key: 'auth_token');
      if (token == null) return null;

      // Backend route: POST /api/ (root path)
      var uri = Uri.parse('$_apiUrl${ApiConfig.documentsEndpoint}');
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll(ApiConfig.authHeaders(token));

      // Thêm quality parameter
      request.fields['quality'] = quality;

      // Thêm output_name nếu có
      if (outputName != null && outputName.isNotEmpty) {
        request.fields['output_name'] = outputName;
      }

      // QUAN TRỌNG: Backend Laravel đang đợi key là 'images[]'
      for (var file in imageFiles) {
        request.files.add(await http.MultipartFile.fromPath(
          'images[]', // Thêm ngoặc [] để Laravel hiểu là mảng
          file.path,
        ));
      }

      var streamedResponse = await request.send().timeout(ApiConfig.sendTimeout);
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Lỗi upload');
      }
    } catch (e) {
      print("Lỗi uploadImages: $e");
      rethrow;
    }
  }

  /// Lấy danh sách quality presets
  /// Backend: GET /api/quality-presets
  Future<Map<String, dynamic>> getQualityPresets() async {
    try {
      // ✅ Kiểm tra mạng trước khi gọi API
      await _networkService.ensureConnectivity();

      final headers = await _getAuthHeaders();

      final response = await http.get(
        Uri.parse('$_apiUrl${ApiConfig.qualityPresetsEndpoint}'),
        headers: headers,
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Không lấy được quality presets: ${response.statusCode}');
      }
    } catch (e) {
      print("Lỗi getQualityPresets: $e");
      rethrow;
    }
  }

  // ==================== FILE PREVIEW ====================

  /// Lấy URL preview file (hiển thị inline)
  /// Backend: GET /api/files/{id}/preview
  String getPreviewUrl(int fileId) {
    return '$_apiUrl${ApiConfig.filePreviewEndpoint(fileId)}';
  }

  /// Lấy URL stream file (hỗ trợ Range requests cho PDF reader)
  /// Backend: GET /api/files/{id}/stream
  String getStreamUrl(int fileId) {
    return '$_apiUrl${ApiConfig.fileStreamEndpoint(fileId)}';
  }

  /// Lấy URL download file
  /// Backend: GET /api/files/{id}/download
  String getDownloadUrl(int fileId) {
    return '$_apiUrl${ApiConfig.fileDownloadEndpoint(fileId)}';
  }

  /// Lấy thông tin chi tiết file
  /// Backend: GET /api/files/{id}/info
  Future<Map<String, dynamic>?> getFileInfo(int fileId) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http.get(
        Uri.parse('$_apiUrl${ApiConfig.fileInfoEndpoint(fileId)}'),
        headers: headers,
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          return data['file'];
        }
      }
      return null;
    } catch (e) {
      print("Lỗi getFileInfo: $e");
      return null;
    }
  }

  // ==================== DOCUMENT MANAGEMENT ====================

  /// Lấy danh sách lịch sử documents
  /// Backend: GET /api/ (index method)
  Future<List<dynamic>> getHistory() async {
    try {
      // ✅ Kiểm tra mạng trước khi gọi API
      await _networkService.ensureConnectivity();

      final headers = await _getAuthHeaders();

      final response = await http.get(
        Uri.parse('$_apiUrl${ApiConfig.documentsEndpoint}'),
        headers: headers,
      ).timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Backend trả về: { success: true, documents: [...] }
        if (data['documents'] is List) {
          return data['documents'];
        } else if (data['documents'] is Map && data['documents']['data'] is List) {
          // Nếu có pagination
          return data['documents']['data'];
        } else {
          throw Exception('Format dữ liệu không đúng');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
      } else {
        throw Exception('Không lấy được lịch sử (${response.statusCode})');
      }
    } catch (e) {
      print("Lỗi getHistory: $e");
      rethrow;
    }
  }

  /// Xóa document theo ID
  /// Backend: DELETE /api/{id}
  Future<void> deleteDocument(int id) async {
    try {
      // ✅ Kiểm tra mạng trước khi gọi API
      await _networkService.ensureConnectivity();

      final headers = await _getAuthHeaders();

      // Backend route: DELETE /api/{id}
      final url = Uri.parse('$_apiUrl${ApiConfig.fileDeleteEndpoint(id)}');

      final response = await http.delete(
        url,
        headers: headers,
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        print('Xóa thành công ID: $id');
        return;
      } else {
        final body = jsonDecode(response.body);
        String errorMessage = body['message'] ?? 'Lỗi không xác định từ server';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Lỗi deleteDocument: $e');
      rethrow;
    }
  }

  /// Đổi tên document
  /// Backend: PUT /api/{id}
  Future<void> renameDocument(int id, String newName) async {
    try {
      // ✅ Kiểm tra mạng trước khi gọi API
      await _networkService.ensureConnectivity();

      final headers = await _getAuthHeaders();

      // Backend route: PUT /api/{id}
      final response = await http.put(
        Uri.parse('$_apiUrl${ApiConfig.fileRenameEndpoint(id)}'),
        headers: headers,
        body: jsonEncode({'new_name': newName}),
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Lỗi khi đổi tên file');
      }
    } catch (e) {
      print('Lỗi renameDocument: $e');
      rethrow;
    }
  }

  /// Gộp nhiều file PDF thành một
  /// Backend: POST /api/merge
  ///
  /// [documentIds] - Danh sách ID của các file PDF cần gộp (theo thứ tự)
  /// [outputName] - Tên file output (optional)
  ///
  /// Returns: Map chứa thông tin document đã được gộp
  Future<Map<String, dynamic>> mergePdfs(
      List<int> documentIds, {
        String? outputName,
      }) async {
    try {
      // ✅ Kiểm tra mạng trước khi gọi API
      await _networkService.ensureConnectivity();

      final headers = await _getAuthHeaders();

      // Validate input
      if (documentIds.length < 2) {
        throw Exception('Cần ít nhất 2 file PDF để gộp');
      }

      // Prepare request body
      Map<String, dynamic> requestBody = {
        'pdf_ids': documentIds,
      };

      if (outputName != null && outputName.isNotEmpty) {
        requestBody['output_name'] = outputName;
      }

      final response = await http.post(
        Uri.parse('$_apiUrl${ApiConfig.mergeEndpoint}'),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(ApiConfig.sendTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['status'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Lỗi gộp PDF');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 422) {
        // Validation error
        throw Exception(data['message'] ?? 'Dữ liệu không hợp lệ');
      } else if (response.statusCode == 429) {
        // Rate limit
        throw Exception(data['message'] ?? 'Quá nhiều yêu cầu. Vui lòng thử lại sau.');
      } else {
        throw Exception(data['message'] ?? 'Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi mergePdfs: $e');
      rethrow;
    }
  }

  // ==================== INFO & STORAGE ====================
  // (User info methods moved to AuthService)

  /// Lấy thông tin dung lượng - Backend chưa có route này
  /// TODO: Cần thêm route trong backend
  Future<Map<String, dynamic>> getStorageUsage() async {
    throw UnimplementedError('Backend chưa hỗ trợ storage usage. Cần thêm route /api/storage');
  }

  // ==================== SPLIT PDF ====================

  /// Lấy thông tin PDF (bao gồm số trang) trước khi tách
  /// Backend: GET /api/pdf-info/{id}
  Future<Map<String, dynamic>> getPdfInfo(int fileId) async {
    try {
      await _networkService.ensureConnectivity();
      final headers = await _getAuthHeaders();

      final response = await http.get(
        Uri.parse('$_apiUrl/pdf-info/$fileId'),
        headers: headers,
      ).timeout(ApiConfig.connectTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        return data['pdf_info'];
      } else {
        throw Exception(data['message'] ?? 'Không lấy được thông tin PDF');
      }
    } catch (e) {
      print('Lỗi getPdfInfo: $e');
      rethrow;
    }
  }

  /// Tách PDF theo phạm vi trang (từ trang X đến trang Y)
  /// Backend: POST /api/split
  ///
  /// [fileId] - ID của file PDF cần tách
  /// [startPage] - Trang bắt đầu (1-indexed)
  /// [endPage] - Trang kết thúc (1-indexed)
  /// [outputName] - Tên file output (optional)
  Future<Map<String, dynamic>> splitPdf({
    required int fileId,
    required int startPage,
    required int endPage,
    String? outputName,
  }) async {
    try {
      await _networkService.ensureConnectivity();
      final headers = await _getAuthHeaders();

      // Validate input
      if (startPage < 1) {
        throw Exception('Trang bắt đầu phải >= 1');
      }
      if (endPage < startPage) {
        throw Exception('Trang kết thúc phải >= trang bắt đầu');
      }

      Map<String, dynamic> requestBody = {
        'file_id': fileId,
        'start_page': startPage,
        'end_page': endPage,
      };

      if (outputName != null && outputName.isNotEmpty) {
        requestBody['output_name'] = outputName;
      }

      final response = await http.post(
        Uri.parse('$_apiUrl/split'),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(ApiConfig.sendTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['status'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Lỗi tách PDF');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn');
      } else if (response.statusCode == 403) {
        throw Exception(data['message'] ?? 'Bạn cần mua gói VIP để sử dụng tính năng này');
      } else if (response.statusCode == 422) {
        throw Exception(data['message'] ?? 'Dữ liệu không hợp lệ');
      } else {
        throw Exception(data['message'] ?? 'Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi splitPdf: $e');
      rethrow;
    }
  }

  /// Tách PDF theo danh sách trang cụ thể
  /// Backend: POST /api/split-by-pages
  ///
  /// [fileId] - ID của file PDF cần tách
  /// [pages] - Danh sách số trang cần lấy [1, 3, 5, 7]
  /// [outputName] - Tên file output (optional)
  Future<Map<String, dynamic>> splitPdfByPages({
    required int fileId,
    required List<int> pages,
    String? outputName,
  }) async {
    try {
      await _networkService.ensureConnectivity();
      final headers = await _getAuthHeaders();

      // Validate input
      if (pages.isEmpty) {
        throw Exception('Vui lòng chọn ít nhất 1 trang');
      }

      Map<String, dynamic> requestBody = {
        'file_id': fileId,
        'pages': pages,
      };

      if (outputName != null && outputName.isNotEmpty) {
        requestBody['output_name'] = outputName;
      }

      final response = await http.post(
        Uri.parse('$_apiUrl/split-by-pages'),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(ApiConfig.sendTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['status'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Lỗi tách PDF');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn');
      } else if (response.statusCode == 403) {
        throw Exception(data['message'] ?? 'Bạn cần mua gói VIP để sử dụng tính năng này');
      } else if (response.statusCode == 422) {
        throw Exception(data['message'] ?? 'Dữ liệu không hợp lệ');
      } else {
        throw Exception(data['message'] ?? 'Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi splitPdfByPages: $e');
      rethrow;
    }
  }

  // ==================== COMPRESS ====================

  /// Nén file (ảnh hoặc PDF)
  /// Backend: POST /api/compress
  ///
  /// [file] - File cần nén
  /// [quality] - Mức chất lượng: high, medium, low
  /// [outputName] - Tên file output (optional)
  Future<Map<String, dynamic>> compressFile({
    required File file,
    String quality = 'medium',
    String? outputName,
  }) async {
    try {
      await _networkService.ensureConnectivity();

      String? token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Bạn chưa đăng nhập');

      var uri = Uri.parse('$_apiUrl/compress');
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll(ApiConfig.authHeaders(token));

      // Thêm quality parameter
      request.fields['quality'] = quality;

      // Thêm output_name nếu có
      if (outputName != null && outputName.isNotEmpty) {
        request.fields['output_name'] = outputName;
      }

      // Thêm file
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
      ));

      var streamedResponse = await request.send().timeout(ApiConfig.sendTimeout);
      var response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['status'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Lỗi nén file');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn');
      } else if (response.statusCode == 403) {
        throw Exception(data['message'] ?? 'Bạn cần mua gói VIP để sử dụng tính năng này');
      } else if (response.statusCode == 422) {
        throw Exception(data['message'] ?? 'Dữ liệu không hợp lệ');
      } else {
        throw Exception(data['message'] ?? 'Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi compressFile: $e');
      rethrow;
    }
  }

  /// Nén file đã có trong hệ thống (theo fileId)
  /// Backend: POST /api/compress với file_id
  Future<Map<String, dynamic>> compressExistingFile({
    required int fileId,
    String quality = 'medium',
    String? outputName,
  }) async {
    try {
      await _networkService.ensureConnectivity();
      final headers = await _getAuthHeaders();

      Map<String, dynamic> requestBody = {
        'file_id': fileId,
        'quality': quality,
      };

      if (outputName != null && outputName.isNotEmpty) {
        requestBody['output_name'] = outputName;
      }

      final response = await http.post(
        Uri.parse('$_apiUrl/compress'),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(ApiConfig.sendTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['status'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Lỗi nén file');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn');
      } else if (response.statusCode == 403) {
        throw Exception(data['message'] ?? 'Bạn cần mua gói VIP để sử dụng tính năng này');
      } else {
        throw Exception(data['message'] ?? 'Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi compressExistingFile: $e');
      rethrow;
    }
  }

  /// Lấy thông tin các mức nén
  /// Backend: GET /api/compression-info
  Future<Map<String, dynamic>> getCompressionInfo() async {
    try {
      await _networkService.ensureConnectivity();
      final headers = await _getAuthHeaders();

      final response = await http.get(
        Uri.parse('$_apiUrl/compression-info'),
        headers: headers,
      ).timeout(ApiConfig.connectTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Không lấy được thông tin nén');
      }
    } catch (e) {
      print('Lỗi getCompressionInfo: $e');
      rethrow;
    }
  }
}
