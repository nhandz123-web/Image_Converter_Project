<?php

namespace App\Observers;

use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class UserObserver
{
    // Web chạy cổng 8000
    protected $webUrl = 'http://127.0.0.1:8000/api/sync-from-app';

    public function created(User $user)
{
    Log::info('1. Observer APP đã bắt được user mới: ' . $user->email); // <--- Thêm dòng này

    try {
        $response = Http::timeout(2)->post($this->webUrl, [
            'action' => 'created',
            'user'   => [
                'email'    => $user->email,
                'name'     => $user->name,
                'password' => $user->password,
            ],
        ]);
        
        // In ra kết quả xem Web trả lời gì
        Log::info('2. Kết quả gọi sang Web: ' . $response->status() . ' - ' . $response->body()); // <--- Thêm dòng này

    } catch (\Exception $e) {
        Log::error("Lỗi gọi API sang Web: " . $e->getMessage());
    }
}
}