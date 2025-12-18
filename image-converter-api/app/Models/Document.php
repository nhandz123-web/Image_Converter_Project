<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Document extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'original_name',
        'path',
        'type',
        'status',
        'size',
        'original_path',
    ];

    // Tạo quan hệ: Một tài liệu thuộc về một User
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}