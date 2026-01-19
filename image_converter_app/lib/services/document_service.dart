import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import 'network_service.dart';

class DocumentService {
  // ✅ Sử dụng ApiConfig thay vì hardcode IP
  final String baseUrl = ApiConfig.apiUrl;
  final _storage = const FlutterSecureStorage();
  
  // ✅ Network Service để kiểm tra kết nối mạng
  final NetworkService _networkService = NetworkService.getInstance();
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

      // Backend route: POST /api/ (root path, không phải /api/convert)
      var uri = Uri.parse(baseUrl);
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

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

      var streamedResponse = await request.send();
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
      
      String? token = await _storage.read(key: 'auth_token');
      
      // ✅ CRITICAL FIX: Check null token trước khi gọi API
      if (token == null) {
        throw Exception('Bạn chưa đăng nhập');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/quality-presets'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Không lấy được quality presets');
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
    return '$baseUrl/files/$fileId/preview';
  }

  /// Lấy URL stream file (hỗ trợ Range requests cho PDF reader)
  /// Backend: GET /api/files/{id}/stream
  String getStreamUrl(int fileId) {
    return '$baseUrl/files/$fileId/stream';
  }

  /// Lấy URL download file
  /// Backend: GET /api/files/{id}/download
  String getDownloadUrl(int fileId) {
    return '$baseUrl/files/$fileId/download';
  }

  /// Lấy thông tin chi tiết file
  /// Backend: GET /api/files/{id}/info
  Future<Map<String, dynamic>?> getFileInfo(int fileId) async {
    try {
      String? token = await _storage.read(key: 'auth_token');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/files/$fileId/info'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

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
      
      String? token = await _storage.read(key: 'auth_token');
      
      // ✅ CRITICAL FIX: Check null token trước khi gọi API
      if (token == null) {
        throw Exception('Bạn chưa đăng nhập');
      }

      // Backend route: GET /api/ (root path, không phải /api/history)
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

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
      
      String? token = await _storage.read(key: 'auth_token');

      if (token == null) {
        throw Exception('Bạn chưa đăng nhập');
      }

      // Backend route: DELETE /api/{id} (không phải /api/documents/{id})
      final url = Uri.parse('$baseUrl/$id');

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

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
      
      String? token = await _storage.read(key: 'auth_token');

      // Backend route: PUT /api/{id} (không phải /api/documents/{id})
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'new_name': newName}),
      );

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
      
      String? token = await _storage.read(key: 'auth_token');

      if (token == null) {
        throw Exception('Bạn chưa đăng nhập');
      }

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
        Uri.parse('$baseUrl/merge'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

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

  /// Lấy thông tin dung lượng - Backend chưa có route này
  /// TODO: Cần thêm route trong backend
  Future<Map<String, dynamic>> getStorageUsage() async {
    throw UnimplementedError('Backend chưa hỗ trợ storage usage. Cần thêm route /api/storage');

    // Code tạm comment:
    /*
    String? token = await _storage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse('$baseUrl/storage'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Lỗi lấy thông tin dung lượng');
    }
    */
  }

  // ==================== USER API ====================

  /// Lấy thông tin user hiện tại
  /// Backend: GET /api/get_user
  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      // ✅ Kiểm tra mạng trước khi gọi API
      await _networkService.ensureConnectivity();
      
      String? token = await _storage.read(key: 'auth_token');

      if (token == null) {
        throw Exception('Chưa đăng nhập');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/get_user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          // Trả về data với format phù hợp cho ProfileScreen
          return {
            'name': data['data']['full_name'] ?? 'Người dùng',
            'email': data['data']['email'] ?? '',
            'username': data['data']['username'] ?? '',
            'phone': data['data']['phone'] ?? '',
            'photo': data['data']['photo'],
            'address': data['data']['address'] ?? '',
            'birthday': data['data']['birthday'],
            'description': data['data']['description'] ?? '',
          };
        } else {
          throw Exception(data['message'] ?? 'Không lấy được thông tin user');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
      } else {
        throw Exception('Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi getUserInfo: $e');
      rethrow;
    }
  }

  /// Cập nhật hồ sơ user - Backend chưa có route
  /// TODO: Cần thêm route trong backend
  Future<void> updateProfile(String name, String? currentPassword, String? newPassword) async {
    throw UnimplementedError('Backend chưa hỗ trợ update profile. Cần thêm route /api/user/update');

    // Code tạm comment:
    /*
    String? token = await _storage.read(key: 'auth_token');

    Map<String, String> data = {'name': name};

    if (newPassword != null && newPassword.isNotEmpty) {
      data['current_password'] = currentPassword ?? "";
      data['password'] = newPassword;
      data['password_confirmation'] = newPassword;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/user/update'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? "Lỗi cập nhật hồ sơ");
    }
    */
  }
}
