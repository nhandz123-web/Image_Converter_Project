import 'dart:async';
import 'package:flutter/material.dart';
import '../services/network_service.dart';

/// Widget hiển thị banner cảnh báo khi mất kết nối mạng
/// Tự động ẩn/hiện dựa trên trạng thái mạng
class NetworkStatusBanner extends StatefulWidget {
  final Widget child;
  
  const NetworkStatusBanner({
    super.key,
    required this.child,
  });
  
  @override
  State<NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends State<NetworkStatusBanner> 
    with SingleTickerProviderStateMixin {
  final NetworkService _networkService = NetworkService.getInstance();
  StreamSubscription<bool>? _networkSubscription;
  bool _isOffline = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Animation controller cho slide effect
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Kiểm tra trạng thái ban đầu
    _checkInitialStatus();
    
    // Lắng nghe thay đổi trạng thái mạng
    _networkSubscription = _networkService.onNetworkChange.listen((isOnline) {
      _updateOfflineStatus(!isOnline);
    });
  }
  
  Future<void> _checkInitialStatus() async {
    final hasNetwork = await _networkService.checkConnectivity();
    _updateOfflineStatus(!hasNetwork);
  }
  
  void _updateOfflineStatus(bool isOffline) {
    if (mounted && _isOffline != isOffline) {
      setState(() {
        _isOffline = isOffline;
        if (_isOffline) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    }
  }
  
  @override
  void dispose() {
    _networkSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Banner cảnh báo offline
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            if (!_isOffline && _animationController.isDismissed) {
              return const SizedBox.shrink();
            }
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value * 50),
              child: _buildOfflineBanner(context),
            );
          },
        ),
        // Nội dung chính
        Expanded(child: widget.child),
      ],
    );
  }
  
  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade600,
            Colors.red.shade800,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Không có kết nối mạng',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Một số tính năng có thể không hoạt động',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
                // Thử kết nối lại
                await _networkService.checkConnectivity();
              },
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
              ),
              tooltip: 'Thử lại',
            ),
          ],
        ),
      ),
    );
  }
}

/// Mixin để dễ dàng kiểm tra mạng trong các màn hình
mixin NetworkCheckMixin<T extends StatefulWidget> on State<T> {
  final NetworkService networkService = NetworkService.getInstance();
  
  /// Kiểm tra mạng và hiển thị thông báo nếu mất kết nối
  /// Returns: true nếu có mạng, false nếu không có mạng
  Future<bool> checkNetworkWithMessage({String? customMessage}) async {
    final hasNetwork = await networkService.checkConnectivity();
    
    if (!hasNetwork && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  customMessage ?? 'Không có kết nối mạng. Vui lòng kiểm tra internet của bạn.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Thử lại',
            textColor: Colors.white,
            onPressed: () async {
              await networkService.checkConnectivity();
            },
          ),
        ),
      );
    }
    
    return hasNetwork;
  }
  
  /// Thực hiện một tác vụ với kiểm tra mạng trước
  /// Nếu có mạng, thực thi [action]
  /// Nếu không có mạng, hiển thị thông báo và không thực thi
  Future<R?> executeWithNetworkCheck<R>({
    required Future<R> Function() action,
    String? noNetworkMessage,
    VoidCallback? onNoNetwork,
  }) async {
    final hasNetwork = await checkNetworkWithMessage(customMessage: noNetworkMessage);
    
    if (!hasNetwork) {
      onNoNetwork?.call();
      return null;
    }
    
    return await action();
  }
}
