import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

// ═══════════════════════════════════════════════════════════════
//                    MAIN EDIT IMAGE SCREEN
// ═══════════════════════════════════════════════════════════════

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
    // Cleanup temp files
    _cleanupTempFiles();
    super.dispose();
  }

  Future<void> _cleanupTempFiles() async {
    // Optional: Clean up temporary rotated/edited files
  }

  // ─────────────────── HISTORY MANAGEMENT ───────────────────
  void _saveToHistory() {
    // Remove future states if we're not at the end
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    // Deep copy current state
    _history.add(imageList.map((e) => e.copy()).toList());
    _historyIndex = _history.length - 1;

    // Limit history to 20 states to save memory
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

  /// Crop ảnh tại index
  Future<void> _cropImage(int index) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageList[index].file.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cắt ảnh - Trang ${index + 1}',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: Theme.of(context).primaryColor,
            cropGridColor: Colors.white54,
            cropFrameColor: Colors.white,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Cắt ảnh - Trang ${index + 1}',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
            rotateButtonsHidden: false,
            resetButtonHidden: false,
          ),
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
        _showSnackBar('✓ Đã cắt ảnh trang ${index + 1}', Colors.green);
      }
    } catch (e) {
      _showSnackBar('✗ Lỗi khi cắt ảnh: $e', Colors.red);
    }
  }

  /// Xoay ảnh 90 độ theo chiều kim đồng hồ
  Future<void> _rotateImage(int index, {int degrees = 90}) async {
    setState(() => isProcessing = true);

    try {
      final bytes = await imageList[index].file.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        throw Exception('Không thể đọc ảnh');
      }

      // Xoay ảnh
      final rotatedImage = img.copyRotate(originalImage, angle: degrees);

      // Lưu vào temp file
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

  /// Xóa ảnh với confirmation dialog
  Future<void> _deleteImage(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            const Text('Xác nhận xóa'),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        imageList.removeAt(index);
        if (selectedIndex == index) selectedIndex = null;
        _saveToHistory();
      });
      _showSnackBar('🗑 Đã xóa trang ${index + 1}', Colors.orange);
    }
  }

  /// Thêm ảnh mới từ gallery
  Future<void> _addImages() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 90,
      );

      if (pickedFiles.isNotEmpty && mounted) {
        setState(() {
          imageList.addAll(
            pickedFiles.map((xFile) => ImageItem(
              file: File(xFile.path),
              id: UniqueKey().toString(),
            )),
          );
          _saveToHistory();
        });
        _showSnackBar('✓ Đã thêm ${pickedFiles.length} ảnh', Colors.green);
      }
    } catch (e) {
      _showSnackBar('✗ Lỗi khi thêm ảnh: $e', Colors.red);
    }
  }

  /// Chụp ảnh mới từ camera
  Future<void> _captureImage() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (photo != null && mounted) {
        setState(() {
          imageList.add(ImageItem(
            file: File(photo.path),
            id: UniqueKey().toString(),
          ));
          _saveToHistory();
        });
        _showSnackBar('📷 Đã chụp ảnh mới', Colors.green);
      }
    } catch (e) {
      _showSnackBar('✗ Lỗi khi chụp ảnh: $e', Colors.red);
    }
  }

  /// Điều chỉnh độ sáng
  Future<void> _adjustBrightness(int index) async {
    double brightness = 0;

    final result = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '☀ Điều chỉnh độ sáng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.brightness_low),
                  Expanded(
                    child: Slider(
                      value: brightness,
                      min: -100,
                      max: 100,
                      divisions: 200,
                      label: brightness.round().toString(),
                      onChanged: (v) => setModalState(() => brightness = v),
                    ),
                  ),
                  const Icon(Icons.brightness_high),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, brightness),
                    child: const Text('Áp dụng'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && result != 0) {
      await _applyBrightness(index, result.round());
    }
  }

  Future<void> _applyBrightness(int index, int amount) async {
    setState(() => isProcessing = true);

    try {
      final bytes = await imageList[index].file.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) throw Exception('Không thể đọc ảnh');

      // Điều chỉnh độ sáng
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

  /// Xem ảnh full screen
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
            setState(() {
              imageList.removeAt(deletedIndex);
              _saveToHistory();
            });
          },
        ),
      ),
    );
  }

  /// Hiện bottom sheet với các tùy chọn chỉnh sửa
  void _showEditOptions(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Chỉnh sửa Trang ${index + 1}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _buildOptionButton(
                  icon: Icons.crop,
                  label: 'Cắt',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _cropImage(index);
                  },
                ),
                _buildOptionButton(
                  icon: Icons.rotate_right,
                  label: 'Xoay 90°',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _rotateImage(index);
                  },
                ),
                _buildOptionButton(
                  icon: Icons.rotate_left,
                  label: 'Xoay -90°',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.pop(context);
                    _rotateImage(index, degrees: -90);
                  },
                ),
                _buildOptionButton(
                  icon: Icons.flip,
                  label: 'Xoay 180°',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _rotateImage(index, degrees: 180);
                  },
                ),
                _buildOptionButton(
                  icon: Icons.brightness_6,
                  label: 'Độ sáng',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _adjustBrightness(index);
                  },
                ),
                _buildOptionButton(
                  icon: Icons.fullscreen,
                  label: 'Xem',
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.pop(context);
                    _viewFullScreen(index);
                  },
                ),
                _buildOptionButton(
                  icon: Icons.delete_outline,
                  label: 'Xóa',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _deleteImage(index);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─────────────────── BUILD UI ───────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              // Selected image preview
              if (selectedIndex != null) _buildPreviewSection(),
              // Main content
              Expanded(
                child: isGridView ? _buildGridView() : _buildListView(),
              ),
            ],
          ),
          // Loading overlay
          if (isProcessing) _buildLoadingOverlay(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chỉnh sửa ảnh'),
          Text(
            '${imageList.length} trang',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      actions: [
        // Undo button
        IconButton(
          icon: Icon(
            Icons.undo_rounded,
            color: canUndo ? null : Colors.grey.withOpacity(0.5),
          ),
          onPressed: canUndo ? _undo : null,
          tooltip: 'Hoàn tác',
        ),
        // Redo button
        IconButton(
          icon: Icon(
            Icons.redo_rounded,
            color: canRedo ? null : Colors.grey.withOpacity(0.5),
          ),
          onPressed: canRedo ? _redo : null,
          tooltip: 'Làm lại',
        ),
        // View toggle
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              key: ValueKey(isGridView),
            ),
          ),
          onPressed: () => setState(() => isGridView = !isGridView),
          tooltip: isGridView ? 'Danh sách' : 'Lưới',
        ),
        // Confirm button
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: ElevatedButton.icon(
            onPressed: imageList.isEmpty
                ? null
                : () => Navigator.pop(context, imageList.map((e) => e.file).toList()),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Xong'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 200,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              imageList[selectedIndex!].file,
              fit: BoxFit.contain,
              cacheWidth: 600,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() => selectedIndex = null),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Trang ${selectedIndex! + 1}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 80),
      itemCount: imageList.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
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

    return AnimatedContainer(
      key: ValueKey(imageList[index].id),
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: Theme.of(context).primaryColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isSelected ? 0.15 : 0.05),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => setState(() =>
          selectedIndex = selectedIndex == index ? null : index),
          onLongPress: () => _showEditOptions(index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail với số trang
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getFileName(imageList[index].file.path),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Quick action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQuickActionButton(
                      icon: Icons.crop_rounded,
                      color: Colors.blue,
                      onTap: () => _cropImage(index),
                      tooltip: 'Cắt',
                    ),
                    _buildQuickActionButton(
                      icon: Icons.rotate_right_rounded,
                      color: Colors.green,
                      onTap: () => _rotateImage(index),
                      tooltip: 'Xoay',
                    ),
                    _buildQuickActionButton(
                      icon: Icons.more_vert_rounded,
                      color: Colors.grey,
                      onTap: () => _showEditOptions(index),
                      tooltip: 'Thêm',
                    ),
                    const SizedBox(width: 4),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: imageList.length,
      itemBuilder: (context, index) => _buildGridItem(index),
    );
  }

  Widget _buildGridItem(int index) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() =>
      selectedIndex = selectedIndex == index ? null : index),
      onLongPress: () => _showEditOptions(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Theme.of(context).primaryColor, width: 3)
              : Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.2 : 0.1),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                imageList[index].file,
                fit: BoxFit.cover,
                cacheWidth: 300,
              ),
              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
              ),
              // Page number
              Positioned(
                top: 6,
                left: 6,
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
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Quick action buttons
              Positioned(
                bottom: 6,
                right: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMiniIconButton(
                      Icons.crop,
                      Colors.blue,
                          () => _cropImage(index),
                    ),
                    const SizedBox(width: 4),
                    _buildMiniIconButton(
                      Icons.rotate_right,
                      Colors.green,
                          () => _rotateImage(index),
                    ),
                  ],
                ),
              ),
              // Selection indicator
              if (isSelected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniIconButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang xử lý...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Camera button
        ScaleTransition(
          scale: _fabAnimationController,
          child: FloatingActionButton.small(
            heroTag: 'camera',
            onPressed: _captureImage,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.camera_alt),
          ),
        ),
        const SizedBox(height: 8),
        // Add image button
        ScaleTransition(
          scale: _fabAnimationController,
          child: FloatingActionButton(
            heroTag: 'add',
            onPressed: _addImages,
            child: const Icon(Icons.add_photo_alternate),
          ),
        ),
      ],
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

// ═══════════════════════════════════════════════════════════════
//                    IMAGE ITEM MODEL
// ═══════════════════════════════════════════════════════════════

class ImageItem {
  final File file;
  final String id;

  ImageItem({required this.file, required this.id});

  ImageItem copy() => ImageItem(file: file, id: id);
}

// ═══════════════════════════════════════════════════════════════
//                 FULL SCREEN IMAGE VIEWER
// ═══════════════════════════════════════════════════════════════

class FullScreenImageViewer extends StatefulWidget {
  final List<File> images;
  final int initialIndex;
  final Function(int, File) onImageEdited;
  final Function(int) onImageDeleted;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.onImageEdited,
    required this.onImageDeleted,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int currentIndex;
  late List<File> images;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    images = List.from(widget.images);
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  Future<void> _cropCurrent() async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: images[currentIndex].path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cắt ảnh',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          backgroundColor: Colors.black,
        ),
        IOSUiSettings(title: 'Cắt ảnh'),
      ],
    );

    if (croppedFile != null && mounted) {
      setState(() {
        images[currentIndex] = File(croppedFile.path);
      });
      widget.onImageEdited(currentIndex, images[currentIndex]);
    }
  }

  Future<void> _rotateCurrent() async {
    try {
      final bytes = await images[currentIndex].readAsBytes();
      final originalImage = img.decodeImage(bytes);
      if (originalImage == null) return;

      final rotated = img.copyRotate(originalImage, angle: 90);
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/rotated_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final rotatedFile = File(tempPath);
      await rotatedFile.writeAsBytes(img.encodeJpg(rotated, quality: 95));

      if (mounted) {
        setState(() {
          images[currentIndex] = rotatedFile;
        });
        widget.onImageEdited(currentIndex, rotatedFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _deleteCurrent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ảnh?'),
        content: const Text('Bạn có chắc muốn xóa ảnh này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      widget.onImageDeleted(currentIndex);
      if (images.length == 1) {
        Navigator.pop(context);
      } else {
        setState(() {
          images.removeAt(currentIndex);
          if (currentIndex >= images.length) {
            currentIndex = images.length - 1;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showControls
          ? AppBar(
        backgroundColor: Colors.black54,
        elevation: 0,
        title: Text(
          '${currentIndex + 1} / ${images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.crop),
            onPressed: _cropCurrent,
            tooltip: 'Cắt',
          ),
          IconButton(
            icon: const Icon(Icons.rotate_right),
            onPressed: _rotateCurrent,
            tooltip: 'Xoay',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteCurrent,
            tooltip: 'Xóa',
          ),
        ],
      )
          : null,
      body: GestureDetector(
        onTap: _toggleControls,
        child: PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (index) => setState(() => currentIndex = index),
          itemBuilder: (context, index) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.file(images[index]),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _showControls
          ? Container(
        color: Colors.black54,
        padding: const EdgeInsets.all(8),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: currentIndex == index
                            ? Colors.white
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        images[index],
                        fit: BoxFit.cover,
                        cacheWidth: 100,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      )
          : null,
    );
  }
}