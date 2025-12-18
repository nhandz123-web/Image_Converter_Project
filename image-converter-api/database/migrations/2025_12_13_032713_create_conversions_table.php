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
        Schema::create('conversions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');

            $table->string('conversion_type')->default('image_to_pdf'); // Loại chuyển đổi

            // Trạng thái: Đang chờ -> Đang xử lý -> Xong -> Lỗi
            $table->enum('status', ['pending', 'processing', 'completed', 'failed'])->default('pending');

            // Lưu danh sách ID các ảnh đầu vào (Dạng JSON: [1, 2, 5])
            $table->json('input_file_ids')->nullable();

            // ID của file PDF kết quả (liên kết ngược lại bảng files)
            $table->foreignId('output_file_id')->nullable()->constrained('files');

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('conversions');
    }
};
