<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    // API Đăng ký tài khoản mới
    public function register(Request $request)
    {
        // 1. Validate dữ liệu gửi lên
        // Đảm bảo email chưa tồn tại, password đủ dài...
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6|confirmed', // confirmed nghĩa là phải có trường password_confirmation gửi kèm
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // 2. Tạo User mới vào Database
        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password), // Mã hóa password
            // storage_limit mặc định đã set trong migration là 1GB, ko cần điền ở đây
        ]);

        // 3. Tạo Token truy cập ngay lập tức để user không cần đăng nhập lại
        // 'AuthToken' là tên đặt cho token này, bạn đặt gì cũng được
        $token = $user->createToken('AuthToken')->accessToken;

        // 4. Trả về kết quả JSON cho Flutter
        return response()->json([
            'message' => 'Đăng ký thành công!',
            'user' => $user,
            'token' => $token // Flutter sẽ lưu token này để dùng cho các request sau
        ], 201);
    }

    public function login(Request $request)
    {
        // 1. Validate dữ liệu đầu vào
        $data = $request->validate([
            'email' => 'required|email',
            'password' => 'required'
        ]);

        // 2. Kiểm tra thông tin đăng nhập
        // Auth::attempt sẽ tự động so sánh password nhập vào với password đã mã hóa trong DB
        if (!auth()->attempt($data)) {
            // Nếu sai email hoặc sai pass
            return response()->json(['message' => 'Thông tin đăng nhập không chính xác'], 401);
        }

        // 3. Nếu đúng, lấy thông tin user hiện tại
        // Lưu ý: Lúc này auth()->user() chính là user vừa đăng nhập thành công
        $user = auth()->user();

        // 4. Tạo token truy cập mới
        $token = $user->createToken('AuthToken')->accessToken;

        // 5. Trả về
        return response()->json([
            'message' => 'Đăng nhập thành công',
            'user' => $user,
            'token' => $token
        ], 200);
    }
}