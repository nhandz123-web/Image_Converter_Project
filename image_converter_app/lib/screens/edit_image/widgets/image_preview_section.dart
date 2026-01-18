import 'package:flutter/material.dart';
import '../models/image_item.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';

/// Widget hiển thị preview ảnh lớn ở phía trên
class ImagePreviewSection extends StatelessWidget {
  final ImageItem imageItem;
  final int index;
  final VoidCallback onClose;
  final VoidCallback onViewFullScreen;

  const ImagePreviewSection({
    super.key,
    required this.imageItem,
    required this.index,
    required this.onClose,
    required this.onViewFullScreen,
  });

  @override
  Widget build(BuildContext context) {
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
            // Ảnh preview
            Image.file(
              imageItem.file,
              fit: BoxFit.contain,
              cacheWidth: 600,
            ),
            
            // Nút đóng
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onClose,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
            
            // Badge số trang
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
                  'Trang ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            // Nút xem toàn màn hình
            Positioned(
              bottom: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                onPressed: onViewFullScreen,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
