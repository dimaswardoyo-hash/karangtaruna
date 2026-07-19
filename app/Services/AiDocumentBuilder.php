<?php

namespace App\Services;

use App\Models\Agenda;
use App\Models\DanaLain;
use App\Models\Hutang;
use App\Models\Kas;
use App\Models\Notulen;
use App\Models\Peminjaman;
use App\Models\Pengeluaran;
use App\Models\Perlengkapan;

/**
 * Mengubah satu record model jadi dokumen teks untuk knowledge base RAG.
 * Dipakai bersama oleh ExportKnowledgeBase (bulk/manual) dan Observers
 * (otomatis, real-time) supaya format kontennya selalu konsisten.
 */
class AiDocumentBuilder
{
    public static function kas(Kas $kas): array
    {
        return [
            'division' => 'keuangan',
            'source_type' => 'kas',
            'id' => $kas->id,
            'content' => "Kas masuk tanggal {$kas->tanggal} sejumlah Rp{$kas->jumlah} dari {$kas->user?->name}. Deskripsi: {$kas->deskripsi}.",
        ];
    }

    public static function pengeluaran(Pengeluaran $p): array
    {
        return [
            'division' => 'keuangan',
            'source_type' => 'pengeluaran',
            'id' => $p->id,
            'content' => "Pengeluaran untuk kegiatan {$p->kegiatan} tanggal {$p->tanggal} sejumlah Rp{$p->jumlah}, sumber dana: {$p->sumber_dana}. Deskripsi: {$p->deskripsi}.",
        ];
    }

    public static function danaLain(DanaLain $d): array
    {
        return [
            'division' => 'keuangan',
            'source_type' => 'dana_lain',
            'id' => $d->id,
            'content' => "Dana lain tanggal {$d->tanggal} sejumlah Rp{$d->jumlah}. Deskripsi: {$d->deskripsi}.",
        ];
    }

    public static function hutang(Hutang $h): array
    {
        return [
            'division' => 'keuangan',
            'source_type' => 'hutang',
            'id' => $h->id,
            'content' => "Hutang anggota {$h->user?->name} tanggal {$h->tanggal} sejumlah Rp{$h->jumlah}. Keterangan: {$h->keterangan}.",
        ];
    }

    public static function agenda(Agenda $a): array
    {
        $jumlahHadir = $a->presensis()->count();

        return [
            'division' => 'kegiatan',
            'source_type' => 'agenda',
            'id' => $a->id,
            'content' => "Agenda '{$a->nama_agenda}' kategori {$a->kategori} berlangsung {$a->waktu_mulai} sampai {$a->waktu_selesai} di {$a->lokasi}. Deskripsi: {$a->deskripsi}. Jumlah anggota yang presensi: {$jumlahHadir}.",
        ];
    }

    public static function notulen(Notulen $n): array
    {
        $n->loadMissing('agenda');

        return [
            'division' => 'kegiatan',
            'source_type' => 'notulen',
            'id' => $n->id,
            'content' => "Notulen rapat agenda '{$n->agenda?->nama_agenda}'. Pembicara: {$n->pembicara}. Poin pembahasan: {$n->poin_pembahasan}. Kesimpulan: {$n->kesimpulan}.",
        ];
    }

    public static function perlengkapan(Perlengkapan $barang): array
    {
        return [
            'division' => 'perlengkapan',
            'source_type' => 'perlengkapan',
            'id' => $barang->id,
            'content' => "Barang '{$barang->nama}' total stok {$barang->stok_awal}, sisa stok {$barang->stok}, sedang dipinjam {$barang->sedang_dipinjam}. Deskripsi: {$barang->deskripsi}.",
        ];
    }

    public static function peminjaman(Peminjaman $pinjam): array
    {
        $pinjam->loadMissing('user', 'perlengkapan');

        return [
            'division' => 'perlengkapan',
            'source_type' => 'peminjaman',
            'id' => $pinjam->id,
            'content' => "Peminjaman barang '{$pinjam->perlengkapan?->nama}' oleh {$pinjam->user?->name} sejumlah {$pinjam->jumlah}, status {$pinjam->status}, tanggal pinjam {$pinjam->tanggal_pinjam} rencana kembali {$pinjam->tanggal_kembali}.",
        ];
    }
}
