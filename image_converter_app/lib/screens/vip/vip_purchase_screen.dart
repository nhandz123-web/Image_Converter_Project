import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/vip_package_model.dart';
import '../../services/vip_service.dart';
import '../../services/iap_service.dart';
import '../../theme/app_colors.dart';

/// Màn hình mua gói VIP - Hiển thị khi user chưa VIP nhấn vào biểu tượng vương miện
class VipPurchaseScreen extends StatefulWidget {
  const VipPurchaseScreen({super.key});

  @override
  State<VipPurchaseScreen> createState() => _VipPurchaseScreenState();
}

class _VipPurchaseScreenState extends State<VipPurchaseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  int? _selectedPackageId;
  bool _isLoading = false;
  bool _isLoadingPackages = true;
  String? _errorMessage;
  String? _purchaseStatusMessage;
  
  // Danh sách gói VIP từ API
  List<VipPackage> _packages = [];
  
  // Services
  final VipService _vipService = VipService.getInstance();
  final IapService _iapService = IapService.getInstance();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Setup IAP callbacks
    _setupIapCallbacks();
    
    // Load packages từ API
    _loadPackages();
  }
  
  void _setupIapCallbacks() {
    _iapService.onStatusChanged = (status, message) {
      if (!mounted) return;
      
      setState(() {
        _purchaseStatusMessage = message;
        
        switch (status) {
          case IapPurchaseStatus.purchasing:
          case IapPurchaseStatus.verifying:
          case IapPurchaseStatus.loading:
            _isLoading = true;
            break;
            
          case IapPurchaseStatus.success:
          case IapPurchaseStatus.restored:
            _isLoading = false;
            _showSuccessDialog(message ?? 'Nâng cấp VIP thành công!');
            break;
            
          case IapPurchaseStatus.error:
            _isLoading = false;
            _showErrorSnackBar(message ?? 'Đã có lỗi xảy ra');
            break;
            
          case IapPurchaseStatus.cancelled:
            _isLoading = false;
            break;
            
          case IapPurchaseStatus.idle:
            _isLoading = false;
            break;
        }
      });
    };
    
    _iapService.onPurchaseSuccess = () {
      // Có thể navigate về hoặc reload VIP status
      if (mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context, true); // Return true = đã mua thành công
        });
      }
    };
    
    // Khởi tạo IAP
    _iapService.initialize();
  }

  Future<void> _loadPackages() async {
    setState(() {
      _isLoadingPackages = true;
      _errorMessage = null;
    });
    
    try {
      // Xác định platform
      final platform = Platform.isIOS ? 'ios' : 'android';
      
      final packages = await _vipService.getPackages(platform: platform);
      
      if (mounted) {
        setState(() {
          _packages = packages;
          _isLoadingPackages = false;
          
          // Auto-select gói đầu tiên nếu có
          if (packages.isNotEmpty && _selectedPackageId == null) {
            // Tìm gói popular (gói có title chứa "tiết kiệm" hoặc index 1)
            final popularIndex = packages.indexWhere(
              (p) => p.title.toLowerCase().contains('tiết kiệm'),
            );
            if (popularIndex != -1) {
              _selectedPackageId = packages[popularIndex].id;
            }
          }
        });
        
        _animationController.forward();
        
        // Load products từ Store (Google Play / App Store)
        if (packages.isNotEmpty) {
          await _iapService.loadProducts(packages);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPackages = false;
          _errorMessage = 'Không thể tải danh sách gói VIP. Vui lòng thử lại.';
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.backgroundGradientDark
              : AppColors.backgroundGradientLight,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark),
              Expanded(
                child: _isLoadingPackages
                    ? _buildLoadingState(isDark)
                    : _errorMessage != null
                        ? _buildErrorState(isDark)
                        : _buildContent(isDark),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: _packages.isEmpty || _isLoadingPackages
          ? null
          : _buildBottomButton(context, isDark),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.crownGold,
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tải danh sách gói VIP...',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Đã có lỗi xảy ra',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPackages,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crownGold,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildPromoBanner(isDark),
                  const SizedBox(height: 24),
                  ..._packages.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildPackageCard(
                        context,
                        entry.value,
                        isDark,
                        index: entry.key,
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  _buildGuaranteeSection(isDark),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.appBarGradientDark
            : AppColors.appBarGradientLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Nâng cấp VIP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildPromoBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.crownGold.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Crown icon with glow
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '✨ Mở khóa toàn bộ tính năng ✨',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chuyển đổi file không giới hạn, dung lượng lớn hơn',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(
    BuildContext context,
    VipPackage package,
    bool isDark, {
    required int index,
  }) {
    final isSelected = _selectedPackageId == package.id;
    final isPopular = package.title.toLowerCase().contains('tiết kiệm');
    final isPro = package.title.toLowerCase().contains('pro');
    
    // Màu sắc cho từng loại gói
    Color accentColor;
    List<Color> gradientColors;
    
    if (package.title.toLowerCase().contains('siêu vip')) {
      // Siêu VIP Pro - màu tím đậm
      accentColor = const Color(0xFF8B5CF6);
      gradientColors = [const Color(0xFF8B5CF6), const Color(0xFFA855F7)];
    } else if (isPro) {
      // VIP Pro - màu xanh dương
      accentColor = const Color(0xFF3B82F6);
      gradientColors = [const Color(0xFF3B82F6), const Color(0xFF60A5FA)];
    } else if (isPopular) {
      // Siêu tiết kiệm - màu xanh lá
      accentColor = const Color(0xFF10B981);
      gradientColors = [const Color(0xFF10B981), const Color(0xFF34D399)];
    } else {
      // VIP 1 - màu vàng
      accentColor = AppColors.crownGold;
      gradientColors = [AppColors.crownGold, const Color(0xFFFFA500)];
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackageId = package.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: isSelected ? 20 : 10,
              offset: const Offset(0, 4),
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Popular badge
            if (isPopular)
              Positioned(
                top: 0,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'PHỔ BIẾN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      // Package icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradientColors),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      
                      // Title and duration
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              package.title,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                package.formattedDuration,
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            package.formattedPrice,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (package.timeMonths > 1)
                            Text(
                              package.formattedPricePerMonth,
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black45,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Benefits list
                  ...package.benefits.take(5).map((benefit) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradientColors),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              benefit,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  // Show more benefits hint
                  if (package.benefits.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${package.benefits.length - 5} quyền lợi khác',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Selection indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 44,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(colors: gradientColors)
                          : null,
                      color: isSelected
                          ? null
                          : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
                      borderRadius: BorderRadius.circular(12),
                      border: !isSelected
                          ? Border.all(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.1),
                            )
                          : null,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white54 : Colors.black45),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isSelected ? 'Đã chọn' : 'Chọn gói này',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black54),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuaranteeSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_rounded,
                color: AppColors.softGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Cam kết từ chúng tôi',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGuaranteeItem(
                  Icons.security_rounded,
                  'Bảo mật',
                  'Thanh toán an toàn',
                  isDark,
                ),
              ),
              Expanded(
                child: _buildGuaranteeItem(
                  Icons.support_agent_rounded,
                  'Hỗ trợ 24/7',
                  'Luôn sẵn sàng',
                  isDark,
                ),
              ),
              Expanded(
                child: _buildGuaranteeItem(
                  Icons.autorenew_rounded,
                  'Hoàn tiền',
                  'Trong 7 ngày',
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuaranteeItem(
    IconData icon,
    String title,
    String subtitle,
    bool isDark,
  ) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.softBlue.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.softBlue, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black45,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context, bool isDark) {
    final selectedPackage = _packages.cast<VipPackage?>().firstWhere(
      (p) => p?.id == _selectedPackageId,
      orElse: () => null,
    );

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected package info
          if (selectedPackage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedPackage.title,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    selectedPackage.formattedPrice,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          // Purchase button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: selectedPackage == null || _isLoading
                  ? null
                  : () => _handlePurchase(selectedPackage),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crownGold,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark ? Colors.white12 : Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: selectedPackage != null ? 8 : 0,
                shadowColor: AppColors.crownGold.withValues(alpha: 0.5),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.workspace_premium_rounded, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          selectedPackage != null
                              ? 'Mua ngay'
                              : 'Chọn gói VIP để tiếp tục',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          // Terms text
          const SizedBox(height: 12),
          Text(
            'Bằng việc mua, bạn đồng ý với Điều khoản sử dụng',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handlePurchase(VipPackage package) async {
    // Kiểm tra product ID có hợp lệ không
    if (package.productId.isEmpty) {
      _showErrorSnackBar('Gói này chưa được cấu hình để thanh toán');
      return;
    }
    
    // Kiểm tra store có khả dụng không
    if (!_iapService.isAvailable) {
      _showErrorSnackBar('Cửa hàng không khả dụng trên thiết bị này');
      return;
    }
    
    // Lấy giá từ store (nếu có)
    final storePrice = _iapService.getStorePrice(package.productId);
    final displayPrice = storePrice ?? package.formattedPrice;
    
    // Hiển thị dialog xác nhận
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700)),
            SizedBox(width: 8),
            Text('Xác nhận mua'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gói: ${package.title}'),
            Text('Thời hạn: ${package.formattedDuration}'),
            Text('Giá: $displayPrice'),
            const SizedBox(height: 16),
            Text(
              'Thanh toán qua ${Platform.isIOS ? "App Store" : "Google Play"}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initiateIAPPurchase(package);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.white,
            ),
            child: const Text('Thanh toán'),
          ),
        ],
      ),
    );
  }
  
  /// Khởi tạo quá trình mua IAP
  Future<void> _initiateIAPPurchase(VipPackage package) async {
    // Gọi IapService để bắt đầu mua
    final success = await _iapService.purchasePackage(package);
    
    if (!success && mounted) {
      // Nếu không thể bắt đầu mua, hiển thị lỗi
      _showErrorSnackBar('Không thể bắt đầu thanh toán. Vui lòng thử lại.');
    }
    // Nếu thành công, các callback trong _setupIapCallbacks sẽ xử lý tiếp
  }
  
  /// Hiển thị dialog thành công
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nâng cấp thành công!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Đóng dialog
                  Navigator.pop(this.context, true); // Quay về màn hình trước
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Tuyệt vời!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Hiển thị lỗi
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
