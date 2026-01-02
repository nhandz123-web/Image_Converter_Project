import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // 10.0.2.2 là localhost của máy tính khi nhìn từ máy ảo Android
  final String baseUrl = "http://192.168.1.2:8001/api";

  final Dio _dio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 5), // 5 giây không kết nối được thì báo lỗi
  receiveTimeout: const Duration(seconds: 5),
  ));
  final _storage = const FlutterSecureStorage();

  // Hàm Đăng nhập
  Future<String?> login(String email, String password) async {
    try {
      print("Đang gọi API: $baseUrl/login"); // In log để kiểm tra

      final response = await _dio.post('$baseUrl/login', data: {
        'email': email,
        'password': password,
      });

      print("Phản hồi: ${response.statusCode}"); // In log phản hồi

      if (response.statusCode == 200) {
        final token = response.data['token'];
        await _storage.write(key: 'auth_token', value: token);
        return null;
      }
      return "Đăng nhập thất bại";
    } on DioException catch (e) {
      print("Lỗi Dio: ${e.message}"); // In chi tiết lỗi ra console
      if (e.type == DioExceptionType.connectionTimeout) {
        return "Hết thời gian kết nối. Kiểm tra lại Server!";
      }
      if (e.response != null) {
        return e.response?.data['message'] ?? "Lỗi từ server";
      }
      return "Không thể kết nối Server (Lỗi mạng)";
    } catch (e) {
      print("Lỗi khác: $e");
      return "Lỗi không xác định: $e";
    }
  }

  // Hàm Đăng ký
  Future<String?> register(String name, String email, String password) async {
    try {
      final response = await _dio.post('$baseUrl/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });

      if (response.statusCode == 201) {
        final token = response.data['token'];
        await _storage.write(key: 'auth_token', value: token);
        return null;
      }
      return "Đăng ký thất bại";
    } on DioException catch (e) {
      // Lấy lỗi validation từ Laravel (VD: Email trùng)
      final data = e.response?.data;
      if(data != null && data['errors'] != null) {
        return data['errors'].toString();
      }
      return e.response?.data['message'] ?? "Lỗi đăng ký";
    }
  }

  Future<void> logout() async {
    // Xóa token lưu trong máy -> Coi như đăng xuất
    await _storage.delete(key: 'auth_token');
  }
}
