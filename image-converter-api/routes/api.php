<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\DocumentController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Route test thử xem lấy thông tin user được không (yêu cầu phải có Token)
Route::middleware('auth:api')->get('/user', function (Request $request) {
    return $request->user();
});
Route::middleware('auth:api')->group(function () { 
    
    // API Đăng xuất
    Route::post('/logout', [AuthController::class, 'logout']); 
    
    // API Upload và xử lý ảnh
    Route::post('/convert', [DocumentController::class, 'upload']);

    //API Xóa
    Route::delete('/documents/{id}', [DocumentController::class, 'destroy']);
    
    //sửa
    Route::put('/documents/{id}', [DocumentController::class, 'update']);

    // API Lấy lịch sử
    Route::get('/history', [DocumentController::class, 'index']);

    // API Lấy dung lượng
    Route::get('/storage', [DocumentController::class, 'storageInfo']);

});