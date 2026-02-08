/// Cấu hình API cho toàn bộ ứng dụng
/// Tập trung quản lý baseUrl và các timeout settings
///
/// ⚠️ LƯU Ý: Thay đổi IP này khi deploy hoặc test trên thiết bị khác
class ApiConfig {
  // ═══════════════════════════════════════════════════════════════
  //                    BASE URL CONFIGURATION
  // ═══════════════════════════════════════════════════════════════

  /// Base URL của server (không có /api)
  /// - Máy ảo Android: 10.0.2.2
  /// - Máy thật: IP LAN của máy tính (VD: 192.168.1.x, 10.85.33.12)
  static const String host = '192.168.1.8';
  static const int port = 8000;

  /// Base URL đầy đủ (không có /api)
  static const String baseUrl = 'http://$host:$port';

  /// API URL (có /api)
  static const String apiUrl = '$baseUrl/api';

  /// Storage URL (để truy cập file đã upload)
  static const String storageUrl = '$baseUrl/storage';

  // ═══════════════════════════════════════════════════════════════
  //                    TIMEOUT CONFIGURATION
  // ═══════════════════════════════════════════════════════════════

  /// Timeout kết nối
  static const Duration connectTimeout = Duration(seconds: 10);

  /// Timeout nhận dữ liệu
  static const Duration receiveTimeout = Duration(seconds: 10);

  /// Timeout gửi dữ liệu (cho upload file)
  static const Duration sendTimeout = Duration(seconds: 60);

  // ═══════════════════════════════════════════════════════════════
  //                    HTTP HEADERS
  // ═══════════════════════════════════════════════════════════════

  /// Headers mặc định cho API requests
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// Tạo headers với Bearer token
  static Map<String, String> authHeaders(String token) {
    return {
      ...defaultHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  // ═══════════════════════════════════════════════════════════════
  //                    API ENDPOINTS
  // ═══════════════════════════════════════════════════════════════

  /// Auth endpoints
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String getUserEndpoint = '/get_user';
  static const String updateProfileEndpoint = '/v1/updateprofile';
  static const String changePasswordEndpoint = '/change-password';

  /// Document endpoints
  static const String documentsEndpoint = '/'; // GET /api/ để lấy list
  static const String mergeEndpoint = '/merge';
  static const String qualityPresetsEndpoint = '/quality-presets';

  /// File endpoints (với file ID)
  static String filePreviewEndpoint(int id) => '/files/$id/preview';
  static String fileStreamEndpoint(int id) => '/files/$id/stream';
  static String fileDownloadEndpoint(int id) => '/files/$id/download';
  static String fileInfoEndpoint(int id) => '/files/$id/info';
  static String fileDeleteEndpoint(int id) => '/$id';
  static String fileRenameEndpoint(int id) => '/$id';
}
