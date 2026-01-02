<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
{
    Schema::create('users', function (Blueprint $table) {
        $table->id(); 
        $table->string('name'); // Bên Web là full_name, sang đây là name
        $table->string('email')->unique();
        $table->string('password'); // Lưu chuỗi mã hóa y hệt Web
        
        // Các trường riêng của App (cho phép null để không lỗi)
        $table->timestamp('email_verified_at')->nullable();
        $table->bigInteger('storage_limit')->default(104857600); // Ví dụ 100MB
        $table->bigInteger('storage_used')->default(0);
        
        $table->rememberToken();
        $table->timestamps();
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('users');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('sessions');
    }
};
