<?php

namespace App\Models;

// 1. Thêm dòng này để gọi thư viện Passport
use Laravel\Passport\HasApiTokens;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    // 2. Thêm trait HasApiTokens vào trong mảng use
    // Trait này cung cấp các phương thức như: $user->createToken()
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'storage_limit', // Thêm dòng này để cho phép gán dữ liệu vào cột storage_limit
        'storage_used',  // Thêm dòng này
    ];

    // ... Các phần dưới giữ nguyên
    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
    ];

    public function files()
    {
        return $this->hasMany(File::class);
    }

    // Lấy tất cả lượt convert của user này
    public function conversions()
    {
        return $this->hasMany(Conversion::class);
    }
}
