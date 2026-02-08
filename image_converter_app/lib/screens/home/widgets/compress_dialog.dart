import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_converter_app/l10n/app_localizations.dart';
import '../../../blocs/home_bloc.dart';

/// Dialog để chọn file và nén (ảnh hoặc PDF)
class CompressDialog extends StatefulWidget {
  const CompressDialog({super.key});

  /// Hiển thị dialog
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => const CompressDialog(),
      ),
    );
  }

  @override
  State<CompressDialog> createState() => _CompressDialogState();
}

class _CompressDialogState extends State<CompressDialog> {
  // File đã chọn
  File? _selectedFile;
  String? _fileName;
  int? _fileSize;
  String? _fileType; // 'image' hoặc 'pdf'

  // Mức chất lượng nén
  String _quality = 'medium';

  // Đang xử lý
  bool _isProcessing = false;

  // Các mức chất lượng
  final List<Map<String, dynamic>> _qualityOptions = [
    {
      'id': 'high',
      'name': 'Chất lượng cao',
      'description': 'Nén nhẹ, giữ chất lượng tốt nhất',
      'icon': Icons.high_quality_rounded,
      'color': Colors.green,
    },
    {
      'id': 'medium',
      'name': 'Cân bằng',
      'description': 'Cân bằng giữa kích thước và chất lượng',
      'icon': Icons.tune_rounded,
      'color': Colors.blue,
    },
    {
      'id': 'low',
      'name': 'Nén tối đa',
      'description': 'Ưu tiên giảm dung lượng',
      'icon': Icons.compress_rounded,
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF34D399)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.compress_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.compress ?? 'Nén file',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Giảm dung lượng ảnh & PDF',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: Chọn file
                  _buildSectionTitle('1. Chọn file', Icons.file_upload_rounded, isDark),
                  const SizedBox(height: 12),
                  _buildFilePicker(isDark),

                  const SizedBox(height: 24),

                  // Step 2: Chọn mức nén
                  _buildSectionTitle('2. Chọn mức nén', Icons.tune_rounded, isDark),
                  const SizedBox(height: 12),
                  _buildQualitySelector(isDark),

                  const SizedBox(height: 24),

                  // Preview thông tin nén
                  if (_selectedFile != null)
                    _buildCompressionPreview(isDark),

                  const SizedBox(height: 100), // Space for button
                ],
              ),
            ),
          ),

          // Bottom action button
          _buildBottomButton(isDark, lang),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white70 : Colors.grey[700],
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildFilePicker(bool isDark) {
    if (_selectedFile != null) {
      // Hiển thị file đã chọn
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _fileType == 'pdf'
                    ? Colors.red.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _fileType == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                color: _fileType == 'pdf' ? Colors.red : Colors.blue,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fileName ?? 'File',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatFileSize(_fileSize ?? 0),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _pickFile,
              icon: Icon(
                Icons.swap_horiz_rounded,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
              tooltip: 'Đổi file',
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedFile = null;
                  _fileName = null;
                  _fileSize = null;
                  _fileType = null;
                });
              },
              icon: Icon(
                Icons.close_rounded,
                color: Colors.red[400],
              ),
              tooltip: 'Xóa file',
            ),
          ],
        ),
      );
    }

    // Picker trống
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey[300]!,
            width: 2,
            // Dashed effect - use simple border
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_rounded,
                color: Color(0xFF10B981),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nhấn để chọn file',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hỗ trợ: JPEG, PNG, GIF, WebP, PDF',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tối đa 50MB',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualitySelector(bool isDark) {
    return Column(
      children: _qualityOptions.map((option) {
        final isSelected = _quality == option['id'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _quality = option['id'];
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? (option['color'] as Color).withOpacity(0.1)
                  : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? (option['color'] as Color)
                    : (isDark ? Colors.white12 : Colors.grey[200]!),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (option['color'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    option['icon'],
                    color: option['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option['name'],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option['description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? option['color']
                        : (isDark ? Colors.white12 : Colors.grey[200]),
                    border: Border.all(
                      color: isSelected
                          ? option['color']
                          : (isDark ? Colors.white24 : Colors.grey[300]!),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompressionPreview(bool isDark) {
    String estimatedReduction;
    switch (_quality) {
      case 'high':
        estimatedReduction = '10-20%';
        break;
      case 'low':
        estimatedReduction = '50-80%';
        break;
      default:
        estimatedReduction = '30-50%';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]
              : [const Color(0xFF10B981).withOpacity(0.05), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFF10B981).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              Text(
                'Dự kiến',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                'Kích thước gốc',
                _formatFileSize(_fileSize ?? 0),
                Icons.folder_open_rounded,
                isDark,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
              ),
              _buildInfoItem(
                'Giảm khoảng',
                estimatedReduction,
                Icons.trending_down_rounded,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF10B981)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(bool isDark, AppLocalizations lang) {
    final canCompress = _selectedFile != null && !_isProcessing;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: canCompress ? _performCompress : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            disabledBackgroundColor: isDark ? Colors.white12 : Colors.grey[200],
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isProcessing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Đang nén...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.compress_rounded),
                    const SizedBox(width: 8),
                    Text(
                      lang.compress ?? 'Nén file',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (file.path != null) {
          setState(() {
            _selectedFile = File(file.path!);
            _fileName = file.name;
            _fileSize = file.size;
            
            // Xác định loại file
            final ext = file.extension?.toLowerCase();
            if (ext == 'pdf') {
              _fileType = 'pdf';
            } else {
              _fileType = 'image';
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performCompress() async {
    if (_selectedFile == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Gọi Bloc event để nén file
      context.read<HomeBloc>().add(
        CompressFileRequested(
          file: _selectedFile!,
          quality: _quality,
        ),
      );

      // Đóng dialog
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang xử lý nén file...'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
