import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/local_file_service.dart';

// ======================== EVENTS ========================

abstract class DownloadedFilesEvent {}

/// Load files lần đầu hoặc refresh (reset về page 1)
class LoadDownloadedFilesRequested extends DownloadedFilesEvent {}

/// Load thêm files (infinite scroll)
class LoadMoreFilesRequested extends DownloadedFilesEvent {}

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
  final bool hasMore; // Còn file để load không
  final bool isLoadingMore; // Đang load thêm không
  final int totalCount; // Tổng số file

  DownloadedFilesLoaded({
    required this.files,
    required this.totalSize,
    this.isSelectMode = false,
    this.selectedFileIds = const {},
    this.hasMore = true,
    this.isLoadingMore = false,
    this.totalCount = 0,
  });

  DownloadedFilesLoaded copyWith({
    List<LocalFile>? files,
    String? totalSize,
    bool? isSelectMode,
    Set<String>? selectedFileIds,
    bool? hasMore,
    bool? isLoadingMore,
    int? totalCount,
  }) {
    return DownloadedFilesLoaded(
      files: files ?? this.files,
      totalSize: totalSize ?? this.totalSize,
      isSelectMode: isSelectMode ?? this.isSelectMode,
      selectedFileIds: selectedFileIds ?? this.selectedFileIds,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      totalCount: totalCount ?? this.totalCount,
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

  // Pagination config
  static const int _pageSize = 20;

  DownloadedFilesBloc() : super(DownloadedFilesInitial()) {
    on<LoadDownloadedFilesRequested>(_onLoadFiles);
    on<LoadMoreFilesRequested>(_onLoadMoreFiles);
    on<DeleteFileRequested>(_onDeleteFile);
    on<DeleteMultipleFilesRequested>(_onDeleteMultipleFiles);
    on<ClearAllFilesRequested>(_onClearAll);
    on<ToggleSelectMode>(_onToggleSelectMode);
    on<ToggleFileSelection>(_onToggleFileSelection);
    on<SelectAllFiles>(_onSelectAll);
    on<DeselectAllFiles>(_onDeselectAll);
  }

  /// Load files lần đầu hoặc refresh
  Future<void> _onLoadFiles(
    LoadDownloadedFilesRequested event,
    Emitter<DownloadedFilesState> emit,
  ) async {
    emit(DownloadedFilesLoading());

    try {
      // ✅ OPTIMIZED: Lấy tất cả thông tin trong một lần đọc duy nhất
      final result = await _fileService.getFilesWithStats(limit: _pageSize, offset: 0);
      
      // Format total size
      final totalSizeFormatted = _formatSize(result.totalSize);

      emit(DownloadedFilesLoaded(
        files: result.files,
        totalSize: totalSizeFormatted,
        hasMore: result.files.length < result.totalCount,
        totalCount: result.totalCount,
      ));
    } catch (e) {
      emit(DownloadedFilesError('Không thể tải danh sách file: $e'));
    }
  }

  /// Helper format size
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Load thêm files (infinite scroll)
  Future<void> _onLoadMoreFiles(
    LoadMoreFilesRequested event,
    Emitter<DownloadedFilesState> emit,
  ) async {
    if (state is! DownloadedFilesLoaded) return;

    final currentState = state as DownloadedFilesLoaded;

    // Nếu đang loading hoặc không còn file thì skip
    if (currentState.isLoadingMore || !currentState.hasMore) return;

    // Emit loading more state
    emit(currentState.copyWith(isLoadingMore: true));

    try {
      // ✅ OPTIMIZED: Sử dụng getFilesWithStats để lấy thông tin trong một lần đọc
      final result = await _fileService.getFilesWithStats(
        limit: _pageSize,
        offset: currentState.files.length,
      );

      final allFiles = [...currentState.files, ...result.files];

      emit(currentState.copyWith(
        files: allFiles,
        hasMore: allFiles.length < result.totalCount,
        isLoadingMore: false,
        totalCount: result.totalCount,
        totalSize: _formatSize(result.totalSize),
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
      emit(DownloadedFilesError('Lỗi khi tải thêm file: $e'));
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
