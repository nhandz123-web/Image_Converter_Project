import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import '../models/vip_package_model.dart';
import 'vip_service.dart';

/// Enum trạng thái mua hàng
enum IapPurchaseStatus {
  idle,
  loading,
  purchasing,
  verifying,
  success,
  error,
  cancelled,
  restored,
}

/// Callback khi có thay đổi trạng thái
typedef IapStatusCallback = void Function(IapPurchaseStatus status, String? message);

/// Service xử lý In-App Purchase
/// Singleton pattern để đảm bảo chỉ có 1 instance xử lý purchase stream
class IapService {
  static IapService? _instance;
  
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final VipService _vipService = VipService.getInstance();
  
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isInitialized = false;
  
  // Callbacks
  IapStatusCallback? onStatusChanged;
  VoidCallback? onPurchaseSuccess;
  

  
  IapService._();
  
  static IapService getInstance() {
    _instance ??= IapService._();
    return _instance!;
  }
  
  /// Khởi tạo IAP Service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      
      if (!_isAvailable) {
        print('⚠️ In-App Purchase không khả dụng trên thiết bị này');
        return;
      }
      
      // Lắng nghe purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: _onPurchaseDone,
        onError: _onPurchaseError,
      );
      
      // Cấu hình platform-specific
      if (Platform.isIOS) {
        final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
            _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
      }
      
      _isInitialized = true;
      print('✅ IAP Service đã khởi tạo thành công');
      
    } catch (e) {
      print('❌ Lỗi khởi tạo IAP: $e');
    }
  }
  
  /// Load products từ Store (Google Play / App Store)
  Future<List<ProductDetails>> loadProducts(List<VipPackage> packages) async {
    if (!_isAvailable) {
      print('⚠️ Store không khả dụng');
      return [];
    }
    
    try {
      // Lấy danh sách product IDs từ packages
      final Set<String> productIds = packages
          .where((p) => p.productId.isNotEmpty)
          .map((p) => p.productId)
          .toSet();
      
      if (productIds.isEmpty) {
        print('⚠️ Không có product ID nào');
        return [];
      }
      
      print('🔄 Đang load products: $productIds');
      
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.error != null) {
        print('❌ Lỗi query products: ${response.error!.message}');
        return [];
      }
      
      if (response.notFoundIDs.isNotEmpty) {
        print('⚠️ Không tìm thấy products: ${response.notFoundIDs}');
      }
      
      _products = response.productDetails;
      print('✅ Đã load ${_products.length} products từ Store');
      
      return _products;
      
    } catch (e) {
      print('❌ Lỗi load products: $e');
      return [];
    }
  }
  
  /// Bắt đầu quá trình mua hàng
  Future<bool> purchasePackage(VipPackage package) async {
    if (!_isAvailable) {
      onStatusChanged?.call(IapPurchaseStatus.error, 'Store không khả dụng');
      return false;
    }
    
    try {
      // Tìm product tương ứng
      ProductDetails? product;
      for (final p in _products) {
        if (p.id == package.productId) {
          product = p;
          break;
        }
      }
      
      if (product == null) {
        onStatusChanged?.call(
          IapPurchaseStatus.error, 
          'Không tìm thấy sản phẩm ${package.productId}',
        );
        return false;
      }
      
      
      onStatusChanged?.call(IapPurchaseStatus.purchasing, 'Đang xử lý thanh toán...');
      
      // Tạo purchase param
      late PurchaseParam purchaseParam;
      
      if (Platform.isAndroid) {
        // Android - consumable product
        purchaseParam = GooglePlayPurchaseParam(
          productDetails: product,
          changeSubscriptionParam: null,
        );
      } else {
        // iOS
        purchaseParam = PurchaseParam(productDetails: product);
      }
      
      // Thực hiện mua
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      
      if (!success) {
        onStatusChanged?.call(IapPurchaseStatus.error, 'Không thể bắt đầu thanh toán');
        return false;
      }
      
      return true;
      
    } catch (e) {
      print('❌ Lỗi mua hàng: $e');
      onStatusChanged?.call(IapPurchaseStatus.error, 'Lỗi: $e');
      return false;
    }
  }
  
  /// Khôi phục các gói đã mua (iOS)
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    
    try {
      onStatusChanged?.call(IapPurchaseStatus.loading, 'Đang khôi phục...');
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      print('❌ Lỗi restore: $e');
      onStatusChanged?.call(IapPurchaseStatus.error, 'Không thể khôi phục');
    }
  }
  
  /// Xử lý purchase updates từ stream
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchase in purchaseDetailsList) {
      _handlePurchase(purchase);
    }
  }
  
  /// Xử lý từng purchase
  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    print('📦 Purchase update: ${purchase.productID} - ${purchase.status}');
    
    switch (purchase.status) {
      case PurchaseStatus.pending:
        onStatusChanged?.call(IapPurchaseStatus.purchasing, 'Đang chờ xác nhận...');
        break;
        
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // Xác thực với server
        await _verifyAndDeliverPurchase(purchase);
        break;
        
      case PurchaseStatus.error:
        onStatusChanged?.call(
          IapPurchaseStatus.error, 
          purchase.error?.message ?? 'Thanh toán thất bại',
        );
        break;
        
      case PurchaseStatus.canceled:
        onStatusChanged?.call(IapPurchaseStatus.cancelled, 'Đã hủy thanh toán');
        break;
    }
    
    // Complete purchase (quan trọng!)
    if (purchase.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchase);
    }
  }
  
  /// Xác thực purchase với server và kích hoạt VIP
  Future<void> _verifyAndDeliverPurchase(PurchaseDetails purchase) async {
    try {
      onStatusChanged?.call(IapPurchaseStatus.verifying, 'Đang xác thực...');
      
      // Lấy purchase token/receipt
      String purchaseToken = '';
      String? orderId;
      
      if (Platform.isAndroid) {
        final GooglePlayPurchaseDetails googlePurchase = 
            purchase as GooglePlayPurchaseDetails;
        purchaseToken = googlePurchase.verificationData.serverVerificationData;
        orderId = googlePurchase.billingClientPurchase.orderId;
      } else if (Platform.isIOS) {
        final AppStorePurchaseDetails applePurchase = 
            purchase as AppStorePurchaseDetails;
        purchaseToken = applePurchase.verificationData.serverVerificationData;
      }
      
      // Gọi API verify với server
      final result = await _vipService.verifyPurchase(
        platform: Platform.isIOS ? 'ios' : 'android',
        productId: purchase.productID,
        purchaseToken: purchaseToken,
        orderId: orderId,
      );
      
      if (result['success'] == true) {
        onStatusChanged?.call(
          purchase.status == PurchaseStatus.restored 
              ? IapPurchaseStatus.restored 
              : IapPurchaseStatus.success,
          result['message'] ?? 'Nâng cấp VIP thành công!',
        );
        onPurchaseSuccess?.call();
      } else {
        onStatusChanged?.call(
          IapPurchaseStatus.error,
          result['message'] ?? 'Xác thực thất bại',
        );
      }
      
    } catch (e) {
      print('❌ Lỗi verify purchase: $e');
      onStatusChanged?.call(IapPurchaseStatus.error, 'Lỗi xác thực: $e');
    }
  }
  
  void _onPurchaseDone() {
    print('📦 Purchase stream done');
    _subscription?.cancel();
  }
  
  void _onPurchaseError(dynamic error) {
    print('❌ Purchase stream error: $error');
    onStatusChanged?.call(IapPurchaseStatus.error, 'Lỗi kết nối Store');
  }
  
  /// Kiểm tra store có khả dụng không
  bool get isAvailable => _isAvailable;
  
  /// Lấy danh sách products đã load
  List<ProductDetails> get products => _products;
  
  /// Lấy giá hiển thị từ Store (đã format theo locale)
  String? getStorePrice(String productId) {
    try {
      final product = _products.firstWhere((p) => p.id == productId);
      return product.price;
    } catch (e) {
      return null;
    }
  }
  
  /// Dispose service
  void dispose() {
    _subscription?.cancel();
    _isInitialized = false;
  }
}

/// Delegate cho iOS Payment Queue (xử lý các trường hợp đặc biệt)
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
