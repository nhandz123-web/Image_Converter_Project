import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/home_bloc.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'file_detail_screen.dart';
import 'all_documents_screen.dart';
import 'profile_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'edit_image_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. Khai báo danh sách ID được chọn để gộp PDF
  List<int> selectedIds = [];

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(LoadHistoryRequested());
  }

  // 2. Hàm hiển thị hộp thoại chọn file PDF từ lịch sử
  void _showMergeSelectionDialog(AppLocalizations lang, ThemeData theme) {
    // Luôn load lại lịch sử mới nhất trước khi chọn
    context.read<HomeBloc>().add(LoadHistoryRequested());
    setState(() => selectedIds = []); // Reset danh sách chọn cũ

    final bool isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  // ═══════════ DRAG HANDLE ═══════════
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // ═══════════ HEADER ═══════════
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          lang.mergePdf ?? "Merge PDF",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (selectedIds.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              "${lang.mergeOrderSelected ?? "Merge order"}: ${selectedIds.length} ${lang.filesSelected ?? "files selected"}",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ═══════════ PDF LIST ═══════════
                  Expanded(
                    child: BlocBuilder<HomeBloc, HomeState>(
                      builder: (context, state) {
                        if (state is HistoryLoaded) {
                          // Lọc chỉ lấy các file PDF trong lịch sử
                          final pdfFiles = state.documents.where((d) =>
                          d['type'] == 'pdf' ||
                              d['original_name'].toString().toLowerCase().endsWith('.pdf')
                          ).toList();

                          if (pdfFiles.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    lang.noPdfFiles ?? "No PDF files available",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            itemCount: pdfFiles.length,
                            itemBuilder: (context, index) {
                              final doc = pdfFiles[index];
                              final docId = doc['id'];
                              final bool isSelected = selectedIds.contains(docId);

                              // ★ TÍNH THỨ TỰ CHỌN (bắt đầu từ 1)
                              final int selectionOrder = isSelected
                                  ? selectedIds.indexOf(docId) + 1
                                  : 0;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      setModalState(() {
                                        if (isSelected) {
                                          selectedIds.remove(docId);
                                        } else {
                                          selectedIds.add(docId);
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 200),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.purple.withOpacity(0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.purple
                                              : Colors.grey.withOpacity(0.3),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // ═══ PDF ICON ═══
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.picture_as_pdf,
                                              color: Colors.red,
                                              size: 24,
                                            ),
                                          ),
                                          SizedBox(width: 12),

                                          // ═══ FILE NAME ═══
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  doc['original_name'],
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                                if (isSelected)
                                                  Text(
                                                    "${lang.orderNumber ?? "Order"}: $selectionOrder",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.purple,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 12),

                                          // ═══ ★ SELECTION ORDER BADGE ═══
                                          _buildSelectionBadge(
                                            isSelected: isSelected,
                                            order: selectionOrder,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                        return Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),

                  // ═══════════ SELECTED FILES PREVIEW ═══════════
                  if (selectedIds.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${lang.mergeOrder ?? "Merge order"}:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: BlocBuilder<HomeBloc, HomeState>(
                              builder: (context, state) {
                                if (state is HistoryLoaded) {
                                  return Row(
                                    children: List.generate(selectedIds.length, (index) {
                                      final docId = selectedIds[index];
                                      final doc = state.documents.firstWhere(
                                            (d) => d['id'] == docId,
                                        orElse: () => {'original_name': lang.unknown ?? 'Unknown'},
                                      );
                                      return Container(
                                        margin: EdgeInsets.only(right: 8),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.purple),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 10,
                                              backgroundColor: Colors.purple,
                                              child: Text(
                                                "${index + 1}",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            ConstrainedBox(
                                              constraints: BoxConstraints(maxWidth: 100),
                                              child: Text(
                                                doc['original_name'],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  );
                                }
                                return SizedBox();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ═══════════ HELPER TEXT ═══════════
                  if (selectedIds.length < 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        lang.selectAtLeast2Files ?? "Please select at least 2 files to merge",
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // ═══════════ MERGE BUTTON ═══════════
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: selectedIds.length < 2 ? 0 : 4,
                      ),
                      onPressed: selectedIds.length < 2
                          ? null
                          : () {
                        context.read<HomeBloc>().add(
                          MergePdfsRequested(selectedIds),
                        );
                        Navigator.pop(modalContext);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.merge_type),
                          SizedBox(width: 8),
                          Text(
                            "${lang.mergeNow ?? "Merge now"} (${selectedIds.length})",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// ═══════════════════════════════════════════════════════════════
//              ★ SELECTION BADGE WIDGET ★
// ═══════════════════════════════════════════════════════════════
  Widget _buildSelectionBadge({
    required bool isSelected,
    required int order,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isSelected ? Colors.purple : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.purple : Colors.grey.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: Center(
        child: isSelected
            ? Text(
          "$order",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        )
            : null,
      ),
    );
  }

// ═══════════════════════════════════════════════════════════════
//              ★ SELECTION BADGE WIDGET ★
// ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Map<String, dynamic>> tools = [
      {'id': 'img_to_pdf', 'name': lang.imageToPdf ?? "Ảnh sang PDF", 'icon': Icons.image_rounded, 'color': Colors.redAccent},
      {'id': 'word_to_pdf', 'name': lang.wordToPdf ?? "Word sang PDF", 'icon': Icons.description_rounded, 'color': Colors.blue},
      {'id': 'excel_to_pdf', 'name': lang.excelToPdf ?? "Excel sang PDF", 'icon': Icons.table_chart_rounded, 'color': Colors.green},
      {'id': 'qr_scan', 'name': lang.qrScan ?? "Quét mã QR", 'icon': Icons.qr_code_scanner_rounded, 'color': Colors.orange},
      {'id': 'merge_pdf', 'name': lang.mergePdf ?? "Ghép file PDF", 'icon': Icons.merge_type_rounded, 'color': Colors.purple},
      {'id': 'compress', 'name': lang.compressData ?? "Nén dữ liệu", 'icon': Icons.compress_rounded, 'color': Colors.teal},
    ];

    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is HomeSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
          );
          context.read<HomeBloc>().add(LoadHistoryRequested());
        }
        if (state is HomeFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
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
                  SliverAppBar(
                    floating: false, pinned: true, elevation: 0,
                    backgroundColor: theme.primaryColor,
                    toolbarHeight: 70,
                    flexibleSpace: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: isDark ? [Color(0xFF1A237E), Color(0xFF0D47A1)] : [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(lang.pdfTools ?? "Công cụ PDF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                              IconButton(
                                icon: Icon(Icons.manage_accounts_rounded, size: 30, color: Colors.white),
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen())),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeCard(isDark, lang),
                          SizedBox(height: 20),
                          _buildSectionTitle(theme, lang.popularTools ?? "Công cụ phổ biến"),
                          SizedBox(height: 6),
                          GridView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: tools.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85,
                            ),
                            itemBuilder: (context, index) => _buildToolCard(tools[index], theme, lang),
                          ),
                          SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionTitle(theme, lang.recentDocuments ?? "Tài liệu gần đây"),
                              TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AllDocumentsScreen())),
                                child: Text(lang.viewAll ?? "Xem tất cả", style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          _buildHistoryList(state, theme, lang),
                          SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (isLoading) _buildLoadingOverlay(theme, lang),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGET HELPER METHODS ---

  Widget _buildWelcomeCard(bool isDark, AppLocalizations lang) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [Colors.blue[900]!, Colors.blue[700]!] : [Colors.blue[400]!, Colors.purple[400]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.welcomeMessage ?? "Chào mừng!", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(lang.chooseToolBelow ?? "Chọn công cụ để bắt đầu", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
              ],
            ),
          ),
          Icon(Icons.touch_app_rounded, size: 50, color: Colors.white.withOpacity(0.8)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(2))),
        SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
      ],
    );
  }

  Widget _buildToolCard(Map<String, dynamic> tool, ThemeData theme, AppLocalizations lang) {
    return Material(
      color: theme.cardColor, elevation: 3, shadowColor: tool['color'].withOpacity(0.3),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (tool['id'] == 'img_to_pdf') {
            _showImageSourceModal(lang, theme);
          } else if (tool['id'] == 'merge_pdf') {
            // GỌI HÀM CHỌN FILE GỘP PDF TẠI ĐÂY
            _showMergeSelectionDialog(lang, theme);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${tool['name']} đang phát triển!")));
          }
        },
        child: Container(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(color: tool['color'].withOpacity(0.15), borderRadius: BorderRadius.circular(15)),
                child: Icon(tool['icon'], size: 32, color: tool['color']),
              ),
              SizedBox(height: 12),
              Text(tool['name'], textAlign: TextAlign.center, maxLines: 2, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceModal(AppLocalizations lang, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang.chooseImageFrom ?? "Chọn ảnh từ",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            Row(
              children: [
                // --- CHẾ ĐỘ MÁY ẢNH ---
                Expanded(
                  child: _buildModalButton(
                    icon: Icons.camera_alt_rounded,
                    label: lang.camera ?? "Máy ảnh",
                    color: Colors.blue,
                    theme: theme,
                    onTap: () async {
                      Navigator.pop(modalContext); // Đóng menu chọn
                      final picker = ImagePicker();
                      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
                      
                      if (photo != null) {
                        _goToEditScreen(File(photo.path));
                      }
                    },
                  ),
                ),
                SizedBox(width: 15),
                // --- CHẾ ĐỘ THƯ VIỆN ---
                Expanded(
                  child: _buildModalButton(
                    icon: Icons.photo_library_rounded,
                    label: lang.gallery ?? "Thư viện",
                    color: Colors.purple,
                    theme: theme,
                    onTap: () async {
                      Navigator.pop(modalContext); // Đóng menu chọn
                      final picker = ImagePicker();
                      final List<XFile> pickedFiles = await picker.pickMultiImage();
                      
                      if (pickedFiles.isNotEmpty) {
                        List<File> files = pickedFiles.map((x) => File(x.path)).toList();
                        _goToEditScreen(files);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // HÀM PHỤ TRỢ ĐỂ CHUYỂN SANG MÀN HÌNH EDIT (Viết thêm hàm này vào trong _HomeScreenState)
  void _goToEditScreen(dynamic input) async {
    List<File> imagesToEdit = [];
    if (input is File) {
      imagesToEdit = [input];
    } else if (input is List<File>) {
      imagesToEdit = input;
    }

    // Chuyển sang màn hình Edit và đợi kết quả trả về
    final List<File>? editedFiles = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditImageScreen(images: imagesToEdit),
      ),
    );

    // Sau khi người dùng nhấn dấu tích (Save) ở màn hình Edit
    if (editedFiles != null && editedFiles.isNotEmpty) {
      // Lúc này mới chính thức gọi Bloc để Upload
      context.read<HomeBloc>().add(UploadEditedImagesEvent(editedFiles));
    }
  }
  

  Widget _buildModalButton({required IconData icon, required String label, required Color color, required ThemeData theme, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(children: [Icon(icon, color: color, size: 36), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget _buildHistoryList(HomeState state, ThemeData theme, AppLocalizations lang) {
    if (state is HistoryLoaded) {
      if (state.documents.isEmpty) return Center(child: Text(lang.noFiles ?? "Chưa có file nào"));
      final displayDocs = state.documents.take(5).toList();
      return ListView.builder(
        shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
        itemCount: displayDocs.length,
        itemBuilder: (context, index) {
          final doc = displayDocs[index];
          bool isPdf = doc['type'] == 'pdf' || doc['original_name'].toString().toLowerCase().endsWith('.pdf');
          return Card(
            margin: EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: Icon(isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded, color: isPdf ? Colors.red : Colors.blue),
              title: Text(doc['original_name'], maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(doc['created_at'].toString().substring(0, 10)),
              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FileDetailScreen(document: doc))),
            ),
          );
        },
      );
    }
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildLoadingOverlay(ThemeData theme, AppLocalizations lang) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(15)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [CircularProgressIndicator(), SizedBox(height: 15), Text(lang.processing ?? "Đang xử lý...")],
          ),
        ),
      ),
    );
  }
}