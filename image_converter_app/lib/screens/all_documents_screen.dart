import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../blocs/home_bloc.dart';
import 'file_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

class AllDocumentsScreen extends StatefulWidget {
  @override
  _AllDocumentsScreenState createState() => _AllDocumentsScreenState();
}

class _AllDocumentsScreenState extends State<AllDocumentsScreen> {
  String _searchKeyword = "";
  TextEditingController _searchController = TextEditingController();
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
      backgroundColor: AppTheme.getBackgroundColor(isDark),
      body: CustomScrollView(
        slivers: [
          // App Bar với gradient
          SliverAppBar(
            floating: false,
            pinned: true,
            elevation: AppDimensions.elevation0,
            backgroundColor: theme.primaryColor,
            toolbarHeight: AppDimensions.appBarHeight,
            automaticallyImplyLeading: false,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.getPrimaryGradient(isDark),
              ),
              child: SafeArea(
                child: Padding(
                  padding: AppDimensions.paddingH8,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      if (!_isSearching)
                        Expanded(
                          child: Text(
                            lang.allDocuments ?? "Tất cả tài liệu",
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: AppTextStyles.weightBold,
                              fontSize: AppTextStyles.fontSize22,
                            ),
                          ),
                        ),
                      if (_isSearching) const Spacer(),
                      IconButton(
                        icon: Icon(
                          _isSearching ? Icons.close_rounded : Icons.search_rounded,
                          color: AppColors.white,
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
                ),
              ),
            ),
            bottom: _isSearching
                ? PreferredSize(
              preferredSize: Size.fromHeight(70),
              child: Container(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: lang.searchDocuments ?? "Tìm kiếm tài liệu...",
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.grey),
                      suffixIcon: _searchKeyword.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchKeyword = "";
                            _searchController.clear();
                          });
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchKeyword = value.toLowerCase();
                      });
                    },
                  ),
                ),
              ),
            )
                : null,
          ),

          // Nội dung danh sách
          BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              if (state is HomeLoading) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          lang.loading ?? "Đang tải...",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is HistoryLoaded) {
                var documents = state.documents;

                // Lọc theo từ khóa tìm kiếm
                if (_searchKeyword.isNotEmpty) {
                  documents = documents.where((doc) {
                    return doc['original_name']
                        .toString()
                        .toLowerCase()
                        .contains(_searchKeyword);
                  }).toList();
                }

                if (documents.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchKeyword.isNotEmpty
                                ? Icons.search_off_rounded
                                : Icons.folder_open_rounded,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 20),
                          Text(
                            _searchKeyword.isNotEmpty
                                ? (lang.noSearchResults ?? "Không tìm thấy kết quả")
                                : (lang.noDocuments ?? "Chưa có tài liệu nào"),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_searchKeyword.isNotEmpty) ...[
                            SizedBox(height: 8),
                            Text(
                              "${lang.trySearchOther ?? "Thử tìm kiếm từ khóa khác"}",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final doc = documents[index];
                        bool isPdf = doc['type'] == 'pdf' ||
                            doc['original_name']
                                .toString()
                                .toLowerCase()
                                .endsWith('.pdf');

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
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 80, color: Colors.grey[400]),
                      SizedBox(height: 20),
                      Text(
                        lang.loadDataError ?? "Không tải được dữ liệu",
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
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
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FileDetailScreen(document: doc),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon file
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isPdf
                        ? Colors.red.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                    color: isPdf ? Colors.red : Colors.blue,
                    size: 28,
                  ),
                ),
                SizedBox(width: 14),

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
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            doc['created_at'].toString().substring(0, 16),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 12),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: doc['status'] == 'completed'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            // child: Text(
                            //   doc['status'] == 'completed'
                            //       ? (lang.completed ?? 'Hoàn thành')
                            //       : (lang.processing ?? 'Đang xử lý'),
                            //   style: TextStyle(
                            //     fontSize: 11,
                            //     fontWeight: FontWeight.w600,
                            //     color: doc['status'] == 'completed'
                            //         ? Colors.green
                            //         : Colors.orange,
                            //   ),
                            // ),
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
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
