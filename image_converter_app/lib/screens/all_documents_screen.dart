import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../blocs/home_bloc.dart';
import 'file_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_header.dart'; // Import AppHeader mới

/// Màn hình tất cả tài liệu
/// Style: Glassmorphism Modern
class AllDocumentsScreen extends StatefulWidget {
  const AllDocumentsScreen({super.key});

  @override
  State<AllDocumentsScreen> createState() => _AllDocumentsScreenState();
}

class _AllDocumentsScreenState extends State<AllDocumentsScreen> {
  String _searchKeyword = "";
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true, // Để AppHeader đè lên background
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
                ),
        ),
        child: Stack(
          children: [
            // Background Blobs
            if (!isDark) ...[
              Positioned(
                top: 100,
                left: -50,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.15),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.1),
                        blurRadius: 80,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            CustomScrollView(
              slivers: [
                // App Header mới với Glassmorphism
                AppHeader(
                  title: _isSearching ? null : (lang.allDocuments ?? "Tất cả tài liệu"),
                  showLogo: false,
                  showVipCrown: false,
                  showProfileButton: false,
                  onBackPressed: () => Navigator.pop(context),
                  actions: [
                    IconButton(
                      icon: Icon(
                        _isSearching ? Icons.close_rounded : Icons.search_rounded,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) {
                            _searchKeyword = "";
                            _searchController.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),

                // Search Bar (Hiện ra khi bấm search)
                if (_isSearching)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.1) 
                                  : Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isDark 
                                    ? Colors.white.withOpacity(0.1) 
                                    : Colors.black.withOpacity(0.05),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: lang.searchDocuments ?? "Tìm kiếm tài liệu...",
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.grey,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: isDark ? Colors.white54 : Colors.grey,
                                ),
                                suffixIcon: _searchKeyword.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear_rounded,
                                          color: isDark ? Colors.white54 : Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _searchKeyword = "";
                                            _searchController.clear();
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchKeyword = value.toLowerCase();
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Danh sách tài liệu
                BlocBuilder<HomeBloc, HomeState>(
                  builder: (context, state) {
                    if (state is HomeLoading) {
                      return SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: theme.primaryColor,
                          ),
                        ),
                      );
                    }

                    if (state is HistoryLoaded) {
                      var documents = state.documents;

                      // Lọc theo từ khóa tìm kiếm
                      if (_searchKeyword.isNotEmpty) {
                        documents = documents.where((doc) {
                          final name = doc['name']?.toString().toLowerCase() ?? '';
                          return name.contains(_searchKeyword);
                        }).toList();
                      }

                      if (documents.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchKeyword.isNotEmpty
                                      ? Icons.search_off_rounded
                                      : Icons.folder_open_rounded,
                                  size: 80,
                                  color: isDark ? Colors.white24 : Colors.grey[300],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _searchKeyword.isNotEmpty
                                      ? (lang.noSearchResults ?? "Không tìm thấy kết quả")
                                      : (lang.noDocuments ?? "Chưa có tài liệu nào"),
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.grey[600],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final doc = documents[index];
                              bool isPdf = (doc['type'] == 'pdf') ||
                                  (doc['name']?.toString().toLowerCase().endsWith('.pdf') ?? false);

                              return _buildDocumentCard(
                                context,
                                doc,
                                isPdf,
                                theme,
                                isDark,
                                lang,
                              );
                            },
                            childCount: documents.length,
                          ),
                        ),
                      );
                    }

                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          lang.loadDataError ?? "Không tải được dữ liệu",
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    Map<String, dynamic> doc,
    bool isPdf,
    ThemeData theme,
    bool isDark,
    AppLocalizations lang,
  ) {
    // Determine colors based on file type
    final Color iconColor = isPdf
        ? (isDark ? const Color(0xFFF43F5E) : const Color(0xFFE11D48)) // Rose
        : (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)); // Blue

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withOpacity(0.05) 
                  : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.1) 
                    : Colors.white.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.1) 
                      : Colors.blue.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FileDetailScreen(document: doc),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Icon file
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(isDark ? 0.15 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: iconColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                          color: iconColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Thông tin file
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc['name']?.toString() ?? "Không có tên file",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: isDark ? Colors.white38 : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  doc['created_at'].toString().length >= 16 
                                      ? doc['created_at'].toString().substring(0, 16)
                                      : doc['created_at'].toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white38 : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Mũi tên
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: isDark ? Colors.white38 : Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
