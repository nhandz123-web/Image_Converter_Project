/// Model đại diện cho gói VIP từ API
class VipPackage {
  final int id;
  final String title;
  final String description;
  final String short; // HTML content for benefits
  final int timeMonths;
  final int price;
  final String productId;

  const VipPackage({
    required this.id,
    required this.title,
    required this.description,
    required this.short,
    required this.timeMonths,
    required this.price,
    required this.productId,
  });

  factory VipPackage.fromJson(Map<String, dynamic> json) {
    return VipPackage(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      short: json['short'] as String? ?? '',
      timeMonths: json['time_months'] as int,
      price: json['price'] as int,
      productId: json['product_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'short': short,
      'time_months': timeMonths,
      'price': price,
      'product_id': productId,
    };
  }

  /// Lấy danh sách benefits từ HTML short description
  List<String> get benefits {
    // Parse HTML để lấy các li items
    final regex = RegExp(r'<li>(.*?)</li>', dotAll: true);
    final matches = regex.allMatches(short);
    return matches.map((m) {
      // Remove HTML tags từ content
      String content = m.group(1) ?? '';
      content = content.replaceAll(RegExp(r'<[^>]*>'), '');
      content = content.replaceAll('&nbsp;', ' ');
      return content.trim();
    }).where((s) => s.isNotEmpty).toList();
  }

  /// Format giá tiền VND
  String get formattedPrice {
    final formatter = price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '${formatter}đ';
  }

  /// Format thời hạn
  String get formattedDuration {
    if (timeMonths == 1) {
      return '1 tháng';
    } else if (timeMonths == 12) {
      return '1 năm';
    } else if (timeMonths == 6) {
      return '6 tháng';
    } else {
      return '$timeMonths tháng';
    }
  }

  /// Tính giá theo tháng
  int get pricePerMonth {
    return (price / timeMonths).round();
  }

  /// Format giá theo tháng
  String get formattedPricePerMonth {
    final formatter = pricePerMonth.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '${formatter}đ/tháng';
  }
}

/// Response wrapper cho API
class VipPackageResponse {
  final bool success;
  final List<VipPackage> data;

  const VipPackageResponse({
    required this.success,
    required this.data,
  });

  factory VipPackageResponse.fromJson(Map<String, dynamic> json) {
    return VipPackageResponse(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => VipPackage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
