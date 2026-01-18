import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

// Import các widget đã tách
import 'models/image_item.dart';
import 'widgets/widgets.dart';

/// Màn hình chỉnh sửa ảnh trước khi convert sang PDF
/// 
/// ĐÃ REFACTOR: Tách thành các widget con để dễ maintain
/// - ImageItem: Model đại diện cho ảnh
/// - FullScreenImageViewer: Xem ảnh toàn màn hình
/// - EditOptionsSheet: Bottom sheet tùy chọn edit
/// - ImagePreviewSection: Preview ảnh lớn
/// - EditHelpers: Các widget helper nhỏ
class EditImageScreen extends StatefulWidget {
  final List<File> images;
  const EditImageScreen({super.key, required this.images});

  @override
  State<EditImageScreen> createState() => _EditImageScreenState();
}

class _EditImageScreenState extends State<EditImageScreen>
    with TickerProviderStateMixin {

  // ─────────────────── STATE VARIABLES ───────────────────
  late List<ImageItem> imageList;
  int? selectedIndex;
  bool isGridView = false;
  bool isProcessing = false;

  // History for Undo/Redo
  final List<List<ImageItem>> _history = [];
  int _historyIndex = -1;

  // Animation controllers
  late AnimationController _fabAnimationController;

  // ─────────────────── LIFECYCLE ───────────────────
  @override
  void initState() {
    super.initState();
    imageList = widget.images
        .map((f) => ImageItem(file: f, id: UniqueKey().toString()))
        .toList();
    _saveToHistory();

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  // ─────────────────── HISTORY MANAGEMENT ───────────────────
  void _saveToHistory() {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(imageList.map((e) => e.copy()).toList());
    _historyIndex = _history.length - 1;

    if (_history.length > 20) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  void _undo() {
    if (canUndo) {
      setState(() {
        _historyIndex--;
        imageList = _history[_historyIndex].map((e) => e.copy()).toList();
      });
      _showSnackBar('↶ Đã hoàn tác', Colors.blue);
    }
  }

  void _redo() {
    if (canRedo) {
      setState(() {
        _historyIndex++;
        imageList = _history[_historyIndex].map((e) => e.copy()).toList();
      });
      _showSnackBar('↷ Đã làm lại', Colors.blue);
    }
  }

  // ─────────────────── IMAGE OPERATIONS ───────────────────

  Future<void> _cropImage(int index) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageList[index].file.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cắt ảnh',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Cắt ảnh'),
        ],
      );

      if (croppedFile != null && mounted) {
        setState(() {
          imageList[index] = ImageItem(
            file: File(croppedFile.path),
            id: UniqueKey().toString(),
          );
          _saveToHistory();
        });
        _showSnackBar('✓ Đã cắt ảnh thành công', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('✗ Lỗi khi cắt ảnh: $e', Colors.red);
      }
    }
  }

  Future<void> _rotateImage(int index, {int degrees = 90}) async {
    if (!mounted) return;
    setState(() => isProcessing = true);

    try {
      final bytes = await imageList[index].file.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        throw Exception('Không thể đọc ảnh');
      }

      final rotatedImage = img.copyRotate(originalImage, angle: degrees);
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/rotated_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final rotatedFile = File(tempPath);
      await rotatedFile.writeAsBytes(img.encodeJpg(rotatedImage, quality: 95));

      if (mounted) {
        setState(() {
          imageList[index] = ImageItem(
            file: rotatedFile,
            id: UniqueKey().toString(),
          );
          _saveToHistory();
          isProcessing = false;
        });
        _showSnackBar('↻ Đã xoay ảnh ${degrees}°', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isProcessing = false);
        _showSnackBar('✗ Lỗi khi xoay ảnh: $e', Colors.red);
      }
    }
  }

  Future<void> _deleteImage(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            const Text('Xóa ảnh?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                imageList[index].file,
                height: 120,
                fit: BoxFit.cover,
                cacheWidth: 240,
              ),
            ),
            const SizedBox(height: 12),
            Text('Bạn có chắc muốn xóa trang ${index + 1}?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      if (imageList.length == 1) {
        _showSnackBar('⚠ Cần ít nhất 1 ảnh', Colors.orange);
        return;
      }

      setState(() {
        imageList.removeAt(index);
        if (selectedIndex == index) {
          selectedIndex = null;
        } else if (selectedIndex != null && selectedIndex! > index) {
          selectedIndex = selectedIndex! - 1;
        }
        _saveToHistory();
      });
      _showSnackBar('✓ Đã xóa trang ${index + 1}', Colors.green);
    }
  }

  Future<void> _addImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 90);

    if (images.isNotEmpty && mounted) {
      setState(() {
        for (var img in images) {
          imageList.add(ImageItem(
            file: File(img.path),
            id: UniqueKey().toString(),
          ));
        }
        _saveToHistory();
      });
      _showSnackBar('✓ Đã thêm ${images.length} ảnh', Colors.green);
    }
  }

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);

    if (photo != null && mounted) {
      setState(() {
        imageList.add(ImageItem(
          file: File(photo.path),
          id: UniqueKey().toString(),
        ));
        _saveToHistory();
      });
      _showSnackBar('✓ Đã chụp ảnh mới', Colors.green);
    }
  }

  Future<void> _adjustBrightness(int index) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        int brightness = 0;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Điều chỉnh độ sáng'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: brightness.toDouble(),
                  min: -100,
                  max: 100,
                  divisions: 20,
                  label: brightness.toString(),
                  onChanged: (value) {
                    setDialogState(() => brightness = value.round());
                  },
                ),
                Text('Độ sáng: $brightness%'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, brightness),
                child: const Text('Áp dụng'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null && result != 0) {
      await _applyBrightness(index, result);
    }
  }

  Future<void> _applyBrightness(int index, int amount) async {
    if (!mounted) return;
    setState(() => isProcessing = true);

    try {
      final bytes = await imageList[index].file.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) throw Exception('Không thể đọc ảnh');

      final adjustedImage = img.adjustColor(originalImage, brightness: amount / 100);

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/bright_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final adjustedFile = File(tempPath);
      await adjustedFile.writeAsBytes(img.encodeJpg(adjustedImage, quality: 95));

      if (mounted) {
        setState(() {
          imageList[index] = ImageItem(
            file: adjustedFile,
            id: UniqueKey().toString(),
          );
          _saveToHistory();
          isProcessing = false;
        });
        _showSnackBar('✓ Đã điều chỉnh độ sáng', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isProcessing = false);
        _showSnackBar('✗ Lỗi: $e', Colors.red);
      }
    }
  }

  void _viewFullScreen(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          images: imageList.map((e) => e.file).toList(),
          initialIndex: index,
          onImageEdited: (editedIndex, editedFile) {
            setState(() {
              imageList[editedIndex] = ImageItem(
                file: editedFile,
                id: UniqueKey().toString(),
              );
              _saveToHistory();
            });
          },
          onImageDeleted: (deletedIndex) {
            if (imageList.length > 1) {
              setState(() {
                imageList.removeAt(deletedIndex);
                _saveToHistory();
              });
            }
          },
        ),
      ),
    );
  }

  void _showEditOptions(int index) {
    EditOptionsSheet.show(
      context: context,
      index: index,
      onCrop: () => _cropImage(index),
      onRotate90: () => _rotateImage(index, degrees: 90),
      onRotate270: () => _rotateImage(index, degrees: -90),
      onRotate180: () => _rotateImage(index, degrees: 180),
      onAdjustBrightness: () => _adjustBrightness(index),
      onViewFullScreen: () => _viewFullScreen(index),
      onDelete: () => _deleteImage(index),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─────────────────── BUILD METHOD ───────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              // Preview section khi chọn ảnh
              if (selectedIndex != null)
                ImagePreviewSection(
                  imageItem: imageList[selectedIndex!],
                  index: selectedIndex!,
                  onClose: () => setState(() => selectedIndex = null),
                  onViewFullScreen: () => _viewFullScreen(selectedIndex!),
                ),
              
              // Image list/grid
              Expanded(
                child: isGridView ? _buildGridView() : _buildListView(),
              ),
            ],
          ),
          
          // Loading overlay
          if (isProcessing) const EditLoadingOverlay(),
        ],
      ),
      floatingActionButton: EditFloatingButtons(
        animationController: _fabAnimationController,
        onAddImages: _addImages,
        onCaptureImage: _captureImage,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getPrimaryGradient(isDark),
        ),
      ),
      title: Text(
        'Chỉnh sửa (${imageList.length} ảnh)',
        style: const TextStyle(color: Colors.white),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        // Undo
        IconButton(
          icon: Icon(Icons.undo, color: canUndo ? Colors.white : Colors.white38),
          onPressed: canUndo ? _undo : null,
          tooltip: 'Hoàn tác',
        ),
        // Redo
        IconButton(
          icon: Icon(Icons.redo, color: canRedo ? Colors.white : Colors.white38),
          onPressed: canRedo ? _redo : null,
          tooltip: 'Làm lại',
        ),
        // Toggle view
        IconButton(
          icon: Icon(isGridView ? Icons.view_list : Icons.grid_view, color: Colors.white),
          onPressed: () => setState(() => isGridView = !isGridView),
          tooltip: isGridView ? 'Xem danh sách' : 'Xem lưới',
        ),
        // Complete
        IconButton(
          icon: const Icon(Icons.check, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, imageList.map((e) => e.file).toList());
          },
          tooltip: 'Hoàn tất',
        ),
      ],
    );
  }

  Widget _buildListView() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: imageList.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = imageList.removeAt(oldIndex);
          imageList.insert(newIndex, item);
          _saveToHistory();
        });
      },
      itemBuilder: (context, index) => _buildListItem(index),
    );
  }

  Widget _buildListItem(int index) {
    final isSelected = selectedIndex == index;

    return Card(
      key: ValueKey(imageList[index].id),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => selectedIndex = isSelected ? null : index),
        onLongPress: () => _showEditOptions(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      imageList[index].file,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      cacheWidth: 120,
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trang ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFileName(imageList[index].file.path),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Quick actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QuickActionButton(
                    icon: Icons.crop,
                    color: Colors.blue,
                    onTap: () => _cropImage(index),
                    tooltip: 'Cắt',
                  ),
                  const SizedBox(width: 4),
                  QuickActionButton(
                    icon: Icons.rotate_right,
                    color: Colors.green,
                    onTap: () => _rotateImage(index),
                    tooltip: 'Xoay',
                  ),
                  const SizedBox(width: 4),
                  QuickActionButton(
                    icon: Icons.more_vert,
                    color: Colors.grey,
                    onTap: () => _showEditOptions(index),
                    tooltip: 'Thêm',
                  ),
                ],
              ),
              
              // Drag handle
              const SizedBox(width: 8),
              const Icon(Icons.drag_handle, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: imageList.length,
      itemBuilder: (context, index) => _buildGridItem(index),
    );
  }

  Widget _buildGridItem(int index) {
    final isSelected = selectedIndex == index;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => selectedIndex = isSelected ? null : index),
        onLongPress: () => _showEditOptions(index),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      imageList[index].file,
                      fit: BoxFit.cover,
                      cacheWidth: 300,
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MiniIconButton(
                    icon: Icons.crop,
                    color: Colors.blue,
                    onTap: () => _cropImage(index),
                  ),
                  MiniIconButton(
                    icon: Icons.rotate_right,
                    color: Colors.green,
                    onTap: () => _rotateImage(index),
                  ),
                  MiniIconButton(
                    icon: Icons.fullscreen,
                    color: Colors.indigo,
                    onTap: () => _viewFullScreen(index),
                  ),
                  MiniIconButton(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    onTap: () => _deleteImage(index),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFileName(String path) {
    final name = path.split('/').last;
    if (name.length > 25) {
      return '${name.substring(0, 22)}...';
    }
    return name;
  }
}
