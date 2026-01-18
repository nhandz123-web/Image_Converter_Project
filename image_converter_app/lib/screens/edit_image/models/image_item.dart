import 'dart:io';

/// Model đại diện cho một item ảnh trong danh sách chỉnh sửa
class ImageItem {
  final File file;
  final String id;

  ImageItem({required this.file, required this.id});

  /// Tạo bản copy của ImageItem
  ImageItem copy() => ImageItem(file: file, id: id);
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageItem && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}
