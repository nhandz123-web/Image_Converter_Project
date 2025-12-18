<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Conversion extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'conversion_type',
        'status',          // pending, processing, completed...
        'input_file_ids',  // Danh sách ID ảnh đầu vào
        'output_file_id',  // ID file PDF kết quả
    ];

    // Tự động chuyển chuỗi JSON trong DB thành Mảng (Array) để dễ dùng
    protected $casts = [
        'input_file_ids' => 'array',
    ];

    // Quan hệ: Lượt convert này của ai?
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // Quan hệ: File kết quả trỏ đến bảng files
    public function outputFile()
    {
        return $this->belongsTo(File::class, 'output_file_id');
    }
}
