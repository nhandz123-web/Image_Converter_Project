import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service quản lý kiểm tra kết nối mạng
/// Cung cấp các phương thức để:
/// - Kiểm tra trạng thái mạng hiện tại
/// - Lắng nghe thay đổi trạng thái mạng
/// - Wrapper để gọi API với kiểm tra mạng tự động
class NetworkService {
  static NetworkService? _instance;
  
  final Connectivity _connectivity = Connectivity();
  
  // Stream controller để broadcast trạng thái mạng
  final StreamController<bool> _networkStatusController = 
      StreamController<bool>.broadcast();
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // Trạng thái online hiện tại
  bool _isOnline = true;
  
  NetworkService._internal() {
    _initConnectivityListener();
  }
  
  /// Singleton pattern - lấy instance duy nhất
  static NetworkService getInstance() {
    _instance ??= NetworkService._internal();
    return _instance!;
  }
  
  /// Stream để lắng nghe thay đổi trạng thái mạng
  Stream<bool> get onNetworkChange => _networkStatusController.stream;
  
  /// Kiểm tra có đang online không (cached value)
  bool get isOnline => _isOnline;
  
  /// Khởi tạo listener cho connectivity changes
  void _initConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final isConnected = await _checkRealConnectivity(results);
        _updateNetworkStatus(isConnected);
      },
    );
    
    // Kiểm tra trạng thái ban đầu
    _checkInitialConnectivity();
  }
  
  /// Kiểm tra trạng thái mạng ban đầu khi khởi tạo service
  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final isConnected = await _checkRealConnectivity(results);
      _updateNetworkStatus(isConnected);
    } catch (e) {
      debugPrint('⚠️ Lỗi kiểm tra kết nối ban đầu: $e');
      _isOnline = true; // Assume online nếu có lỗi
    }
  }
  
  /// Kiểm tra kết nối thực sự (có thể có WiFi nhưng không có internet)
  Future<bool> _checkRealConnectivity(List<ConnectivityResult> results) async {
    // Nếu không có kết nối nào
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return false;
    }
    
    // Có kết nối (WiFi, Mobile, Ethernet...)
    return true;
  }
  
  /// Cập nhật trạng thái mạng và notify listeners
  void _updateNetworkStatus(bool isConnected) {
    if (_isOnline != isConnected) {
      _isOnline = isConnected;
      _networkStatusController.add(isConnected);
      
      if (isConnected) {
        debugPrint('✅ Đã kết nối mạng');
      } else {
        debugPrint('❌ Mất kết nối mạng');
      }
    }
  }
  
  /// Kiểm tra kết nối mạng hiện tại
  /// Returns: true nếu có kết nối, false nếu không
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = await _checkRealConnectivity(results);
      return _isOnline;
    } catch (e) {
      debugPrint('⚠️ Lỗi checkConnectivity: $e');
      return true; // Assume online nếu có lỗi (để không block user)
    }
  }
  
  /// Wrapper để thực hiện API call với kiểm tra mạng
  /// Nếu không có mạng, throw NetworkException
  /// 
  /// Ví dụ:
  /// ```dart
  /// final result = await networkService.executeWithNetworkCheck(() async {
  ///   return await documentService.getHistory();
  /// });
  /// ```
  Future<T> executeWithNetworkCheck<T>(Future<T> Function() apiCall) async {
    final hasConnection = await checkConnectivity();
    
    if (!hasConnection) {
      throw NetworkException('Không có kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn.');
    }
    
    return await apiCall();
  }
  
  /// Kiểm tra mạng và throw exception nếu không có kết nối
  /// Dùng khi muốn kiểm tra mạng trước một loạt operations
  Future<void> ensureConnectivity() async {
    final hasConnection = await checkConnectivity();
    
    if (!hasConnection) {
      throw NetworkException('Không có kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn.');
    }
  }
  
  /// Lấy loại kết nối hiện tại (WiFi, Mobile, Ethernet...)
  Future<String> getConnectionType() async {
    try {
      final results = await _connectivity.checkConnectivity();
      
      if (results.contains(ConnectivityResult.wifi)) {
        return 'WiFi';
      } else if (results.contains(ConnectivityResult.mobile)) {
        return 'Mạng di động';
      } else if (results.contains(ConnectivityResult.ethernet)) {
        return 'Ethernet';
      } else if (results.contains(ConnectivityResult.vpn)) {
        return 'VPN';
      } else if (results.contains(ConnectivityResult.none)) {
        return 'Không có kết nối';
      } else {
        return 'Khác';
      }
    } catch (e) {
      return 'Không xác định';
    }
  }
  
  /// Dispose service khi không dùng nữa
  void dispose() {
    _connectivitySubscription?.cancel();
    _networkStatusController.close();
  }
}

/// Exception khi không có kết nối mạng
class NetworkException implements Exception {
  final String message;
  
  NetworkException(this.message);
  
  @override
  String toString() => message;
}
