import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../../../blocs/home_bloc.dart';
import '../../../services/document_service.dart';

/// Dialog để chọn file PDF và tách theo range hoặc danh sách trang
class SplitPdfDialog extends StatefulWidget {
  const SplitPdfDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<HomeBloc>(),
        child: const SplitPdfDialog(),
      ),
    );
  }

  @override
  State<SplitPdfDialog> createState() => _SplitPdfDialogState();
}

class _SplitPdfDialogState extends State<SplitPdfDialog> {
  // State
  int _currentStep = 0; // 0: Chọn file, 1: Chọn trang
  Map<String, dynamic>? _selectedFile;
  int? _totalPages;
  bool _isLoadingInfo = false;
  
  // Controllers
  final _startPageController = TextEditingController(text: '1');
  final _endPageController = TextEditingController();
  final _outputNameController = TextEditingController();
  
  // Mode: 'range' hoặc 'pages'
  String _splitMode = 'range';
  List<int> _selectedPages = [];
  
  // Loading state khi thực hiện split
  bool _isSplitting = false;
  
  // Document service để gọi API
  final DocumentService _documentService = DocumentService();

  @override
  void initState() {
    super.initState();
    // Load danh sách PDF
    context.read<HomeBloc>().add(LoadHistoryRequested());
  }

  @override
  void dispose() {
    _startPageController.dispose();
    _endPageController.dispose();
    _outputNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.call_split_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.splitPdf ?? 'Tách PDF',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        _currentStep == 0
                            ? 'Chọn file PDF cần tách'
                            : 'Chọn các trang muốn tách',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Step indicator
          _buildStepIndicator(isDark),

          const SizedBox(height: 16),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: bottomPadding + 20,
              ),
              child: _currentStep == 0
                  ? _buildFileList(isDark, lang)
                  : _buildPageSelector(isDark, lang),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStepCircle(1, 'Chọn file', _currentStep >= 0, isDark),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 1
                  ? const Color(0xFF06B6D4)
                  : Colors.grey[300],
            ),
          ),
          _buildStepCircle(2, 'Chọn trang', _currentStep >= 1, isDark),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label, bool isActive, bool isDark) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF06B6D4) : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive
                ? (isDark ? Colors.white : Colors.black87)
                : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildFileList(bool isDark, AppLocalizations lang) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is HomeHistoryLoaded) {
          // Lọc chỉ lấy file PDF
          final pdfFiles = state.documents
              .where((doc) =>
                  doc['type']?.toString().toLowerCase() == 'pdf' ||
                  doc['name']?.toString().toLowerCase().endsWith('.pdf') == true)
              .toList();

          if (pdfFiles.isEmpty) {
            return _buildEmptyState(
              Icons.picture_as_pdf_rounded,
              'Không có file PDF nào',
              'Hãy chuyển đổi ảnh sang PDF trước',
            );
          }

          return Column(
            children: pdfFiles.take(10).map((doc) {
              final isSelected = _selectedFile?['id'] == doc['id'];
              return _buildFileItem(doc, isSelected, isDark);
            }).toList(),
          );
        }

        return _buildEmptyState(
          Icons.folder_open_rounded,
          'Không có dữ liệu',
          'Kéo xuống để làm mới',
        );
      },
    );
  }

  Widget _buildFileItem(Map<String, dynamic> doc, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () => _onFileSelected(doc),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF06B6D4).withOpacity(0.1)
              : (isDark ? Colors.grey[850] : Colors.grey[50]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF06B6D4)
                : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // PDF Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc['name'] ?? doc['original_name'] ?? 'Untitled.pdf',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatFileSize(doc['size']),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Checkmark
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF06B6D4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageSelector(bool isDark, AppLocalizations lang) {
    if (_isLoadingInfo) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải thông tin file...'),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File info card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFile?['name'] ?? 'File.pdf',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Tổng cộng: $_totalPages trang',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 0;
                    _selectedFile = null;
                    _totalPages = null;
                  });
                },
                child: const Text('Đổi file'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Mode selector
        Text(
          'Chế độ tách',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildModeButton('range', 'Theo phạm vi', Icons.linear_scale_rounded, isDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildModeButton('pages', 'Chọn trang', Icons.checklist_rounded, isDark),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Input fields based on mode
        if (_splitMode == 'range') ...[
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _startPageController,
                  label: 'Từ trang',
                  hint: '1',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _endPageController,
                  label: 'Đến trang',
                  hint: '$_totalPages',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ] else ...[
          // Page grid for selection
          Text(
            'Chọn các trang (bấm để chọn/bỏ chọn)',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_totalPages ?? 0, (index) {
              final pageNum = index + 1;
              final isSelected = _selectedPages.contains(pageNum);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedPages.remove(pageNum);
                    } else {
                      _selectedPages.add(pageNum);
                    }
                    _selectedPages.sort();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF06B6D4)
                        : (isDark ? Colors.grey[800] : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF06B6D4)
                          : Colors.grey[400]!,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$pageNum',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          if (_selectedPages.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Đã chọn: ${_selectedPages.join(", ")}',
              style: const TextStyle(
                color: Color(0xFF06B6D4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],

        const SizedBox(height: 20),

        // Output name
        _buildTextField(
          controller: _outputNameController,
          label: 'Tên file mới (tùy chọn)',
          hint: 'Để trống để tự động đặt tên',
          isDark: isDark,
          keyboardType: TextInputType.text,
        ),

        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 0;
                    _selectedFile = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Quay lại'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (_canSplit() && !_isSplitting) ? _performSplit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSplitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call_split_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Tách PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeButton(String mode, String label, IconData icon, bool isDark) {
    final isSelected = _splitMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _splitMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF06B6D4).withOpacity(0.1)
              : (isDark ? Colors.grey[850] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF06B6D4)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? const Color(0xFF06B6D4)
                  : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF06B6D4)
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    TextInputType keyboardType = TextInputType.number,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ======================== LOGIC ========================

  void _onFileSelected(Map<String, dynamic> doc) async {
    setState(() {
      _selectedFile = doc;
      _isLoadingInfo = true;
      _currentStep = 1;
    });

    // Gọi API để lấy số trang thực tế
    try {
      final fileId = doc['id'];
      if (fileId == null) {
        throw Exception('File ID không hợp lệ');
      }
      
      // Gọi API getPdfInfo để lấy thông tin PDF
      final pdfInfo = await _documentService.getPdfInfo(fileId);
      
      if (mounted) {
        setState(() {
          _totalPages = pdfInfo['total_pages'] ?? 1;
          _endPageController.text = '$_totalPages';
          _isLoadingInfo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingInfo = false;
          _currentStep = 0; // Quay lại bước chọn file nếu lỗi
          _selectedFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lấy thông tin PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _canSplit() {
    if (_selectedFile == null || _totalPages == null) return false;

    if (_splitMode == 'range') {
      final start = int.tryParse(_startPageController.text) ?? 0;
      final end = int.tryParse(_endPageController.text) ?? 0;
      return start >= 1 && end >= start && end <= _totalPages!;
    } else {
      return _selectedPages.isNotEmpty;
    }
  }

  void _performSplit() async {
    if (_selectedFile == null || _isSplitting) return;

    // Validate input trước khi gọi API
    final fileId = _selectedFile!['id'];
    if (fileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File ID không hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final outputName = _outputNameController.text.trim().isEmpty
        ? null
        : _outputNameController.text.trim();

    // Bắt đầu loading
    setState(() => _isSplitting = true);

    try {
      if (_splitMode == 'range') {
        final startPage = int.tryParse(_startPageController.text);
        final endPage = int.tryParse(_endPageController.text);
        
        if (startPage == null || endPage == null) {
          throw Exception('Vui lòng nhập số trang hợp lệ');
        }

        context.read<HomeBloc>().add(SplitPdfRequested(
          fileId: fileId,
          startPage: startPage,
          endPage: endPage,
          outputName: outputName,
        ));
      } else {
        if (_selectedPages.isEmpty) {
          throw Exception('Vui lòng chọn ít nhất 1 trang');
        }
        
        context.read<HomeBloc>().add(SplitPdfByPagesRequested(
          fileId: fileId,
          pages: _selectedPages,
          outputName: outputName,
        ));
      }

      // Hiển thị thông báo đang xử lý
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Đang tách PDF...'),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: const Color(0xFF06B6D4),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSplitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatFileSize(dynamic size) {
    if (size == null) return 'N/A';
    final bytes = size is int ? size : int.tryParse(size.toString()) ?? 0;
    if (bytes > 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(2)} KB';
  }
}
