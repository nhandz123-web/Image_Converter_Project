import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/home_bloc.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'file_detail_screen.dart';
import 'all_documents_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(LoadHistoryRequested());
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Danh sách các tính năng với đa ngôn ngữ
    final List<Map<String, dynamic>> tools = [
      {
        'id': 'img_to_pdf',
        'name': lang.imageToPdf ?? "Ảnh sang PDF",
        'icon': Icons.image_rounded,
        'color': Colors.redAccent
      },
      {
        'id': 'word_to_pdf',
        'name': lang.wordToPdf ?? "Word sang PDF",
        'icon': Icons.description_rounded,
        'color': Colors.blue
      },
      {
        'id': 'excel_to_pdf',
        'name': lang.excelToPdf ?? "Excel sang PDF",
        'icon': Icons.table_chart_rounded,
        'color': Colors.green
      },
      {
        'id': 'qr_scan',
        'name': lang.qrScan ?? "Quét mã QR",
        'icon': Icons.qr_code_scanner_rounded,
        'color': Colors.orange
      },
      {
        'id': 'merge_pdf',
        'name': lang.mergePdf ?? "Ghép file PDF",
        'icon': Icons.merge_type_rounded,
        'color': Colors.purple
      },
      {
        'id': 'compress',
        'name': lang.compressData ?? "Nén dữ liệu",
        'icon': Icons.compress_rounded,
        'color': Colors.teal
      },
    ];

    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is HomeSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          context.read<HomeBloc>().add(LoadHistoryRequested());
        }
        if (state is HomeFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        bool isLoading = state is HomeLoading;

        return Scaffold(
          backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.grey[50],
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // App Bar hiện đại với gradient - KHÔNG DÃN RA
                  SliverAppBar(
                    floating: false,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: theme.primaryColor,
                    toolbarHeight: 70,
                    flexibleSpace: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [Color(0xFF1A237E), Color(0xFF0D47A1)]
                              : [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang.pdfTools ?? "Công cụ PDF",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                              IconButton(
                                // Đổi thành icon hình người/tài khoản cho đúng ý nghĩa Profile
                                icon: Icon(Icons.manage_accounts_rounded, size: 30, color: Colors.white),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Nội dung chính
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome card
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [Colors.blue[900]!, Colors.blue[700]!]
                                    : [Colors.blue[400]!, Colors.purple[400]!],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lang.welcomeMessage ?? "Chào mừng bạn!",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        lang.chooseToolBelow ?? "Chọn công cụ bên dưới để bắt đầu",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.touch_app_rounded,
                                  size: 50,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          // Tiêu đề công cụ
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                lang.popularTools ?? "Công cụ phổ biến",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),

                          // Grid chức năng
                          GridView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: tools.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            itemBuilder: (context, index) {
                              return _buildToolCard(tools[index], theme, lang);
                            },
                          ),

                          SizedBox(height: 25),

                          // Tiêu đề lịch sử
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    lang.recentDocuments ?? "Tài liệu gần đây",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ],
                              ),
                              // Tìm đoạn TextButton này:
                              TextButton(
                                onPressed: () {
                                  // --- Code cũ: hiện SnackBar ---
                                  // ScaffoldMessenger.of(context).showSnackBar(...)

                                  // --- Code MỚI: Chuyển sang màn hình tất cả ---
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => AllDocumentsScreen()),
                                  );
                                },
                                child: Text(
                                  lang.viewAll ?? "Xem tất cả",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 6),

                          // Danh sách lịch sử
                          _buildHistoryList(state, theme, lang),

                          SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Loading overlay
              if (isLoading)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 15),
                          Text(
                            lang.processing ?? "Đang xử lý...",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Widget vẽ từng ô chức năng
  Widget _buildToolCard(Map<String, dynamic> tool, ThemeData theme, AppLocalizations lang) {
    return Material(
      color: theme.cardColor,
      elevation: 3,
      shadowColor: tool['color'].withOpacity(0.3),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (tool['id'] == 'img_to_pdf') {
            _showImageSourceModal(lang, theme);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "${lang.feature ?? "Tính năng"} ${tool['name']} ${lang.inDevelopment ?? "đang phát triển!"}",
                ),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tool['color'].withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(tool['icon'], size: 32, color: tool['color']),
              ),
              SizedBox(height: 12),
              Text(
                tool['name'],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Menu chọn Camera/Gallery
  // Menu chọn Camera/Gallery (Phiên bản nhẹ, hỗ trợ chọn nhiều ảnh)
  void _showImageSourceModal(AppLocalizations lang, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) { // <--- Đổi tên biến này để an toàn hơn
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh gạch ngang nhỏ
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Tiêu đề
              Text(
                lang.chooseImageFrom ?? "Chọn ảnh từ",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              // Hai nút lựa chọn
              Row(
                children: [
                  // --- NÚT 1: MÁY ẢNH ---
                  Expanded(
                    child: _buildModalButton(
                      icon: Icons.camera_alt_rounded,
                      label: lang.camera ?? "Máy ảnh",
                      color: Colors.blue,
                      theme: theme,
                      onTap: () {
                        Navigator.pop(modalContext); // Đóng popup
                        // True = Camera (Chụp 1 tấm)
                        context.read<HomeBloc>().add(PickImageRequested(true));
                      },
                    ),
                  ),
                  SizedBox(width: 15),

                  // --- NÚT 2: THƯ VIỆN (Đã nâng cấp chọn nhiều) ---
                  Expanded(
                    child: _buildModalButton(
                      icon: Icons.photo_library_rounded,
                      label: lang.gallery ?? "Thư viện",
                      color: Colors.purple,
                      theme: theme,
                      onTap: () {
                        Navigator.pop(modalContext); // Đóng popup

                        // False = Thư viện
                        // Nhờ đã sửa HomeBloc dùng pickMultiImage, lệnh này sẽ mở giao diện chọn nhiều ảnh!
                        context.read<HomeBloc>().add(PickImageRequested(false));
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalButton({
    required IconData icon,
    required String label,
    required Color color,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Phần hiển thị danh sách lịch sử
  Widget _buildHistoryList(HomeState state, ThemeData theme, AppLocalizations lang) {
    if (state is HistoryLoaded) {
      if (state.documents.isEmpty) {
        return Container(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.folder_open_rounded,
                size: 80,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                lang.noFiles ?? "Chưa có file nào",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }

      final displayDocs = state.documents.take(5).toList();

      return ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: displayDocs.length,
        itemBuilder: (context, index) {
          final doc = displayDocs[index];
          bool isPdf = doc['type'] == 'pdf' ||
              doc['original_name'].toString().toLowerCase().endsWith('.pdf');

          return Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPdf ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                  color: isPdf ? Colors.red : Colors.blue,
                  size: 28,
                ),
              ),
              title: Text(
                doc['original_name'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              subtitle: Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  doc['created_at'].toString().substring(0, 10),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FileDetailScreen(document: doc),
                ),
              ),
            ),
          );
        },
      );
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      ),
    );
  }
}