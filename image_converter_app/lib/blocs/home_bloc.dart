import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../services/document_service.dart';
import '../services/cache_service.dart';

// --- Events ---
abstract class HomeEvent {}

// Chọn ảnh ban đầu (Từ nút bấm trên HomeScreen)
class PickImageRequested extends HomeEvent {
  final bool fromCamera;
  PickImageRequested(this.fromCamera);
}

// EVENT QUAN TRỌNG: Nhận danh sách ảnh đã qua Chỉnh sửa/Sắp xếp để Upload
class UploadEditedImagesEvent extends HomeEvent {
  final List<File> editedFiles;
  final String? outputName; // Tên file tùy chỉnh (có thể null)
  UploadEditedImagesEvent(this.editedFiles, {this.outputName});
}

// EVENT GỘP PDF: Nhận danh sách ID file PDF cần ghép
class MergePdfsRequested extends HomeEvent {
  final List<int> ids;
  MergePdfsRequested(this.ids);
}

class LoadHistoryRequested extends HomeEvent {
  final bool forceRefresh; // Bắt buộc load từ API, bỏ qua cache
  LoadHistoryRequested({this.forceRefresh = false});
}

class DeleteDocumentRequested extends HomeEvent {
  final int id;
  DeleteDocumentRequested(this.id);
}

class RenameDocumentRequested extends HomeEvent {
  final int id;
  final String newName;
  RenameDocumentRequested(this.id, this.newName);
}

// --- States ---
abstract class HomeState {}
class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}
class HomeSuccess extends HomeState {
  final String message;
  final String? imageUrl;
  HomeSuccess(this.message, {this.imageUrl});
}
class HomeFailure extends HomeState {
  final String error;
  HomeFailure(this.error);
}
class HistoryLoaded extends HomeState {
  final List<dynamic> documents;
  final bool isFromCache; // Đánh dấu data từ cache hay API
  final DateTime? cacheTime; // Thời điểm cache
  HistoryLoaded(this.documents, {this.isFromCache = false, this.cacheTime});
}

// --- Bloc ---
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final DocumentService _documentService = DocumentService();
  final ImagePicker _picker = ImagePicker();

  HomeBloc() : super(HomeInitial()) {

    // 1. Xử lý chọn ảnh (Sửa lại để chỉ chọn, không upload ngay để chờ Edit)
    on<PickImageRequested>((event, emit) async {
      try {
        List<XFile> images = [];
        if (event.fromCamera) {
          final XFile? photo = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 70,
          );
          if (photo != null) images.add(photo);
        } else {
          images = await _picker.pickMultiImage(
            imageQuality: 70,
            maxWidth: 1024,
          );
        }

        if (images.isNotEmpty) {
          // Sau khi chọn xong, HomeScreen sẽ điều hướng sang màn hình Edit.
          // Sau khi Edit xong, HomeScreen sẽ gọi UploadEditedImagesEvent.
          // Bạn có thể emit một state trung gian nếu muốn báo đã chọn xong.
        }
      } catch (e) {
        emit(HomeFailure("Lỗi chọn ảnh: ${e.toString()}"));
      }
    });

    // 2. Xử lý Upload sau khi đã Cắt ảnh (Crop) hoặc Sắp xếp
    on<UploadEditedImagesEvent>((event, emit) async {
      emit(HomeLoading());
      try {
        final result = await _documentService.uploadImages(
          event.editedFiles,
          outputName: event.outputName,
        );
        if (result != null) {
          // Invalidate cache vì có document mới
          final cacheService = await CacheService.getInstance();
          await cacheService.invalidateDocumentsCache();

          emit(HomeSuccess("Chuyển đổi thành công ${event.editedFiles.length} ảnh!"));
          add(LoadHistoryRequested(forceRefresh: true));
        }
      } catch (e) {
        emit(HomeFailure("Lỗi upload: ${e.toString()}"));
        // ✅ Tự động reload history sau lỗi để danh sách file hiển thị lại
        add(LoadHistoryRequested());
      }
    });

    // 3. Xử lý Gộp PDF (Ghép file)
    on<MergePdfsRequested>((event, emit) async {
      emit(HomeLoading());
      try {
        await _documentService.mergePdfs(event.ids);

        // Invalidate cache vì có document mới
        final cacheService = await CacheService.getInstance();
        await cacheService.invalidateDocumentsCache();

        emit(HomeSuccess("Ghép file PDF thành công!"));
        add(LoadHistoryRequested(forceRefresh: true));
      } catch (e) {
        emit(HomeFailure("Lỗi ghép file: ${e.toString()}"));
        // ✅ Tự động reload history sau lỗi để danh sách file hiển thị lại
        add(LoadHistoryRequested());
      }
    });

    // 4. Xử lý lấy lịch sử (CÓ CACHING)
    on<LoadHistoryRequested>((event, emit) async {
      try {
        final cacheService = await CacheService.getInstance();

        // BƯỚC 1: Nếu không force refresh, thử load từ cache trước
        if (!event.forceRefresh) {
          final cachedDocs = await cacheService.getCachedDocuments();
          if (cachedDocs != null && cachedDocs.isNotEmpty) {
            // Emit data từ cache ngay lập tức (UX nhanh)
            final cacheTime = cacheService.getDocumentsCacheTime();
            emit(HistoryLoaded(
              cachedDocs,
              isFromCache: true,
              cacheTime: cacheTime,
            ));
            print('⚡ Hiển thị ${cachedDocs.length} docs từ cache');

            // Nếu cache vẫn còn valid, không cần call API
            if (cacheService.isDocumentsCacheValid()) {
              print('✅ Cache còn valid, bỏ qua API call');
              return;
            }
            // Cache hết hạn -> tiếp tục call API để refresh
            print('🔄 Cache hết hạn, đang refresh từ API...');
          }
        } else {
          // Force refresh -> show loading
          emit(HomeLoading());
        }

        // BƯỚC 2: Load từ API
        final docs = await _documentService.getHistory();

        // BƯỚC 3: Cache data mới
        await cacheService.cacheDocuments(docs);

        // BƯỚC 4: Emit data từ API
        emit(HistoryLoaded(docs, isFromCache: false));
        print('🌐 Đã load ${docs.length} docs từ API và cache');

      } catch (e) {
        // Nếu API fail, thử fallback về cache (kể cả đã hết hạn)
        try {
          final cacheService = await CacheService.getInstance();
          final cachedDocs = await cacheService.getCachedDocuments(ignoreExpiry: true);
          if (cachedDocs != null && cachedDocs.isNotEmpty) {
            final cacheTime = cacheService.getDocumentsCacheTime();
            emit(HistoryLoaded(
              cachedDocs,
              isFromCache: true,
              cacheTime: cacheTime,
            ));
            print('⚠️ API lỗi, fallback về cache (${cachedDocs.length} docs)');
            return;
          }
        } catch (_) {}

        // Không có cache -> emit error
        emit(HomeFailure(e.toString()));
      }
    });

    // 5. Xử lý xóa (CÓ INVALIDATE CACHE)
    on<DeleteDocumentRequested>((event, emit) async {
      try {
        await _documentService.deleteDocument(event.id);

        // Invalidate cache vì document bị xóa
        final cacheService = await CacheService.getInstance();
        await cacheService.invalidateDocumentsCache();

        add(LoadHistoryRequested(forceRefresh: true));
      } catch (e) {
        emit(HomeFailure("Không xóa được: ${e.toString()}"));
        // ✅ Tự động reload history sau lỗi
        add(LoadHistoryRequested());
      }
    });

    // 6. Xử lý đổi tên (CÓ INVALIDATE CACHE)
    on<RenameDocumentRequested>((event, emit) async {
      try {
        await _documentService.renameDocument(event.id, event.newName);

        // Invalidate cache vì document bị đổi tên
        final cacheService = await CacheService.getInstance();
        await cacheService.invalidateDocumentsCache();

        add(LoadHistoryRequested(forceRefresh: true));
        emit(HomeSuccess("Đổi tên thành công!"));
      } catch (e) {
        emit(HomeFailure("Không đổi tên được: ${e.toString()}"));
        // ✅ Tự động reload history sau lỗi
        add(LoadHistoryRequested());
      }
    });
  }
}
