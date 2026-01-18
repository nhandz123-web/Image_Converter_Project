import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/local_file_service.dart';

// ======================== EVENTS ========================

abstract class DownloadedFilesEvent {}

class LoadDownloadedFilesRequested extends DownloadedFilesEvent {}

class DeleteFileRequested extends DownloadedFilesEvent {
  final String fileId;
  DeleteFileRequested(this.fileId);
}

class DeleteMultipleFilesRequested extends DownloadedFilesEvent {
  final List<String> fileIds;
  DeleteMultipleFilesRequested(this.fileIds);
}

class ClearAllFilesRequested extends DownloadedFilesEvent {}

class ToggleSelectMode extends DownloadedFilesEvent {}

class ToggleFileSelection extends DownloadedFilesEvent {
  final String fileId;
  ToggleFileSelection(this.fileId);
}

class SelectAllFiles extends DownloadedFilesEvent {}

class DeselectAllFiles extends DownloadedFilesEvent {}

// ======================== STATES ========================

abstract class DownloadedFilesState {}

class DownloadedFilesInitial extends DownloadedFilesState {}

class DownloadedFilesLoading extends DownloadedFilesState {}

class DownloadedFilesLoaded extends DownloadedFilesState {
  final List<LocalFile> files;
  final String totalSize;
  final bool isSelectMode;
  final Set<String> selectedFileIds;

  DownloadedFilesLoaded({
    required this.files,
    required this.totalSize,
    this.isSelectMode = false,
    this.selectedFileIds = const {},
  });

  DownloadedFilesLoaded copyWith({
    List<LocalFile>? files,
    String? totalSize,
    bool? isSelectMode,
    Set<String>? selectedFileIds,
  }) {
    return DownloadedFilesLoaded(
      files: files ?? this.files,
      totalSize: totalSize ?? this.totalSize,
      isSelectMode: isSelectMode ?? this.isSelectMode,
      selectedFileIds: selectedFileIds ?? this.selectedFileIds,
    );
  }
}

class DownloadedFilesError extends DownloadedFilesState {
  final String message;
  DownloadedFilesError(this.message);
}

class DownloadedFilesSuccess extends DownloadedFilesState {
  final String message;
  DownloadedFilesSuccess(this.message);
}

// ======================== BLOC ========================

class DownloadedFilesBloc extends Bloc<DownloadedFilesEvent, DownloadedFilesState> {
  final LocalFileService _fileService = LocalFileService();

  DownloadedFilesBloc() : super(DownloadedFilesInitial()) {
    on<LoadDownloadedFilesRequested>(_onLoadFiles);
    on<DeleteFileRequested>(_onDeleteFile);
    on<DeleteMultipleFilesRequested>(_onDeleteMultipleFiles);
    on<ClearAllFilesRequested>(_onClearAll);
    on<ToggleSelectMode>(_onToggleSelectMode);
    on<ToggleFileSelection>(_onToggleFileSelection);
    on<SelectAllFiles>(_onSelectAll);
    on<DeselectAllFiles>(_onDeselectAll);
  }

  Future<void> _onLoadFiles(
    LoadDownloadedFilesRequested event,
    Emitter<DownloadedFilesState> emit,
  ) async {
    emit(DownloadedFilesLoading());
    
    try {
      final files = await _fileService.getDownloadedFiles();
      final totalSize = await _fileService.getFormattedTotalSize();
      
      emit(DownloadedFilesLoaded(
        files: files,
        totalSize: totalSize,
      ));
    } catch (e) {
      emit(DownloadedFilesError('Không thể tải danh sách file: $e'));
    }
  }

  Future<void> _onDeleteFile(
    DeleteFileRequested event,
    Emitter<DownloadedFilesState> emit,
  ) async {
    try {
      final success = await _fileService.deleteFile(event.fileId);
      
      if (success) {
        emit(DownloadedFilesSuccess('Đã xóa file thành công'));
        add(LoadDownloadedFilesRequested());
      } else {
        emit(DownloadedFilesError('Không thể xóa file'));
      }
    } catch (e) {
      emit(DownloadedFilesError('Lỗi khi xóa file: $e'));
    }
  }

  Future<void> _onDeleteMultipleFiles(
    DeleteMultipleFilesRequested event,
    Emitter<DownloadedFilesState> emit,
  ) async {
    try {
      final deletedCount = await _fileService.deleteFiles(event.fileIds);
      
      emit(DownloadedFilesSuccess('Đã xóa $deletedCount file'));
      add(LoadDownloadedFilesRequested());
    } catch (e) {
      emit(DownloadedFilesError('Lỗi khi xóa files: $e'));
    }
  }

  Future<void> _onClearAll(
    ClearAllFilesRequested event,
    Emitter<DownloadedFilesState> emit,
  ) async {
    try {
      await _fileService.clearAll();
      emit(DownloadedFilesSuccess('Đã xóa tất cả file'));
      add(LoadDownloadedFilesRequested());
    } catch (e) {
      emit(DownloadedFilesError('Lỗi khi xóa tất cả: $e'));
    }
  }

  void _onToggleSelectMode(
    ToggleSelectMode event,
    Emitter<DownloadedFilesState> emit,
  ) {
    if (state is DownloadedFilesLoaded) {
      final currentState = state as DownloadedFilesLoaded;
      emit(currentState.copyWith(
        isSelectMode: !currentState.isSelectMode,
        selectedFileIds: {}, // Reset selection khi toggle mode
      ));
    }
  }

  void _onToggleFileSelection(
    ToggleFileSelection event,
    Emitter<DownloadedFilesState> emit,
  ) {
    if (state is DownloadedFilesLoaded) {
      final currentState = state as DownloadedFilesLoaded;
      final newSelection = Set<String>.from(currentState.selectedFileIds);
      
      if (newSelection.contains(event.fileId)) {
        newSelection.remove(event.fileId);
      } else {
        newSelection.add(event.fileId);
      }
      
      emit(currentState.copyWith(selectedFileIds: newSelection));
    }
  }

  void _onSelectAll(
    SelectAllFiles event,
    Emitter<DownloadedFilesState> emit,
  ) {
    if (state is DownloadedFilesLoaded) {
      final currentState = state as DownloadedFilesLoaded;
      final allIds = currentState.files.map((f) => f.id).toSet();
      emit(currentState.copyWith(selectedFileIds: allIds));
    }
  }

  void _onDeselectAll(
    DeselectAllFiles event,
    Emitter<DownloadedFilesState> emit,
  ) {
    if (state is DownloadedFilesLoaded) {
      final currentState = state as DownloadedFilesLoaded;
      emit(currentState.copyWith(selectedFileIds: {}));
    }
  }
}
