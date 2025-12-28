import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _isStep1 = true; 
  bool _isLoading = false;

  // Đảm bảo IP này trùng với IP máy tính chạy Laravel của bạn
  final String _apiUrl = "http://192.168.1.13:8000/api/password"; 

  Future<void> _handleAction() async {
    setState(() => _isLoading = true);
    
    // Header quan trọng để Laravel trả về JSON thay vì HTML lỗi
    final Map<String, String> headers = {
      "Accept": "application/json",
    };

    try {
      if (_isStep1) {
        // --- BƯỚC 1: GỬI OTP ---
        final res = await http.post(
          Uri.parse("$_apiUrl/email"), 
          headers: headers,
          body: {'email': _emailController.text},
        );

        if (res.statusCode == 200) {
          setState(() => _isStep1 = false);
          _showMsg("Mã OTP đã được gửi vào Email của bạn");
        } else {
          // Lấy thông báo lỗi từ JSON trả về
          final Map<String, dynamic> errorData = jsonDecode(res.body);
          _showMsg(errorData['message'] ?? "Không thể gửi mã OTP");
        }
      } else {
        // --- BƯỚC 2: RESET PASSWORD ---
        final res = await http.post(
          Uri.parse("$_apiUrl/reset"), 
          headers: headers,
          body: {
            'email': _emailController.text,
            'otp': _otpController.text,
            'password': _passController.text,
            'password_confirmation': _confirmPassController.text,
          },
        );

        if (res.statusCode == 200) {
          _showMsg("Thành công! Hãy đăng nhập bằng mật khẩu mới.");
          Navigator.pop(context); // Quay lại màn hình đăng nhập
        } else {
          final Map<String, dynamic> errorData = jsonDecode(res.body);
          _showMsg(errorData['message'] ?? "Mã OTP không đúng hoặc có lỗi xảy ra");
        }
      }
    } catch (e) {
      _showMsg("Lỗi kết nối Server. Vui lòng kiểm tra lại mạng!");
      print("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quên mật khẩu"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isStep1) ...[
              const Text(
                "Nhập Email của bạn để nhận mã xác nhận đổi mật khẩu.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController, 
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email đăng ký",
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              _btn("Gửi mã OTP", _handleAction),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Mã đã gửi đến: ${_emailController.text}",
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _otpController, 
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Nhập mã OTP 6 số",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passController, 
                decoration: const InputDecoration(
                  labelText: "Mật khẩu mới",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _confirmPassController, 
                decoration: const InputDecoration(
                  labelText: "Xác nhận mật khẩu",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              _btn("Đổi mật khẩu", _handleAction),
              TextButton(
                onPressed: () => setState(() => _isStep1 = true),
                child: const Text("Gửi lại mã khác"),
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _btn(String text, VoidCallback press) {
    return SizedBox(
      height: 50,
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : ElevatedButton(
            onPressed: press,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
    );
  }
}