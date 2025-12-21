import 'package:flutter/material.dart';
import '../services/document_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;

  const EditProfileScreen({Key? key, required this.currentName}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentService = DocumentService();

  late TextEditingController _nameController;
  final _currentPassController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _newPassController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Điền sẵn tên cũ vào ô nhập
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String name = _nameController.text.trim();

      // Lấy mật khẩu mới (nếu có)
      String? newPass = _newPassController.text.isNotEmpty ? _newPassController.text : null;
      // Lấy mật khẩu cũ
      String? currentPass = _currentPassController.text.isNotEmpty ? _currentPassController.text : null;

      // Gọi service (truyền 3 tham số)
      await _documentService.updateProfile(name, currentPass, newPass);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cập nhật thành công!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Nếu nhập sai mật khẩu cũ, lỗi sẽ hiện ở đây
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // e.toString() sẽ in ra "Exception: Mật khẩu hiện tại không chính xác!"
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chỉnh sửa hồ sơ")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Thông tin cơ bản", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Họ và tên",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) => val == null || val.isEmpty ? "Vui lòng nhập tên" : null,
              ),

              SizedBox(height: 30),
              Divider(),
              SizedBox(height: 10),

              Text("Đổi mật khẩu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Nhập mật khẩu cũ để xác thực nếu muốn đổi mật khẩu mới", style: TextStyle(color: Colors.grey, fontSize: 12)),

              SizedBox(height: 15),

              // --- 1. Ô NHẬP MẬT KHẨU CŨ (MỚI THÊM) ---
              TextFormField(
                controller: _currentPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Mật khẩu hiện tại",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                validator: (val) {
                  // Logic: Nếu ô Mật khẩu MỚI có chữ -> Bắt buộc phải nhập ô Mật khẩu CŨ
                  if (_newPassController.text.isNotEmpty && (val == null || val.isEmpty)) {
                    return "Cần nhập mật khẩu cũ để xác thực";
                  }
                  return null;
                },
              ),

              SizedBox(height: 15),

              // --- 2. Ô NHẬP MẬT KHẨU MỚI ---
              TextFormField(
                controller: _newPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Mật khẩu mới (Tùy chọn)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (val) {
                  if (val != null && val.isNotEmpty && val.length < 6) {
                    return "Mật khẩu phải từ 6 ký tự";
                  }
                  return null;
                },
              ),

              SizedBox(height: 15),

              // --- 3. Ô NHẬP LẠI MẬT KHẨU MỚI ---
              TextFormField(
                controller: _confirmPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Nhập lại mật khẩu mới",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.check_circle_outline),
                ),
                validator: (val) {
                  if (_newPassController.text.isNotEmpty && val != _newPassController.text) {
                    return "Mật khẩu xác nhận không khớp";
                  }
                  return null;
                },
              ),

              SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Lưu thay đổi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}