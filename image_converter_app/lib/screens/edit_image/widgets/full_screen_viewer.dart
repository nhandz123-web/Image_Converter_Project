import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Widget xem ảnh toàn màn hình với các chức năng edit
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
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
      bottomNavigationBar: _showControls ? _buildThumbnailBar() : null,
    );
  }

  Widget _buildThumbnailBar() {
    return Container(
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
    );
  }
}
