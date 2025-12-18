<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Document;
use Illuminate\Support\Facades\Storage; // Nhớ import cái này để lưu file
use Barryvdh\DomPDF\Facade\Pdf;

class DocumentController extends Controller
{
    // API: Upload ảnh và tạo yêu cầu chuyển đổi
    public function upload(Request $request)
    {
        set_time_limit(300);
        ini_set('memory_limit', '512M');

        // Validate: Cho phép gửi mảng 'images[]'
        $request->validate([
            'images' => 'required',
            'images.*' => 'image|mimes:jpeg,png,jpg,gif|max:10240', // Validate từng ảnh
        ]);

        try {
            $user = $request->user();
            
            // Kiểm tra xem input là 1 file hay nhiều file
            $files = $request->file('images');
            if (!is_array($files)) {
                $files = [$files]; // Nếu gửi 1 file thì biến nó thành mảng
            }

            $htmlContent = '';
            $originalPaths = [];
            $totalSize = 0;
            $firstFileName = pathinfo($files[0]->getClientOriginalName(), PATHINFO_FILENAME);

            // --- VÒNG LẶP XỬ LÝ TỪNG ẢNH ---
            foreach ($files as $index => $file) {
                $originalName = $file->getClientOriginalName();
                $fileSize = $file->getSize();
                $totalSize += $fileSize;

                // 1. Lưu ảnh gốc
                $imageName = time() . "_{$index}_" . $originalName;
                $originalPath = $file->storeAs('uploads', $imageName, 'public');
                $originalPaths[] = $originalPath; // Lưu vào danh sách đường dẫn

                // 2. Chuẩn bị HTML cho PDF
                $fullPath = storage_path('app/public/' . $originalPath);
                $imageData = base64_encode(file_get_contents($fullPath));
                $src = 'data:' . $file->getMimeType() . ';base64,' . $imageData;

                // Thêm ngắt trang (page-break) trừ trang cuối
                $pageBreak = ($index < count($files) - 1) ? 'page-break-after: always;' : '';
                
                $htmlContent .= '<div style="text-align: center; width: 100%; height: 100%; ' . $pageBreak . '">
                                    <img src="' . $src . '" style="max-width: 100%; max-height: 100%;">
                                 </div>';
            }

            // 3. Tạo file PDF từ chuỗi HTML đã ghép
            $pdfName = time() . '_' . $firstFileName . '_merged.pdf';
            $pdf = Pdf::loadHTML($htmlContent)->setPaper('a4', 'portrait');
            
            $pdfPath = 'uploads/' . $pdfName;
            Storage::disk('public')->put($pdfPath, $pdf->output());
            
            $totalSize += Storage::disk('public')->size($pdfPath);

            // 4. Lưu vào Database
            // original_path bây giờ sẽ lưu dạng JSON Array (VD: ["path1.jpg", "path2.jpg"])
            $document = Document::create([
                'user_id' => $user->id,
                'original_name' => $firstFileName . '.pdf',
                'path' => $pdfPath,
                'original_path' => json_encode($originalPaths), // <--- LƯU DẠNG JSON
                'status' => 'completed',
                'type' => 'pdf',
                'size' => $totalSize,
            ]);

            return response()->json([
                'message' => 'Upload thành công ' . count($files) . ' ảnh!',
                'document' => $document,
            ], 200);

        } catch (\Exception $e) {
            return response()->json(['message' => 'Lỗi server: ' . $e->getMessage()], 500);
        }
    }

    // API: Xóa tài liệu (Xóa DB + Xóa file PDF + Xóa file Gốc)
    public function destroy(Request $request, $id)
    {
        $user = $request->user();
        // Tìm file của đúng user đó
        $document = Document::where('user_id', $user->id)->where('id', $id)->first();

        if (!$document) {
            return response()->json(['message' => 'Không tìm thấy file'], 404);
        }

        // 1. Xóa file PDF kết quả (nếu có)
        if ($document->path && Storage::disk('public')->exists($document->path)) {
            Storage::disk('public')->delete($document->path);
        }

        // 2. Xóa file ẢNH GỐC (nếu có) <--- ĐOẠN MỚI THÊM
        if ($document->original_path && Storage::disk('public')->exists($document->original_path)) {
            Storage::disk('public')->delete($document->original_path);
        }

        // 3. Xóa dữ liệu trong Database
        $document->delete();

        return response()->json([
            'message' => 'Đã xóa hoàn toàn tài liệu và file gốc!'
        ]);
    }

    public function update(Request $request, $id)
    {
        $request->validate([
            'name' => 'required|string|max:255', // Tên mới không được để trống
        ]);

        $user = $request->user();
        $document = Document::where('user_id', $user->id)->where('id', $id)->first();

        if (!$document) {
            return response()->json(['message' => 'Không tìm thấy file'], 404);
        }

        // Cập nhật tên mới vào cột original_name
        // (Lưu ý: Bạn có thể giữ đuôi file hoặc cho người dùng đổi luôn tùy thích)
        $document->original_name = $request->name;
        $document->save();

        return response()->json([
            'message' => 'Đổi tên thành công!',
            'document' => $document
        ]);
    }

    // API: Lấy danh sách lịch sử của User
    public function index(Request $request)
    {
        $user = $request->user();
        // Lấy danh sách file của user đó, sắp xếp mới nhất lên đầu
        $documents = Document::where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'documents' => $documents
        ]);
    }
    // API: Lấy thông tin dung lượng
    public function storageInfo(Request $request)
    {
        $user = $request->user();

        // Tính tổng size
        $usedBytes = Document::where('user_id', $user->id)->sum('size');
        $totalBytes = 1 * 1024 * 1024 * 1024; // 1GB

        return response()->json([
            'used_bytes' => (int)$usedBytes,
            'total_bytes' => $totalBytes,
            'percentage' => round(($usedBytes / $totalBytes) * 100, 2) // Tính phần trăm
        ]);
    }
}
