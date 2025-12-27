import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../services/document_service.dart';

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
  UploadEditedImagesEvent(this.editedFiles);
}

// EVENT GỘP PDF: Nhận danh sách ID file PDF cần ghép
class MergePdfsRequested extends HomeEvent {
  final List<int> ids;
  MergePdfsRequested(this.ids);
}

class LoadHistoryRequested extends HomeEvent {}

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
  HistoryLoaded(this.documents);
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
        final result = await _documentService.uploadImages(event.editedFiles);
        if (result != null) {
          emit(HomeSuccess("Chuyển đổi thành công ${event.editedFiles.length} ảnh!"));
          add(LoadHistoryRequested());
        }
      } catch (e) {
        emit(HomeFailure("Lỗi upload: ${e.toString()}"));
      }
    });

    // 3. Xử lý Gộp PDF (Ghép file)
    on<MergePdfsRequested>((event, emit) async {
      emit(HomeLoading());
      try {
        await _documentService.mergePdfs(event.ids);
        emit(HomeSuccess("Ghép file PDF thành công!"));
        add(LoadHistoryRequested());
      } catch (e) {
        emit(HomeFailure("Lỗi ghép file: ${e.toString()}"));
      }
    });

    // 4. Xử lý lấy lịch sử (Giữ nguyên code cũ)
    on<LoadHistoryRequested>((event, emit) async {
      try {
        emit(HomeLoading());
        final docs = await _documentService.getHistory();
        emit(HistoryLoaded(docs));
      } catch (e) {
        emit(HomeFailure(e.toString()));
      }
    });

    // 5. Xử lý xóa (Giữ nguyên code cũ)
    on<DeleteDocumentRequested>((event, emit) async {
      try {
        await _documentService.deleteDocument(event.id);
        add(LoadHistoryRequested());
      } catch (e) {
        emit(HomeFailure("Không xóa được: ${e.toString()}"));
      }
    });

    // 6. Xử lý đổi tên (Giữ nguyên code cũ)
    on<RenameDocumentRequested>((event, emit) async {
      try {
        await _documentService.renameDocument(event.id, event.newName);
        add(LoadHistoryRequested());
        emit(HomeSuccess("Đổi tên thành công!"));
      } catch (e) {
        emit(HomeFailure("Không đổi tên được: ${e.toString()}"));
      }
    });
  }
}