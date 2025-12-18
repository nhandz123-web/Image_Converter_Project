<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class File extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'original_name', // Tên file gốc (vd: tai_lieu.jpg)
        'path',          // Đường dẫn lưu trên ổ cứng
        'mime_type',     // Loại file (image/jpeg, application/pdf)
        'size',          // Kích thước (bytes)
    ];

    // Quan hệ: File này thuộc về User nào?
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
