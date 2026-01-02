<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

// 👇 1. Thêm 2 dòng này vào đầu file
use App\Models\User;
use App\Observers\UserObserver; 
// 👆 ----------------------------

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // 👇 2. Đăng ký Observer ở đây (Thay vì EventServiceProvider cũ)
        User::observe(UserObserver::class);
    }
}