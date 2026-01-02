<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Document;
use Illuminate\Support\Facades\Storage;
use Barryvdh\DomPDF\Facade\Pdf;
use setasign\Fpdi\Fpdi; 

class DocumentController extends Controller
{
    // API: Upload ảnh và tạo PDF từ ảnh
    public function upload(Request $request)
    {
        set_time_limit(300);
        ini_set('memory_limit', '512M');

        $request->validate([
            'images' => 'required',
            'images.*' => 'image|mimes:jpeg,png,jpg,gif|max:10240',
        ]);

        try {
            $user = $request->user();
            $files = $request->file('images');
            if (!is_array($files)) {
                $files = [$files];
            }

            $htmlContent = '';
            $originalPaths = [];
            $totalSize = 0;
            $firstFileName = pathinfo($files[0]->getClientOriginalName(), PATHINFO_FILENAME);

            foreach ($files as $index => $file) {
                $originalName = $file->getClientOriginalName();
                $totalSize += $file->getSize();

                $imageName = time() . "_{$index}_" . $originalName;
                $originalPath = $file->storeAs('uploads', $imageName, 'public');
                $originalPaths[] = $originalPath;

                $fullPath = storage_path('app/public/' . $originalPath);
                $imageData = base64_encode(file_get_contents($fullPath));
                $src = 'data:' . $file->getMimeType() . ';base64,' . $imageData;

                $pageBreak = ($index < count($files) - 1) ? 'page-break-after: always;' : '';
                $htmlContent .= '<div style="text-align: center; width: 100%; height: 100%; ' . $pageBreak . '">
                                    <img src="' . $src . '" style="max-width: 100%; max-height: 100%;">
                                 </div>';
            }

            $pdfName = time() . '_' . $firstFileName . '_merged.pdf';
            $pdf = Pdf::loadHTML($htmlContent)->setPaper('a4', 'portrait');
            $pdfPath = 'uploads/' . $pdfName;
            
            Storage::disk('public')->put($pdfPath, $pdf->output());
            $totalSize += Storage::disk('public')->size($pdfPath);

            $document = Document::create([
                'user_id' => $user->id,
                'original_name' => $firstFileName . '.pdf',
                'path' => $pdfPath,
                'original_path' => json_encode($originalPaths),
                'status' => 'completed',
                'type' => 'pdf',
                'size' => $totalSize,
            ]);

            return response()->json([
                'message' => 'Upload và chuyển đổi thành công!',
                'document' => $document,
            ], 200);

        } catch (\Exception $e) {
            return response()->json(['message' => 'Lỗi server: ' . $e->getMessage()], 500);
        }
    }

    // --- API MỚI: GỘP CÁC FILE PDF CÓ SẴN ---
    public function mergePdfs(Request $request)
    {
        $request->validate([
            'document_ids' => 'required|array|min:2',
        ]);

        try {
            $user = $request->user();
            $documents = Document::where('user_id', $user->id)
                                 ->whereIn('id', $request->document_ids)
                                 ->get();

            if ($documents->count() < 2) {
                return response()->json(['message' => 'Cần ít nhất 2 file để gộp'], 400);
            }

            $pdf = new Fpdi();
            $mergedOriginalPaths = [];

            foreach ($documents as $doc) {
                $filePath = storage_path('app/public/' . $doc->path);
                
                if (!file_exists($filePath)) continue;

                // Lưu lại danh sách ảnh gốc từ các file cũ (nếu có)
                if ($doc->original_path) {
                    $paths = json_decode($doc->original_path, true);
                    if (is_array($paths)) {
                        $mergedOriginalPaths = array_merge($mergedOriginalPaths, $paths);
                    }
                }

                $pageCount = $pdf->setSourceFile($filePath);
                for ($i = 1; $i <= $pageCount; $i++) {
                    $tplIdx = $pdf->importPage($i);
                    $specs = $pdf->getTemplateSize($tplIdx);
                    $pdf->AddPage($specs['orientation'], [$specs['width'], $specs['height']]);
                    $pdf->useTemplate($tplIdx);
                }
            }

            $fileName = 'combined_' . time() . '.pdf';
            $outputPath = 'uploads/' . $fileName;
            Storage::disk('public')->put($outputPath, $pdf->Output('S'));

            $newDoc = Document::create([
                'user_id' => $user->id,
                'original_name' => 'Gộp_' . time() . '.pdf',
                'path' => $outputPath,
                'original_path' => json_encode($mergedOriginalPaths),
                'status' => 'completed',
                'type' => 'pdf',
                'size' => Storage::disk('public')->size($outputPath),
            ]);

            return response()->json([
                'message' => 'Gộp file thành công!',
                'document' => $newDoc
            ], 201);

        } catch (\Exception $e) {
            return response()->json(['message' => 'Lỗi khi gộp: ' . $e->getMessage()], 500);
        }
    }

    // API: Xóa tài liệu
    public function destroy(Request $request, $id)
    {
        $user = $request->user();
        $document = Document::where('user_id', $user->id)->where('id', $id)->first();

        if (!$document) {
            return response()->json(['message' => 'Không tìm thấy file'], 404);
        }

        // 1. Xóa file kết quả
        if ($document->path) {
            Storage::disk('public')->delete($document->path);
        }

        // 2. Xóa tất cả ảnh gốc (vì original_path là mảng JSON)
        if ($document->original_path) {
            $paths = json_decode($document->original_path, true);
            if (is_array($paths)) {
                foreach ($paths as $p) {
                    Storage::disk('public')->delete($p);
                }
            }
        }

        $document->delete();
        return response()->json(['message' => 'Đã xóa hoàn toàn!']);
    }

    public function update(Request $request, $id)
    {
        $request->validate(['name' => 'required|string|max:255']);
        $document = Document::where('user_id', auth()->id())->where('id', $id)->first();
        if (!$document) return response()->json(['message' => 'Không thấy file'], 404);

        $document->original_name = $request->name;
        $document->save();

        return response()->json(['message' => 'Đổi tên thành công!', 'document' => $document]);
    }

    public function index(Request $request)
    {
        $documents = Document::where('user_id', auth()->id())->orderBy('created_at', 'desc')->get();
        return response()->json(['documents' => $documents]);
    }

    public function storageInfo(Request $request)
    {
        $usedBytes = Document::where('user_id', auth()->id())->sum('size');
        $totalBytes = 1024 * 1024 * 1024; // 1GB
        return response()->json([
            'used_bytes' => (int)$usedBytes,
            'total_bytes' => $totalBytes,
            'percentage' => round(($usedBytes / $totalBytes) * 100, 2)
        ]);
    }
}