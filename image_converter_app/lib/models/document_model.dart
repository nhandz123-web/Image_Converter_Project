/// Model class đại diện cho một Document/File trong hệ thống
/// Sử dụng thay vì Map<String, dynamic> để có type-safety
class DocumentModel {
  final int id;
  final String name;
  final String type;
  final int size;
  final String? path;
  final String? inputPath;
  final List<String>? sourceImagesPaths;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DocumentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    this.path,
    this.inputPath,
    this.sourceImagesPaths,
    this.status = 'completed',
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor để parse từ JSON response của API
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    // Parse source_images_paths
    List<String>? sourceImages;
    if (json['source_images_paths'] != null) {
      if (json['source_images_paths'] is List) {
        sourceImages = (json['source_images_paths'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    // Parse created_at
    DateTime? createdAt;
    if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at'].toString());
      } catch (_) {}
    }

    // Parse updated_at
    DateTime? updatedAt;
    if (json['updated_at'] != null) {
      try {
        updatedAt = DateTime.parse(json['updated_at'].toString());
      } catch (_) {}
    }

    return DocumentModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? json['original_name']?.toString() ?? 'Không tên',
      type: json['type']?.toString() ?? 'pdf',
      size: json['size'] ?? 0,
      path: json['path']?.toString(),
      inputPath: json['input_path']?.toString(),
      sourceImagesPaths: sourceImages,
      status: json['status']?.toString() ?? 'completed',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convert về Map để gửi API (nếu cần)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'size': size,
      'path': path,
      'input_path': inputPath,
      'source_images_paths': sourceImagesPaths,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Format file size dễ đọc (VD: "2.45 MB")
  String get formattedSize {
    if (size <= 0) return "0 B";
    
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    int i = 0;
    double sizeDouble = size.toDouble();
    
    while (sizeDouble >= 1024 && i < suffixes.length - 1) {
      sizeDouble /= 1024;
      i++;
    }
    
    return "${sizeDouble.toStringAsFixed(2)} ${suffixes[i]}";
  }

  /// Format ngày tạo dễ đọc
  String get formattedCreatedAt {
    if (createdAt == null) return 'Không xác định';
    return '${createdAt!.day.toString().padLeft(2, '0')}/'
           '${createdAt!.month.toString().padLeft(2, '0')}/'
           '${createdAt!.year} '
           '${createdAt!.hour.toString().padLeft(2, '0')}:'
           '${createdAt!.minute.toString().padLeft(2, '0')}';
  }

  /// Kiểm tra có phải PDF hay không
  bool get isPdf => type.toLowerCase() == 'pdf' || name.toLowerCase().endsWith('.pdf');

  /// Kiểm tra có phải ảnh hay không
  bool get isImage {
    final imageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
    return imageTypes.contains(type.toLowerCase()) ||
           imageTypes.any((ext) => name.toLowerCase().endsWith('.$ext'));
  }

  /// Kiểm tra đã hoàn thành chưa
  bool get isCompleted => status.toLowerCase() == 'completed';

  /// Copy with method
  DocumentModel copyWith({
    int? id,
    String? name,
    String? type,
    int? size,
    String? path,
    String? inputPath,
    List<String>? sourceImagesPaths,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      size: size ?? this.size,
      path: path ?? this.path,
      inputPath: inputPath ?? this.inputPath,
      sourceImagesPaths: sourceImagesPaths ?? this.sourceImagesPaths,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'DocumentModel(id: $id, name: $name, type: $type, size: $formattedSize)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
