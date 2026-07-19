<?php

namespace App\Console\Commands;

use App\Models\AiDocument;
use App\Models\Agenda;
use App\Models\DanaLain;
use App\Models\Hutang;
use App\Models\Kas;
use App\Models\Notulen;
use App\Models\Peminjaman;
use App\Models\Pengeluaran;
use App\Models\Perlengkapan;
use App\Services\AiDocumentBuilder;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;

class ExportKnowledgeBase extends Command
{
    /**
     * php artisan ai:export-knowledge
     * Tambahkan --push untuk langsung mengirim dokumen baru ke AI service
     * (endpoint /ingest) agar di-embed ke Vector DB.
     *
     * Catatan: sejak ditambahkan Observer (lihat app/Observers), data yang
     * dibuat/diubah/dihapus lewat aplikasi akan otomatis sync ke knowledge
     * base secara real-time. Command ini sekarang terutama dipakai untuk:
     * (1) backfill data lama saat pertama kali setup, atau
     * (2) resync massal kalau ai-service sempat mati saat ada perubahan data
     *     (dokumen yang gagal sync real-time tetap punya embedded_at = null,
     *     jadi otomatis ikut terkirim di sini).
     */
    protected $signature = 'ai:export-knowledge {--push : Kirim dokumen baru ke AI service setelah export}';

    protected $description = 'Export data Keuangan, Kegiatan, dan Perlengkapan menjadi dokumen teks untuk knowledge base RAG (backfill/resync manual)';

    public function handle(): int
    {
        $this->info('Mengekspor data ke ai_documents...');

        $count = 0;
        $count += $this->exportKeuangan();
        $count += $this->exportKegiatan();
        $count += $this->exportPerlengkapan();

        $this->info("Selesai. {$count} dokumen baru dibuat/diperbarui.");

        if ($this->option('push')) {
            $this->pushToAiService();
        }

        return self::SUCCESS;
    }

    private function upsertDoc(string $division, string $sourceType, int $sourceId, string $content): int
    {
        $existing = AiDocument::where('division', $division)
            ->where('source_type', $sourceType)
            ->where('source_id', $sourceId)
            ->first();

        // Hanya reset embedded_at kalau dokumen baru atau isinya benar-benar berubah,
        // supaya dokumen yang tidak berubah tidak ikut di-re-embed setiap kali command dijalankan.
        $contentChanged = !$existing || $existing->content !== $content;

        $doc = AiDocument::updateOrCreate(
            ['division' => $division, 'source_type' => $sourceType, 'source_id' => $sourceId],
            $contentChanged
                ? ['content' => $content, 'embedded_at' => null]
                : ['content' => $content]
        );

        return $doc->wasRecentlyCreated || $contentChanged ? 1 : 0;
    }

    private function exportKeuangan(): int
    {
        $n = 0;

        foreach (Kas::with('user')->get() as $kas) {
            $doc = AiDocumentBuilder::kas($kas);
            $n += $this->upsertDoc($doc['division'], $doc['source_type'], $doc['id'], $doc['content']);
        }

        foreach (Pengeluaran::all() as $p) {
            $doc = AiDocumentBuilder::pengeluaran($p);
            $n += $this->upsertDoc($doc['division'], $doc['source_type'], $doc['id'], $doc['content']);
        }

        foreach (DanaLain::all() as $d) {
            $doc = AiDocumentBuilder::danaLain($d);
            $n += $this->upsertDoc($doc['division'], $doc['source_type'], $doc['id'], $doc['content']);
        }

        foreach (Hutang::with('user')->get() as $h) {
            $doc = AiDocumentBuilder::hutang($h);
            $n += $this->upsertDoc($doc['division'], $doc['source_type'], $doc['id'], $doc['content']);
        }

        return $n;
    }

    private function exportKegiatan(): int
    {
        $n = 0;

        foreach (Agenda::with('presensis.user')->get() as $a) {
            $doc = AiDocumentBuilder::agenda($a);
            $n += $this->upsertDoc($doc['division'], $doc['source_type'], $doc['id'], $doc['content']);
        }

        foreach (Notulen::with('agenda')->get() as $notulen) {
            $doc = AiDocumentBuilder::notulen($notulen);
            $n += $this->upsertDoc($doc['division'], $doc['source_type'], $doc['id'], $doc['content']);
        }

        return $n;
    }

    private function exportPerlengkapan(): int
    {
        $n = 0;

        foreach (Perlengkapan::all() as $barang) {
            $doc = AiDocumentBuilder::perlengkapan($barang);
            $n += $this->upsertDoc($doc['division'], $doc['source_type'], $doc['id'], $doc['content']);
        }

        foreach (Peminjaman::with(['user', 'perlengkapan'])->get() as $pinjam) {
            $doc = AiDocumentBuilder::peminjaman($pinjam);
            $n += $this->upsertDoc($doc['division'], $doc['source_type'], $doc['id'], $doc['content']);
        }

        return $n;
    }

    private function pushToAiService(): void
    {
        $docs = AiDocument::belumDiEmbed()->get();

        if ($docs->isEmpty()) {
            $this->info('Tidak ada dokumen baru untuk dikirim ke AI service.');
            return;
        }

        $this->info("Mengirim {$docs->count()} dokumen ke AI service...");

        $response = Http::timeout(60)->post(
            rtrim(config('services.ai_service.url'), '/') . '/ingest',
            [
                'documents' => $docs->map(fn ($d) => [
                    'id' => $d->id,
                    'division' => $d->division,
                    'source_type' => $d->source_type,
                    'content' => $d->content,
                ])->values(),
            ]
        );

        if ($response->successful()) {
            AiDocument::whereIn('id', $docs->pluck('id'))->update(['embedded_at' => now()]);
            $this->info('Berhasil di-embed ke Vector DB.');
        } else {
            $this->error('Gagal mengirim ke AI service: ' . $response->status() . ' ' . $response->body());
        }
    }
}