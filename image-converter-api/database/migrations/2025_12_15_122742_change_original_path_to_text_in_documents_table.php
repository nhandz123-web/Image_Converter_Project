<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB; 

return new class extends Migration
{
    public function up()
    {
        // Sử dụng câu lệnh SQL trực tiếp để đổi kiểu dữ liệu
        // Cách này "bất chấp" dữ liệu cũ, ít lỗi hơn hẳn so với ->change()
        // MODIFY COLUMN ... TEXT: Chuyển sang TEXT
        DB::statement("ALTER TABLE documents MODIFY COLUMN original_path TEXT NULL");
    }

    public function down()
    {
        // Khi rollback thì chuyển về lại VARCHAR(255)
        // Lưu ý: Nếu dữ liệu lúc này quá dài thì rollback sẽ lỗi, nhưng chấp nhận được
        DB::statement("ALTER TABLE documents MODIFY COLUMN original_path VARCHAR(255) NULL");
    }
};