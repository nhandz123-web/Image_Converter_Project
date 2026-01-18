import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service quản lý cache cho app
/// Sử dụng SharedPreferences để lưu trữ dữ liệu đơn giản
class CacheService {
  static const String _documentsKey = 'cached_documents';
  static const String _documentsCacheTimeKey = 'cached_documents_time';
  static const String _userInfoKey = 'cached_user_info';
  static const String _userInfoCacheTimeKey = 'cached_user_info_time';

  // Thời gian cache hợp lệ (mặc định 1 giờ)
  static const Duration defaultCacheDuration = Duration(hours: 1);
  
  // Thời gian cache cho documents (30 phút - vì data thay đổi thường xuyên hơn)
  static const Duration documentsCacheDuration = Duration(minutes: 30);

  // Singleton pattern
  static CacheService? _instance;
  static SharedPreferences? _prefs;

  CacheService._();

  static Future<CacheService> getInstance() async {
    if (_instance == null) {
      _instance = CacheService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // ==================== DOCUMENTS CACHE ====================

  /// Lưu danh sách documents vào cache
  Future<bool> cacheDocuments(List<dynamic> documents) async {
    try {
      final jsonString = jsonEncode(documents);
      final now = DateTime.now().millisecondsSinceEpoch;
      
      await _prefs?.setString(_documentsKey, jsonString);
      await _prefs?.setInt(_documentsCacheTimeKey, now);
      
      print('📦 Đã cache ${documents.length} documents');
      return true;
    } catch (e) {
      print('❌ Lỗi cache documents: $e');
      return false;
    }
  }

  /// Lấy documents từ cache
  /// Trả về null nếu cache không tồn tại hoặc đã hết hạn
  Future<List<dynamic>?> getCachedDocuments({bool ignoreExpiry = false}) async {
    try {
      final jsonString = _prefs?.getString(_documentsKey);
      final cacheTime = _prefs?.getInt(_documentsCacheTimeKey);

      if (jsonString == null || cacheTime == null) {
        print('📭 Không có cache documents');
        return null;
      }

      // Kiểm tra cache còn hợp lệ không
      if (!ignoreExpiry) {
        final cachedAt = DateTime.fromMillisecondsSinceEpoch(cacheTime);
        final now = DateTime.now();
        final difference = now.difference(cachedAt);

        if (difference > documentsCacheDuration) {
          print('⏰ Cache documents đã hết hạn (${difference.inMinutes} phút)');
          return null;
        }
      }

      final documents = jsonDecode(jsonString) as List<dynamic>;
      print('📂 Đọc ${documents.length} documents từ cache');
      return documents;
    } catch (e) {
      print('❌ Lỗi đọc cache documents: $e');
      return null;
    }
  }

  /// Xóa cache documents
  Future<void> clearDocumentsCache() async {
    await _prefs?.remove(_documentsKey);
    await _prefs?.remove(_documentsCacheTimeKey);
    print('🗑️ Đã xóa cache documents');
  }

  /// Kiểm tra cache documents có hợp lệ không
  bool isDocumentsCacheValid() {
    final cacheTime = _prefs?.getInt(_documentsCacheTimeKey);
    if (cacheTime == null) return false;

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(cacheTime);
    final now = DateTime.now();
    return now.difference(cachedAt) <= documentsCacheDuration;
  }

  /// Lấy thời gian cache documents gần nhất
  DateTime? getDocumentsCacheTime() {
    final cacheTime = _prefs?.getInt(_documentsCacheTimeKey);
    if (cacheTime == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(cacheTime);
  }

  // ==================== USER INFO CACHE ====================

  /// Lưu thông tin user vào cache
  Future<bool> cacheUserInfo(Map<String, dynamic> userInfo) async {
    try {
      final jsonString = jsonEncode(userInfo);
      final now = DateTime.now().millisecondsSinceEpoch;
      
      await _prefs?.setString(_userInfoKey, jsonString);
      await _prefs?.setInt(_userInfoCacheTimeKey, now);
      
      print('📦 Đã cache user info');
      return true;
    } catch (e) {
      print('❌ Lỗi cache user info: $e');
      return false;
    }
  }

  /// Lấy user info từ cache
  Future<Map<String, dynamic>?> getCachedUserInfo({bool ignoreExpiry = false}) async {
    try {
      final jsonString = _prefs?.getString(_userInfoKey);
      final cacheTime = _prefs?.getInt(_userInfoCacheTimeKey);

      if (jsonString == null || cacheTime == null) {
        return null;
      }

      if (!ignoreExpiry) {
        final cachedAt = DateTime.fromMillisecondsSinceEpoch(cacheTime);
        final now = DateTime.now();
        if (now.difference(cachedAt) > defaultCacheDuration) {
          return null;
        }
      }

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Lỗi đọc cache user info: $e');
      return null;
    }
  }

  /// Xóa cache user info
  Future<void> clearUserInfoCache() async {
    await _prefs?.remove(_userInfoKey);
    await _prefs?.remove(_userInfoCacheTimeKey);
  }

  // ==================== UTILITY ====================

  /// Xóa tất cả cache
  Future<void> clearAllCache() async {
    await clearDocumentsCache();
    await clearUserInfoCache();
    print('🗑️ Đã xóa tất cả cache');
  }

  /// Invalidate documents cache (đánh dấu cần refresh)
  /// Gọi hàm này sau khi upload, delete, rename document
  Future<void> invalidateDocumentsCache() async {
    // Thay vì xóa hoàn toàn, set thời gian cache về 0 để force refresh
    // nhưng vẫn giữ data cũ để hiển thị tạm thời
    await _prefs?.setInt(_documentsCacheTimeKey, 0);
    print('🔄 Đã invalidate cache documents');
  }
}
