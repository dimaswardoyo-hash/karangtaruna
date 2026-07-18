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
use App\Models\Presensi;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;

class ExportKnowledgeBase extends Command
{
    /**
     * php artisan ai:export-knowledge
     * Tambahkan --push untuk langsung mengirim dokumen baru ke AI service
     * (endpoint /ingest) agar di-embed ke Vector DB.
     */
    protected $signature = 'ai:export-knowledge {--push : Kirim dokumen baru ke AI service setelah export}';

    protected $description = 'Export data Keuangan, Kegiatan, dan Perlengkapan menjadi dokumen teks untuk knowledge base RAG';

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
            $content = "Kas masuk tanggal {$kas->tanggal} sejumlah Rp{$kas->jumlah} dari {$kas->user?->name}. Deskripsi: {$kas->deskripsi}.";
            $n += $this->upsertDoc('keuangan', 'kas', $kas->id, $content);
        }

        foreach (Pengeluaran::all() as $p) {
            $content = "Pengeluaran untuk kegiatan {$p->kegiatan} tanggal {$p->tanggal} sejumlah Rp{$p->jumlah}, sumber dana: {$p->sumber_dana}. Deskripsi: {$p->deskripsi}.";
            $n += $this->upsertDoc('keuangan', 'pengeluaran', $p->id, $content);
        }

        foreach (DanaLain::all() as $d) {
            $content = "Dana lain tanggal {$d->tanggal} sejumlah Rp{$d->jumlah}. Deskripsi: {$d->deskripsi}.";
            $n += $this->upsertDoc('keuangan', 'dana_lain', $d->id, $content);
        }

        foreach (Hutang::with('user')->get() as $h) {
            $content = "Hutang anggota {$h->user?->name} tanggal {$h->tanggal} sejumlah Rp{$h->jumlah}. Keterangan: {$h->keterangan}.";
            $n += $this->upsertDoc('keuangan', 'hutang', $h->id, $content);
        }

        return $n;
    }

    private function exportKegiatan(): int
    {
        $n = 0;

        foreach (Agenda::with('presensis.user')->get() as $a) {
            $jumlahHadir = $a->presensis->count();
            $content = "Agenda '{$a->nama_agenda}' kategori {$a->kategori} berlangsung {$a->waktu_mulai} sampai {$a->waktu_selesai} di {$a->lokasi}. Deskripsi: {$a->deskripsi}. Jumlah anggota yang presensi: {$jumlahHadir}.";
            $n += $this->upsertDoc('kegiatan', 'agenda', $a->id, $content);
        }

        foreach (Notulen::with('agenda')->get() as $notulen) {
            $content = "Notulen rapat agenda '{$notulen->agenda?->nama_agenda}'. Pembicara: {$notulen->pembicara}. Poin pembahasan: {$notulen->poin_pembahasan}. Kesimpulan: {$notulen->kesimpulan}.";
            $n += $this->upsertDoc('kegiatan', 'notulen', $notulen->id, $content);
        }

        return $n;
    }

    private function exportPerlengkapan(): int
    {
        $n = 0;

        foreach (Perlengkapan::all() as $barang) {
            $content = "Barang '{$barang->nama}' total stok {$barang->stok_awal}, sisa stok {$barang->stok}, sedang dipinjam {$barang->sedang_dipinjam}. Deskripsi: {$barang->deskripsi}.";
            $n += $this->upsertDoc('perlengkapan', 'perlengkapan', $barang->id, $content);
        }

        foreach (Peminjaman::with(['user', 'perlengkapan'])->get() as $pinjam) {
            $content = "Peminjaman barang '{$pinjam->perlengkapan?->nama}' oleh {$pinjam->user?->name} sejumlah {$pinjam->jumlah}, status {$pinjam->status}, tanggal pinjam {$pinjam->tanggal_pinjam} rencana kembali {$pinjam->tanggal_kembali}.";
            $n += $this->upsertDoc('perlengkapan', 'peminjaman', $pinjam->id, $content);
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