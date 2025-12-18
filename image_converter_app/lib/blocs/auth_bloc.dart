import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- Events (Hành động) ---
abstract class AuthEvent {}
class LoginRequested extends AuthEvent {
  final String email, password;
  LoginRequested(this.email, this.password);
}
class RegisterRequested extends AuthEvent {
  final String name, email, password;
  RegisterRequested(this.name, this.email, this.password);
}
class LogoutRequested extends AuthEvent {}
class CheckAuthRequested extends AuthEvent {}

// --- States (Trạng thái) ---
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {}
class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
}
class AuthLoggedOut extends AuthState {}


// --- Bloc (Bộ não xử lý) ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;
  final _storage = const FlutterSecureStorage();
  AuthBloc(this.authService) : super(AuthInitial()) {

    // Xử lý Login
    on<CheckAuthRequested>((event, emit) async {
      // Đọc token từ máy
      final token = await _storage.read(key: 'auth_token');

      if (token != null) {
        emit(AuthSuccess()); // Có token -> Cho vào luôn
      } else {
        emit(AuthLoggedOut()); // Không có -> Bắt đăng nhập
      }
    });

    on<LoginRequested>((event, emit) async {
      emit(AuthLoading()); // Hiện vòng quay
      final error = await authService.login(event.email, event.password);
      if (error == null) {
        emit(AuthSuccess()); // Chuyển màn hình
      } else {
        emit(AuthFailure(error)); // Hiện lỗi
      }
    });


    // Xử lý Register
    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());
      final error = await authService.register(event.name, event.email, event.password);
      if (error == null) {
        emit(AuthSuccess());
      } else {
        emit(AuthFailure(error));
      }
    });
    // đăng xuất
    on<LogoutRequested>((event, emit) async {
      emit(AuthLoading()); // Hiện loading chút cho mượt
      await authService.logout(); // Xóa token
      emit(AuthLoggedOut()); // Báo ra ngoài là đã thoát
    });
  }
}