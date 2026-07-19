<?php

namespace App\Providers;

use App\Models\Agenda;
use App\Models\DanaLain;
use App\Models\Hutang;
use App\Models\Kas;
use App\Models\Notulen;
use App\Models\Peminjaman;
use App\Models\Pengeluaran;
use App\Models\Perlengkapan;
use App\Observers\AgendaObserver;
use App\Observers\DanaLainObserver;
use App\Observers\HutangObserver;
use App\Observers\KasObserver;
use App\Observers\NotulenObserver;
use App\Observers\PeminjamanObserver;
use App\Observers\PengeluaranObserver;
use App\Observers\PerlengkapanObserver;
use Illuminate\Support\ServiceProvider;

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
        // Sinkronisasi otomatis ke knowledge base RAG (ai-service) setiap kali
        // data keuangan/kegiatan/perlengkapan dibuat, diubah, atau dihapus.
        // Menggantikan kebutuhan menjalankan `ai:export-knowledge --push` manual
        // setelah setiap perubahan data (command itu tetap ada untuk backfill awal
        // atau resync massal kalau ai-service sempat mati saat ada perubahan).
        Kas::observe(KasObserver::class);
        Pengeluaran::observe(PengeluaranObserver::class);
        DanaLain::observe(DanaLainObserver::class);
        Hutang::observe(HutangObserver::class);
        Agenda::observe(AgendaObserver::class);
        Notulen::observe(NotulenObserver::class);
        Perlengkapan::observe(PerlengkapanObserver::class);
        Peminjaman::observe(PeminjamanObserver::class);
    }
}
