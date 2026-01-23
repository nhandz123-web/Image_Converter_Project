import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/vip_package_model.dart';
import 'network_service.dart';

/// Service xử lý các API liên quan đến VIP/IAP
class VipService {
  static VipService? _instance;
  
  final String baseUrl = ApiConfig.apiUrl;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    headers: ApiConfig.defaultHeaders,
  ));
  
  final _storage = const FlutterSecureStorage();
  final NetworkService _networkService = NetworkService.getInstance();
  
  VipService._();
  
  static VipService getInstance() {
    _instance ??= VipService._();
    return _instance!;
  }
  
  // ═══════════════════════════════════════════════════════════════
  //                    LẤY DANH SÁCH GÓI VIP
  // ═══════════════════════════════════════════════════════════════
  
  /// Lấy danh sách các gói VIP từ server
  /// [platform] - 'android' hoặc 'ios' để lấy đúng product_id
  Future<List<VipPackage>> getPackages({String platform = 'android'}) async {
    try {
      // Kiểm tra mạng
      final hasNetwork = await _networkService.checkConnectivity();
      if (!hasNetwork) {
        print('❌ Không có kết nối mạng khi lấy packages');
        return [];
      }
      
      print('🚀 Đang gọi API Get Packages: $baseUrl/v1/iap/packages?platform=$platform');
      
      final response = await _dio.get(
        '$baseUrl/v1/iap/packages',
        queryParameters: {'platform': platform},
      );
      
      print('✅ Phản hồi Get Packages: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> packagesJson = response.data['data'];
        return packagesJson
            .map((json) => VipPackage.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    } on DioException catch (e) {
      print('❌ Lỗi Dio khi lấy packages: ${e.message}');
      return [];
    } catch (e) {
      print('❌ Lỗi không xác định khi lấy packages: $e');
      return [];
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  //                    XÁC THỰC MUA HÀNG (IAP)
  // ═══════════════════════════════════════════════════════════════
  
  /// Xác thực giao dịch mua hàng IAP với server
  /// Returns: Map với success và message
  Future<Map<String, dynamic>> verifyPurchase({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? orderId,
  }) async {
    try {
      // Kiểm tra mạng
      final hasNetwork = await _networkService.checkConnectivity();
      if (!hasNetwork) {
        return {
          'success': false,
          'message': 'Không có kết nối mạng. Vui lòng thử lại.',
        };
      }
      
      // Lấy token
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        return {
          'success': false,
          'message': 'Bạn cần đăng nhập để thực hiện thanh toán.',
        };
      }
      
      print('🚀 Đang gọi API Verify Purchase: $baseUrl/v1/iap/verify');
      
      final response = await _dio.post(
        '$baseUrl/v1/iap/verify',
        data: {
          'platform': platform,
          'product_id': productId,
          'purchase_token': purchaseToken,
          'order_id': orderId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      
      print('✅ Phản hồi Verify Purchase: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Nâng cấp VIP thành công!',
          'data': response.data['data'],
        };
      }
      
      return {
        'success': false,
        'message': response.data['message'] ?? 'Xác thực giao dịch thất bại.',
      };
    } on DioException catch (e) {
      print('❌ Lỗi Dio khi verify purchase: ${e.message}');
      
      String errorMessage = 'Lỗi kết nối server.';
      if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response!.data['message'];
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('❌ Lỗi không xác định khi verify purchase: $e');
      return {
        'success': false,
        'message': 'Lỗi hệ thống: $e',
      };
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  //                    LẤY THÔNG TIN VIP USER
  // ═══════════════════════════════════════════════════════════════
  
  /// Lấy thông tin VIP của user hiện tại
  /// Returns: Map với is_vip, plan_name, expire_date hoặc null nếu lỗi
  Future<Map<String, dynamic>?> getVipStatus() async {
    try {
      // Lấy token
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        return null;
      }
      
      print('🚀 Đang lấy VIP status từ API Get User');
      
      final response = await _dio.get(
        '$baseUrl/get_user',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        return {
          'is_vip': data['is_vip'] ?? false,
          'plan_name': data['plan_name'] ?? 'Member',
          'expire_date': data['expire_date'],
        };
      }
      
      return null;
    } catch (e) {
      print('❌ Lỗi lấy VIP status: $e');
      return null;
    }
  }
}
