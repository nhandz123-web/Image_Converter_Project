import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

class DocumentService {
  // Thay đổi IP này giống bên AuthService (10.0.2.2 nếu máy ảo, IP LAN nếu máy thật)
  final String baseUrl = "http://192.168.1.2:8001/api";
  final _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();
  DocumentService() {
    _dio.options.baseUrl = baseUrl;
  }
  // Hàm Upload ảnh
  Future<Map<String, dynamic>?> uploadImages(List<File> imageFiles) async {
    try {
      String? token = await _storage.read(key: 'auth_token');
      if (token == null) return null;

      var uri = Uri.parse('$baseUrl/convert');
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // QUAN TRỌNG: Backend Laravel đang đợi key là 'images[]'
      // Duyệt qua từng file trong danh sách để add vào request
      for (var file in imageFiles) {
        request.files.add(await http.MultipartFile.fromPath(
          'images[]', // Thêm ngoặc [] để Laravel hiểu là mảng
          file.path,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Lỗi upload');
      }
    } catch (e) {
      print("Lỗi Service: $e");
      rethrow;
    }
  }

    // --- HÀM GỘP PDF (Dùng Dio) ---
  Future<Map<String, dynamic>> mergePdfs(List<int> documentIds) async {
    try {
      // Lấy token từ storage giống các hàm http bên dưới
      String? token = await _storage.read(key: 'auth_token');

      final response = await _dio.post(
        '/documents/merge',
        data: {
          'document_ids': documentIds,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Lỗi server khi gộp PDF");
    } catch (e) {
      throw Exception("Lỗi hệ thống: $e");
    }
  }

  // Hàm lấy danh sách lịch sử
  Future<List<dynamic>> getHistory() async {
    String? token = await _storage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse('$baseUrl/history'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['documents']; // Trả về mảng documents
    } else {
      throw Exception('Không lấy được lịch sử');
    }
  }

  Future<void> deleteDocument(int id) async {
    String? token = await _storage.read(key: 'auth_token');
    final response = await http.delete(
      Uri.parse('$baseUrl/documents/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi khi xóa file');
    }
  }
  // Lấy thông tin dung lượng
  Future<Map<String, dynamic>> getStorageUsage() async {
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
  }
  // Hàm đổi tên tài liệu
  Future<void> renameDocument(int id, String newName) async {
    String? token = await _storage.read(key: 'auth_token');
    final response = await http.put(
      Uri.parse('$baseUrl/documents/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json', // Quan trọng khi gửi body json
        'Accept': 'application/json',
      },
      body: jsonEncode({'name': newName}), // Gửi tên mới lên
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi khi đổi tên file');
    }
  }

  // Hàm lấy thông tin user (Tên, Email)
  Future<Map<String, dynamic>> getUserInfo() async {
    String? token = await _storage.read(key: 'auth_token');
    // Gọi vào API /user có sẵn của Laravel
    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Trả về {id, name, email...}
    } else {
      throw Exception('Không lấy được thông tin user');
    }
  }
  // Hàm cập nhật hồ sơ
  Future<void> updateProfile(String name, String? currentPassword, String? newPassword) async {
    String? token = await _storage.read(key: 'auth_token');

    Map<String, String> data = {'name': name};

    // Nếu có đổi mật khẩu thì gửi cả mật khẩu cũ và mới đi
    if (newPassword != null && newPassword.isNotEmpty) {
      data['current_password'] = currentPassword ?? ""; // Gửi key này cho Laravel check
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
      // Ném lỗi ra để màn hình hiển thị (VD: Mật khẩu cũ sai)
      throw Exception(body['message'] ?? "Lỗi cập nhật hồ sơ");
    }
  }
}
