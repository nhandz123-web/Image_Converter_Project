<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;

class SyncUserController extends Controller
{
    public function sync(Request $request)
    {
        // 1. Lấy dữ liệu Web gửi sang
        $data = $request->all();
        $action = $data['action']; // created, updated, hoặc deleted
        $webUser = $data['user'];  // Thông tin user bên Web

        // 2. Nếu là lệnh XÓA
        if ($action == 'deleted') {
            User::where('email', $webUser['email'])->delete();
            return response()->json(['message' => 'Đã xóa user bên App']);
        }

        // 3. Nếu là lệnh THÊM hoặc SỬA
        // Dùng updateOrCreate: Có email thì sửa, chưa có thì tạo mới
        $user = User::updateOrCreate(
            ['email' => $webUser['email']], // Tìm theo email
            [
                // Cột trái (App) => Cột phải (Web gửi sang)
                'name'     => $webUser['full_name'], // Đổi full_name thành name
                'password' => $webUser['password'],  // Giữ nguyên chuỗi mã hóa
                'email_verified_at' => $webUser['email_verified_at'],
            ]
        );

        if ($action == 'deleted') {
            // Bọc trong withoutEvents để khi xóa nó KHÔNG bắn ngược lại Web
            User::withoutEvents(function () use ($webUser) {
                User::where('email', $webUser['email'])->delete();
            });
            return response()->json(['message' => 'Đã xóa']);
        }

        // Bọc trong withoutEvents
        User::withoutEvents(function () use ($webUser) {
            User::updateOrCreate(
                ['email' => $webUser['email']],
                [
                    'name'     => $webUser['full_name'],
                    'password' => $webUser['password'],
                    'email_verified_at' => $webUser['email_verified_at'],
                ]
            );
        });

        return response()->json(['message' => 'Đồng bộ thành công', 'id_app' => $user->id]);
    }
}
