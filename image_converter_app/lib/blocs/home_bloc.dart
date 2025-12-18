import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../services/document_service.dart';

// --- Events ---
abstract class HomeEvent {}
class PickImageRequested extends HomeEvent {
  final bool fromCamera; // True: Chụp ảnh, False: Chọn thư viện
  PickImageRequested(this.fromCamera);
}
class LoadHistoryRequested extends HomeEvent {}
class RenameDocumentRequested extends HomeEvent {
  final int id;
  final String newName;
  RenameDocumentRequested(this.id, this.newName);
}

// --- States ---
abstract class HomeState {}
class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {} // Đang xoay xoay
class HomeSuccess extends HomeState {
  final String message;
  final String? imageUrl; // URL ảnh sau khi upload xong
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

class DeleteDocumentRequested extends HomeEvent {
  final int id;
  DeleteDocumentRequested(this.id);
}

// --- Bloc ---
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final DocumentService _documentService = DocumentService();
  final ImagePicker _picker = ImagePicker();

  HomeBloc() : super(HomeInitial()) {

    // Xử lý chọn ảnh và Upload luôn
    on<PickImageRequested>((event, emit) async {
      try {
        List<XFile> images = [];

        if (event.fromCamera) {
          // Camera: Vẫn chụp 1 tấm
          final XFile? photo = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 70,
          );
          if (photo != null) images.add(photo);
        } else {
          // Thư viện: Dùng pickMultiImage (Chọn nhiều native)
          // Hàm này siêu nhẹ, gọi giao diện gốc của máy
          images = await _picker.pickMultiImage(
            imageQuality: 70,
            maxWidth: 1024,
          );
        }

        if (images.isNotEmpty) {
          emit(HomeLoading());

          // Chuyển đổi sang File
          List<File> fileList = images.map((e) => File(e.path)).toList();

          // Gọi Service Upload (dùng hàm uploadImages bạn đã sửa lúc nãy)
          final result = await _documentService.uploadImages(fileList);

          if (result != null) {
            emit(HomeSuccess("Upload thành công ${images.length} ảnh!"));
            add(LoadHistoryRequested());
          }
        }
      } catch (e) {
        emit(HomeFailure(e.toString()));
      }
    });

    // Xử lý lấy lịch sử
    on<LoadHistoryRequested>((event, emit) async {
      try {
        emit(HomeLoading());
        final docs = await _documentService.getHistory();
        emit(HistoryLoaded(docs));
      } catch (e) {
        emit(HomeFailure(e.toString()));
      }
    });

    on<DeleteDocumentRequested>((event, emit) async {
      try {
        // Không emit(HomeLoading) để tránh màn hình bị nháy, chỉ xóa ngầm
        await _documentService.deleteDocument(event.id);

        // Xóa xong thì load lại danh sách mới
        add(LoadHistoryRequested());

        // (Tùy chọn) Có thể emit một State thông báo xóa thành công nếu muốn
      } catch (e) {
        emit(HomeFailure("Không xóa được: ${e.toString()}"));
      }
    });

    on<RenameDocumentRequested>((event, emit) async {
      try {
        await _documentService.renameDocument(event.id, event.newName);
        // Đổi tên xong thì load lại danh sách để cập nhật tên mới
        add(LoadHistoryRequested());
        emit(HomeSuccess("Đổi tên thành công!"));
      } catch (e) {
        emit(HomeFailure("Không đổi tên được: ${e.toString()}"));
      }
    });
  }
}