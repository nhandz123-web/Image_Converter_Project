import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- Events (Hành động) ---
abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email, password;
  LoginRequested(this.email, this.password);
}

// 🔥 CẬP NHẬT: Thêm các trường mới vào Event Đăng ký
class RegisterRequested extends AuthEvent {
  final String fullname;
  final String email;
  final String password;
  final String phone;
  final String address;
  final String birthday;

  // Dùng named parameter ({}) cho dễ nhìn và tránh nhầm lẫn vị trí
  RegisterRequested({
    required this.fullname,
    required this.email,
    required this.password,
    required this.phone,
    required this.address,
    required this.birthday,
  });
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

    // 1. Kiểm tra trạng thái đăng nhập (lúc mở app)
    on<CheckAuthRequested>((event, emit) async {
      final token = await _storage.read(key: 'auth_token');
      if (token != null) {
        emit(AuthSuccess());
      } else {
        emit(AuthLoggedOut());
      }
    });

    // 2. Xử lý Login
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      final error = await authService.login(event.email, event.password);
      if (error == null) {
        emit(AuthSuccess());
      } else {
        emit(AuthFailure(error));
      }
    });

    // 3. Xử lý Register (CẬP NHẬT)
    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());

      // Gọi hàm register mới bên Service với đầy đủ tham số
      final error = await authService.register(
        name: event.fullname,
        email: event.email,
        password: event.password,
        phone: event.phone,
        address: event.address,
        birthday: event.birthday,
      );

      if (error == null) {
        emit(AuthSuccess());
      } else {
        emit(AuthFailure(error));
      }
    });

    // 4. Đăng xuất
    on<LogoutRequested>((event, emit) async {
      emit(AuthLoading());
      await authService.logout();
      emit(AuthLoggedOut());
    });
  }
}
