import 'package:flutter/material.dart';
import 'edit_helpers.dart';

/// Bottom sheet hiển thị các tùy chọn chỉnh sửa ảnh
class EditOptionsSheet extends StatelessWidget {
  final int index;
  final VoidCallback onCrop;
  final VoidCallback onRotate90;
  final VoidCallback onRotate270;
  final VoidCallback onRotate180;
  final VoidCallback onAdjustBrightness;
  final VoidCallback onViewFullScreen;
  final VoidCallback onDelete;

  const EditOptionsSheet({
    super.key,
    required this.index,
    required this.onCrop,
    required this.onRotate90,
    required this.onRotate270,
    required this.onRotate180,
    required this.onAdjustBrightness,
    required this.onViewFullScreen,
    required this.onDelete,
  });

  /// Hiển thị bottom sheet
  static void show({
    required BuildContext context,
    required int index,
    required VoidCallback onCrop,
    required VoidCallback onRotate90,
    required VoidCallback onRotate270,
    required VoidCallback onRotate180,
    required VoidCallback onAdjustBrightness,
    required VoidCallback onViewFullScreen,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditOptionsSheet(
        index: index,
        onCrop: () {
          Navigator.pop(ctx);
          onCrop();
        },
        onRotate90: () {
          Navigator.pop(ctx);
          onRotate90();
        },
        onRotate270: () {
          Navigator.pop(ctx);
          onRotate270();
        },
        onRotate180: () {
          Navigator.pop(ctx);
          onRotate180();
        },
        onAdjustBrightness: () {
          Navigator.pop(ctx);
          onAdjustBrightness();
        },
        onViewFullScreen: () {
          Navigator.pop(ctx);
          onViewFullScreen();
        },
        onDelete: () {
          Navigator.pop(ctx);
          onDelete();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Text(
            'Chỉnh sửa Trang ${index + 1}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Options grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              EditOptionButton(
                icon: Icons.crop,
                label: 'Cắt',
                color: Colors.blue,
                onTap: onCrop,
              ),
              EditOptionButton(
                icon: Icons.rotate_right,
                label: 'Xoay 90°',
                color: Colors.green,
                onTap: onRotate90,
              ),
              EditOptionButton(
                icon: Icons.rotate_left,
                label: 'Xoay -90°',
                color: Colors.teal,
                onTap: onRotate270,
              ),
              EditOptionButton(
                icon: Icons.flip,
                label: 'Xoay 180°',
                color: Colors.purple,
                onTap: onRotate180,
              ),
              EditOptionButton(
                icon: Icons.brightness_6,
                label: 'Độ sáng',
                color: Colors.orange,
                onTap: onAdjustBrightness,
              ),
              EditOptionButton(
                icon: Icons.fullscreen,
                label: 'Xem',
                color: Colors.indigo,
                onTap: onViewFullScreen,
              ),
              EditOptionButton(
                icon: Icons.delete_outline,
                label: 'Xóa',
                color: Colors.red,
                onTap: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
