<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use App\Mail\ResetPasswordMail;
use Carbon\Carbon;

class ForgotPasswordController extends Controller
{
    /**
     * BƯỚC 1: Gửi mã OTP đến Email (Ghi vào log)
     */
    public function sendResetCode(Request $request) 
    {
        // 1. Kiểm tra định dạng email gửi lên
        $request->validate(['email' => 'required|email']);

        // 2. Kiểm tra email có tồn tại trong bảng users không
        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json(['message' => 'Email này không tồn tại trong hệ thống!'], 404);
        }

        // 3. Tạo mã OTP ngẫu nhiên 6 số
        $otp = rand(100000, 999999);
        
        // 4. Lưu mã vào bảng password_resets
        DB::table('password_resets')->updateOrInsert(
            ['email' => $request->email],
            [
                'token' => Hash::make($otp), // Mã hóa để bảo mật khi lưu DB
                'created_at' => now()
            ]
        );

        try {
            // 5. Gửi mail (Sẽ ghi vào storage/logs/laravel.log)
            Mail::to($request->email)->send(new ResetPasswordMail($otp));
            
            return response()->json(['message' => 'Mã OTP đã được gửi! Hãy kiểm tra file log.']);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Lỗi hệ thống: ' . $e->getMessage()], 500);
        }
    }

    /**
     * BƯỚC 2: Xác nhận OTP và cập nhật mật khẩu mới
     * Đây là hàm bạn đang thiếu dẫn đến lỗi trên màn hình App
     */
    public function resetPassword(Request $request)
    {
        // 1. Validate dữ liệu từ Flutter gửi lên
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required|numeric',
            'password' => 'required|min:6|confirmed', // Flutter cần gửi kèm trường password_confirmation
        ]);

        // 2. Tìm bản ghi OTP trong database
        $resetData = DB::table('password_resets')->where('email', $request->email)->first();

        if (!$resetData) {
            return response()->json(['message' => 'Không tìm thấy yêu cầu khôi phục mật khẩu!'], 400);
        }

        // 3. Kiểm tra OTP có khớp không (Sử dụng Hash::check vì mã OTP lưu trong DB đã được mã hóa)
        if (!Hash::check($request->otp, $resetData->token)) {
            return response()->json(['message' => 'Mã OTP không chính xác!'], 400);
        }

        // 4. Kiểm tra thời hạn OTP (ví dụ 15 phút)
        if (Carbon::parse($resetData->created_at)->addMinutes(15)->isPast()) {
            return response()->json(['message' => 'Mã OTP đã hết hạn!'], 400);
        }

        // 5. Tìm user và cập nhật mật khẩu
        $user = User::where('email', $request->email)->first();
        if ($user) {
            $user->update([
                'password' => Hash::make($request->password)
            ]);

            // 6. Đổi xong thì xóa OTP đi để không dùng lại được lần 2
            DB::table('password_resets')->where('email', $request->email)->delete();

            return response()->json(['message' => 'Mật khẩu đã được đổi thành công!']);
        }

        return response()->json(['message' => 'Người dùng không tồn tại!'], 404);
    }
}