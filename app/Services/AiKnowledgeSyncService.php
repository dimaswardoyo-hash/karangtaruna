<?php

namespace App\Services;

use App\Models\AiDocument;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Sinkronisasi real-time satu dokumen ke knowledge base RAG. Dipanggil oleh
 * Observer setiap kali data (kas, agenda, dst) dibuat/diubah/dihapus, supaya
 * AI Assistant selalu tahu data terbaru tanpa perlu menjalankan
 * `php artisan ai:export-knowledge --push` secara manual.
 */
class AiKnowledgeSyncService
{
    public function sync(string $division, string $sourceType, int $sourceId, string $content): void
    {
        $existing = AiDocument::where('division', $division)
            ->where('source_type', $sourceType)
            ->where('source_id', $sourceId)
            ->first();

        $changed = !$existing || $existing->content !== $content;

        $doc = AiDocument::updateOrCreate(
            ['division' => $division, 'source_type' => $sourceType, 'source_id' => $sourceId],
            $changed ? ['content' => $content, 'embedded_at' => null] : ['content' => $content]
        );

        if (!$changed) {
            return;
        }

        $this->pushOne($doc);
    }

    public function delete(string $division, string $sourceType, int $sourceId): void
    {
        // Catatan/keterbatasan: ini menghapus catatannya di ai_documents, tapi
        // ai-service belum punya endpoint hapus-per-id di vector store, jadi
        // entri lama di vector store tetap ada (stale) sampai iterasi berikutnya
        // menambahkan endpoint DELETE /documents/{id}.
        AiDocument::where('division', $division)
            ->where('source_type', $sourceType)
            ->where('source_id', $sourceId)
            ->delete();
    }

    private function pushOne(AiDocument $doc): void
    {
        try {
            $response = Http::timeout(15)->post(
                rtrim(config('services.ai_service.url'), '/') . '/ingest',
                [
                    'documents' => [[
                        'id' => $doc->id,
                        'division' => $doc->division,
                        'source_type' => $doc->source_type,
                        'content' => $doc->content,
                    ]],
                ]
            );

            if ($response->successful()) {
                $doc->update(['embedded_at' => now()]);
            } else {
                Log::warning('Sync real-time ke AI service gagal, akan ikut terkirim saat export manual berikutnya', [
                    'status' => $response->status(),
                    'ai_document_id' => $doc->id,
                ]);
            }
        } catch (\Throwable $e) {
            // ai-service sedang mati/tidak terjangkau. Tidak perlu menggagalkan
            // proses simpan data utama karena ini hanya operasi sinkronisasi.
            // embedded_at tetap null, sehingga otomatis ikut terkirim saat
            // `php artisan ai:export-knowledge --push` dijalankan sebagai fallback.
            Log::info('AI service tidak terjangkau saat sync real-time, akan di-retry via export manual', [
                'error' => $e->getMessage(),
                'ai_document_id' => $doc->id,
            ]);
        }
    }
}
