import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import 'dart:io';

import '../theme/app_colors.dart';
import '../blocs/downloaded_files_bloc.dart';
import '../blocs/home_bloc.dart';

import 'home/home_screen.dart';
import 'downloaded_files/downloaded_files_screen.dart';
import '../widgets/network_status_widget.dart';

/// Màn hình chính chứa Bottom Navigation Bar
/// Quản lý navigation giữa Home và Downloaded Files
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;

  // Double back to exit
  DateTime? _lastBackPressed;
  static const Duration _exitTimeWindow = Duration(seconds: 2);

  // ✅ LAZY LOADING: Track xem user đã vào tab Files chưa
  bool _hasVisitedFilesTab = false;

  // Animation controller for nav bar
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
    
    // ✅ AUTO RELOAD DATA: Khi vào màn hình chính (sau Login hoặc mở lại app)
    // Buộc reload History từ API để đảm bảo không hiển thị data cũ của user trước
    // HomeBloc là global nên cần call event này mỗi khi MainScreen được tạo lại
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeBloc>().add(LoadHistoryRequested(forceRefresh: true));
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
      // ✅ Đánh dấu đã visit tab Files khi user click lần đầu
      if (index == 1 && !_hasVisitedFilesTab) {
        _hasVisitedFilesTab = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Nếu đang ở tab Files, về tab Home trước
          if (_currentIndex == 1) {
            _onTabSelected(0);
            return;
          }

          final shouldExit = await _onWillPop();
          if (shouldExit && context.mounted) {
            if (Platform.isAndroid) {
              SystemNavigator.pop();
            } else if (Platform.isIOS) {
              exit(0);
            }
          }
        }
      },
      child: Scaffold(
        // ✅ LAZY LOADING: Sử dụng IndexedStack thay vì PageView
        // IndexedStack giữ state của children và chỉ hiển thị child hiện tại
        body: NetworkStatusBanner(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              const HomeScreen(),
              // ✅ LAZY LOADING: Chỉ tạo DownloadedFilesScreen khi user đã click tab
              if (_hasVisitedFilesTab)
                BlocProvider(
                  create: (context) => DownloadedFilesBloc(),
                  child: const DownloadedFilesScreen(),
                )
              else
              // Placeholder widget nhẹ khi chưa visit
                const SizedBox.shrink(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(isDark),
      ),
    );
  }

  Widget _buildBottomNavBar(bool isDark) {
    // Lấy localization
    final lang = AppLocalizations.of(context)!;

    // Màu tím đậm cho active state
    const Color activeColor = Color(0xFF6366F1); // Indigo-500
    final Color inactiveColor = isDark ? AppColors.grey500 : AppColors.grey400;

    return Container(
      // Full-width, không bo góc
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        // Shadow nhẹ ở cạnh trên
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Tab Trang chủ - với Flexible
              Flexible(
                child: _buildNavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: lang.navHome ?? 'Trang chủ',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  isDark: isDark,
                ),
              ),
              // Tab Tệp tin - với Flexible
              Flexible(
                child: _buildNavItem(
                  index: 1,
                  icon: Icons.folder_outlined,
                  activeIcon: Icons.folder_rounded,
                  label: lang.navFiles ?? 'Tệp tin',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
    required bool isDark,
  }) {
    final isActive = _currentIndex == index;
    final Color currentColor = isActive ? activeColor : inactiveColor;

    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon - với Flexible để tránh overflow
            Flexible(
              flex: 3,
              child: Icon(
                isActive ? activeIcon : icon,
                color: currentColor,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            // Label - với Flexible để tránh overflow
            Flexible(
              flex: 2,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: currentColor,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_lastBackPressed != null &&
        now.difference(_lastBackPressed!) < _exitTimeWindow) {
      return true;
    }

    _lastBackPressed = now;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.primaryGradientDark
                    : AppColors.primaryGradientLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.exit_to_app_rounded, color: AppColors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Nhấn lại để thoát',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.white : AppColors.grey900,
                ),
              ),
            ),
          ],
        ),
        duration: _exitTimeWindow,
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.grey850 : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? AppColors.grey700 : AppColors.grey200),
        ),
      ),
    );
    return false;
  }
}
