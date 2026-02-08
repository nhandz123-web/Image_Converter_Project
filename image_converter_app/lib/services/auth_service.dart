import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'cache_service.dart';
import '../config/api_config.dart';
import 'network_service.dart';

class AuthService {
  // ✅ Sử dụng ApiConfig thay vì hardcode IP
  final String baseUrl = ApiConfig.apiUrl;

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    headers: ApiConfig.defaultHeaders,
  ));

  final _storage = const FlutterSecureStorage();
  
  // ✅ Network Service để kiểm tra kết nối mạng
  final NetworkService _networkService = NetworkService.getInstance();

  // ==========================================
  // 🔐 ĐĂNG NHẬP (LOGIN)
  // ==========================================
  Future<String?> login(String email, String password) async {
    try {
      // ✅ Kiểm tra mạng trước khi gọi API
      final hasNetwork = await _networkService.checkConnectivity();
      if (!hasNetwork) {
        return 'Không có kết nối mạng. Vui lòng kiểm tra internet của bạn.';
      }
      
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
      // ✅ Kiểm tra mạng trước khi gọi API
      final hasNetwork = await _networkService.checkConnectivity();
      if (!hasNetwork) {
        return 'Không có kết nối mạng. Vui lòng kiểm tra internet của bạn.';
      }
      
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
      print('🗑️ Đã xóa tất cả cache local khi logout');
    } catch (e) {
      print('⚠️ Lỗi xóa cache local: $e');
    }

    // Xóa cache hình ảnh (Disk & Memory)
    try {
      // Xóa cache file trên đĩa (do cached_network_image tạo ra)
      await DefaultCacheManager().emptyCache();
      
      // Xóa cache trong RAM
      imageCache.clear();
      imageCache.clearLiveImages();
      
      print('🗑️ Đã xóa cache hình ảnh (Disk & RAM)');
    } catch (e) {
      // Có thể lỗi nếu chưa import hoặc chưa dùng bao giờ, không sao
      print('⚠️ Lỗi xóa cache hình ảnh: $e');
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
          // Thông tin VIP
          'is_vip': data['is_vip'] ?? false,
          'plan_name': data['plan_name'] ?? 'Member',
          'expire_date': data['expire_date'],
          'storage': data['storage'], // Thông tin dung lượng
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
  // ==========================================
  // 📝 CẬP NHẬT THÔNG TIN USER (UPDATE PROFILE)
  // ==========================================
  Future<void> updateProfile({
    required String name,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      // ✅ Kiểm tra mạng trước khi gọi API
      final hasNetwork = await _networkService.checkConnectivity();
      if (!hasNetwork) {
        throw DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionTimeout,
            error: 'Không có kết nối mạng.');
      }

      print("🚀 Đang gọi API Update Profile...");

      // Lấy token để gắn vào header (Dio instance này chưa tự động gắn token cho mọi request)
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception("Bạn chưa đăng nhập");

      final options = Options(headers: {'Authorization': 'Bearer $token'});

      // 1. Cập nhật thông tin cơ bản (Tên)
      final profileUrl = '$baseUrl${ApiConfig.updateProfileEndpoint}';
      await _dio.post(
        profileUrl,
        data: {'full_name': name},
        options: options,
      );

      // 2. Đổi mật khẩu (nếu có)
      if (newPassword != null && newPassword.isNotEmpty) {
        if (currentPassword == null || currentPassword.isEmpty) {
          throw Exception('Vui lòng nhập mật khẩu hiện tại');
        }

        final passwordUrl = '$baseUrl${ApiConfig.changePasswordEndpoint}';
        await _dio.post(
          passwordUrl,
          data: {
            'current_password': currentPassword,
            'new_password': newPassword,
            'new_password_confirmation': newPassword,
          },
          options: options,
        );
      }
      
      // 3. Invalidate cache để load lại info mới
      await invalidateUserCache();
      
      print("✅ Cập nhật profile thành công");
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception("Lỗi cập nhật: $e");
    }
  }
}
