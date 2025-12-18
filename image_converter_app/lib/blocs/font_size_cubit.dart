import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeCubit extends Cubit<double> {
  // Nhận cỡ chữ ban đầu
  FontSizeCubit({double initialSize = 1.0}) : super(initialSize);

  void changeSize(double newSize) async {
    emit(newSize);
    // Lưu vào bộ nhớ
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', newSize);
  }
}