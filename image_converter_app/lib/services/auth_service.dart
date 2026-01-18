import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'cache_service.dart';
import '../config/api_config.dart';

class AuthService {
  // ✅ Sử dụng ApiConfig thay vì hardcode IP
  final String baseUrl = ApiConfig.apiUrl;

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    headers: ApiConfig.defaultHeaders,
  ));

  final _storage = const FlutterSecureStorage();

  // ==========================================
  // 🔐 ĐĂNG NHẬP (LOGIN)
  // ==========================================
  Future<String?> login(String email, String password) async {
    try {
      print("🚀 Đang gọi API Login: $baseUrl/login");

      final response = await _dio.post('$baseUrl/login', data: {
        'email': email,
        'password': password,
      });

      print("✅ Phản hồi Login: ${response.statusCode}");

      if (response.statusCode == 200) {
        // Lưu Token
        final token = response.data['token'];
        await _storage.write(key: 'auth_token', value: token);

        // (Tùy chọn) Lưu thông tin user để hiển thị profile
        // await _storage.write(key: 'user_name', value: response.data['user']['name']);

        return null; // Null nghĩa là thành công, không có lỗi
      }
      return "Đăng nhập thất bại";
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return "Lỗi không xác định: $e";
    }
  }

  // ==========================================
  // 📝 ĐĂNG KÝ (REGISTER) - ĐÃ CẬP NHẬT
  // ==========================================
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String birthday, // Định dạng chuỗi 'YYYY-MM-DD'
  }) async {
    try {
      print("🚀 Đang gọi API Register...");

      // 🔥 QUAN TRỌNG: Key ở đây phải KHỚP 100% với hàm validator trong Laravel
      final bodyData = {
        'name': name,       // Khớp với validator: 'fullname'
        'email': email,
        'password': password,        // Khớp với validator: 'matkhau'
        'password_confirmation': password,
        'phone': phone,         // Khớp với validator: 'dienthoai'
        'diachi': address,          // Khớp với validator: 'diachi'
        'ngaysinh': birthday,       // Khớp với validator: 'ngaysinh'
      };

      final response = await _dio.post('$baseUrl/register', data: bodyData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Đăng ký xong tự đăng nhập luôn (lưu token)
        final token = response.data['token'];
        await _storage.write(key: 'auth_token', value: token);
        return null; // Thành công
      }
      return "Đăng ký thất bại";
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return "Lỗi hệ thống: $e";
    }
  }

  // Hàm phụ để xử lý lỗi cho gọn code
  String _handleDioError(DioException e) {
    print("❌ Lỗi Dio: ${e.message}");
    if (e.type == DioExceptionType.connectionTimeout) {
      return "Không thể kết nối Server. Vui lòng kiểm tra mạng!";
    }

    // Xử lý lỗi từ Laravel trả về (Validation Error)
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;

      // Trường hợp lỗi Validate (VD: Email trùng, Thiếu tên...)
      if (data['errors'] != null) {
        // Lấy lỗi đầu tiên tìm thấy để hiển thị cho gọn
        Map<String, dynamic> errors = data['errors'];
        String firstError = errors.values.first[0];
        return firstError; // VD: "The email has already been taken."
      }

      return data['message'] ?? "Lỗi từ máy chủ (${e.response?.statusCode})";
    }

    return "Lỗi kết nối: ${e.message}";
  }

  Future<void> logout() async {
    // Xóa token
    await _storage.delete(key: 'auth_token');
    
    // Xóa tất cả cache (documents, user info)
    try {
      final cacheService = await CacheService.getInstance();
      await cacheService.clearAllCache();
      print('🗑️ Đã xóa tất cả cache khi logout');
    } catch (e) {
      print('⚠️ Lỗi xóa cache khi logout: $e');
    }
  }

  // ==========================================
  // 👤 LẤY THÔNG TIN USER (GET USER INFO) - CÓ CACHING
  // ==========================================
  /// Lấy thông tin user với caching
  /// [forceRefresh] - Bắt buộc load từ API, bỏ qua cache
  /// Returns: Map chứa thông tin user hoặc null nếu chưa đăng nhập
  Future<Map<String, dynamic>?> getUser({bool forceRefresh = false}) async {
    try {
      // Import cache service
      final cacheService = await CacheService.getInstance();
      
      // BƯỚC 1: Nếu không force refresh, thử load từ cache trước
      if (!forceRefresh) {
        final cachedUser = await cacheService.getCachedUserInfo();
        if (cachedUser != null) {
          print('⚡ Trả về user info từ cache');
          
          // Background refresh nếu cache hết hạn
          _backgroundRefreshUser(cacheService);
          
          return cachedUser;
        }
      }
      
      // BƯỚC 2: Load từ API
      final userData = await _fetchUserFromApi();
      
      if (userData != null) {
        // BƯỚC 3: Cache data mới
        await cacheService.cacheUserInfo(userData);
        print('🌐 Đã load user từ API và cache');
      }
      
      return userData;
      
    } catch (e) {
      print('❌ Lỗi getUser: $e');
      
      // Fallback về cache nếu API lỗi
      try {
        final cacheService = await CacheService.getInstance();
        final cachedUser = await cacheService.getCachedUserInfo(ignoreExpiry: true);
        if (cachedUser != null) {
          print('⚠️ API lỗi, fallback về cache user');
          return cachedUser;
        }
      } catch (_) {}
      
      return null;
    }
  }
  
  /// Background refresh user info (không block UI)
  Future<void> _backgroundRefreshUser(CacheService cacheService) async {
    try {
      // Kiểm tra cache còn valid không
      final cachedUser = await cacheService.getCachedUserInfo();
      if (cachedUser == null) {
        // Cache hết hạn, cần refresh
        print('🔄 Background refresh user info...');
        final userData = await _fetchUserFromApi();
        if (userData != null) {
          await cacheService.cacheUserInfo(userData);
          print('✅ Background refresh user thành công');
        }
      }
    } catch (e) {
      print('⚠️ Background refresh user thất bại: $e');
    }
  }
  
  /// Fetch user từ API (internal method)
  Future<Map<String, dynamic>?> _fetchUserFromApi() async {
    try {
      // Lấy token đã lưu
      final token = await _storage.read(key: 'auth_token');

      if (token == null) {
        print("❌ Chưa đăng nhập - không có token");
        return null;
      }

      print("🚀 Đang gọi API Get User: $baseUrl/get_user");

      final response = await _dio.get(
        '$baseUrl/get_user',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print("✅ Phản hồi Get User: ${response.statusCode}");

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        // Trả về với key phù hợp cho ProfileScreen
        return {
          'name': data['full_name'] ?? 'Người dùng',
          'email': data['email'] ?? '',
          'username': data['username'] ?? '',
          'phone': data['phone'] ?? '',
          'photo': data['photo'],
          'address': data['address'] ?? '',
          'birthday': data['birthday'],
          'description': data['description'] ?? '',
        };
      }

      return null;
    } on DioException catch (e) {
      print("❌ Lỗi API Get User: ${_handleDioError(e)}");
      return null;
    } catch (e) {
      print("❌ Lỗi không xác định: $e");
      return null;
    }
  }
  
  /// Invalidate user cache (gọi sau khi update profile)
  Future<void> invalidateUserCache() async {
    try {
      final cacheService = await CacheService.getInstance();
      await cacheService.clearUserInfoCache();
      print('🗑️ Đã xóa cache user info');
    } catch (e) {
      print('⚠️ Lỗi xóa cache user: $e');
    }
  }

  // ==========================================
  // 🔑 KIỂM TRA ĐÃ ĐĂNG NHẬP CHƯA
  // ==========================================
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }

  // ==========================================
  // 🔐 LẤY TOKEN HIỆN TẠI
  // ==========================================
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
}
