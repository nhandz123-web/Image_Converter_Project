import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../services/document_service.dart';
import '../blocs/auth_bloc.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DocumentService _documentService = DocumentService();

  // Biến lưu dữ liệu dung lượng
  bool _isLoading = true;
  int _usedBytes = 0;
  int _totalBytes = 1073741824; // Mặc định 1GB nếu chưa load được
  double _percent = 0.0;
  String _name = "Đang tải...";
  String _email = "";

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      // 1. Gọi API lấy dung lượng
      final storageData = await _documentService.getStorageUsage();

      // 2. Gọi API lấy thông tin User
      final userData = await _documentService.getUserInfo();

      if (mounted) {
        setState(() {
          // Cập nhật dung lượng
          _usedBytes = storageData['used_bytes'];
          _totalBytes = storageData['total_bytes'];
          _percent = (storageData['percentage'] ?? 0) / 100.0;

          // Cập nhật Tên & Email thật
          _name = userData['name'];
          _email = userData['email'];

          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hàm format số bytes sang MB/GB cho dễ đọc
  String formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + ' ' + suffixes[i];
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Logic màu sắc thanh tiến trình
    Color progressColor = _percent > 0.9 ? Colors.red : Colors.orange;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoggedOut) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        // --- AppBar với Gradient và Title ---
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text(
            lang.myProfile ?? "Hồ sơ của tôi",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Color(0xFF1A237E), Color(0xFF0D47A1)]
                    : [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // --- HEADER với Gradient cho cả Light & Dark mode ---
              Container(
                padding: EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Color(0xFF1A237E), Color(0xFF0D47A1)] // Gradient xanh đậm cho Dark mode
                        : [Colors.blue[400]!, Colors.purple[400]!], // Gradient xanh-tím cho Light mode
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, size: 50, color: theme.primaryColor),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _isLoading ? (lang.loading ?? "Đang tải...") : _name,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      _email,
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // --- THANH DUNG LƯỢNG (DATA THẬT) - ĐÃ SỬA MÀU ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lang.storageUsed ?? "Dung lượng đã dùng",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black, // Đảm bảo hiển thị rõ
                            ),
                          ),
                          _isLoading
                              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(
                            "${formatBytes(_usedBytes, 2)} / ${formatBytes(_totalBytes, 0)}",
                            style: TextStyle(
                              color: isDark ? Colors.blue[300] : theme.primaryColor, // Sáng hơn trong dark mode
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _isLoading
                            ? LinearProgressIndicator(minHeight: 10)
                            : LinearProgressIndicator(
                          value: _percent,
                          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200], // Nền tối hơn trong dark mode
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                          minHeight: 10,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _isLoading
                            ? (lang.calculating ?? "Đang tính toán...")
                            : "${lang.youHaveUsed ?? "Bạn đã dùng"} ${(_percent * 100).toStringAsFixed(1)}% ${lang.storage ?? "dung lượng"}.",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600], // Sáng hơn trong dark mode
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // --- MENU ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildProfileItem(
                      context,
                      lang: lang,
                      theme: theme,
                      icon: Icons.person_outline,
                      title: lang.editProfile ?? "Chỉnh sửa thông tin",
                      color: Colors.blue,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(currentName: _name),
                          ),
                        );
                        if (result == true) {
                          _loadAllData();
                        }
                      },
                    ),
                    _buildProfileItem(
                      context,
                      lang: lang,
                      theme: theme,
                      icon: Icons.settings_outlined,
                      title: lang.appSettings ?? "Cài đặt ứng dụng",
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SettingsScreen()),
                        );
                      },
                    ),
                    _buildProfileItem(
                      context,
                      lang: lang,
                      theme: theme,
                      icon: Icons.help_outline,
                      title: lang.helpAndSupport ?? "Trợ giúp & Hỗ trợ",
                      color: Colors.orange,
                      onTap: () {},
                    ),
                    SizedBox(height: 20),
                    _buildProfileItem(
                      context,
                      lang: lang,
                      theme: theme,
                      icon: Icons.logout,
                      title: lang.logout ?? "Đăng xuất",
                      color: Colors.red,
                      isDestructive: true,
                      onTap: () {
                        _showLogoutDialog(context, lang);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(
      BuildContext context, {
        required AppLocalizations lang,
        required ThemeData theme,
        required IconData icon,
        required String title,
        required Color color,
        required VoidCallback onTap,
        bool isDestructive = false,
      }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 10),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: isDestructive ? Colors.red : null),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  // Dialog xác nhận đăng xuất
  void _showLogoutDialog(BuildContext context, AppLocalizations lang) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          lang.confirmLogout ?? "Xác nhận đăng xuất",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          lang.logoutMessage ?? "Bạn có chắc chắn muốn đăng xuất?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              lang.cancel ?? "Hủy",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              lang.logout ?? "Đăng xuất",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}