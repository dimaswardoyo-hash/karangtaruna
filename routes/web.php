<?php

use App\Http\Controllers\AiAssistantController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\{AgendaController, AuthController, BroadcastController, ContentController, DashboardController, FinanceController, HomeController, ManageUsersController, PerlengkapanController, ProfileController, StrukturController, UndanganController};

/*
|--------------------------------------------------------------------------
| ROUTE PUBLIK (Halaman Umum)
|--------------------------------------------------------------------------
*/
Route::get('/', [HomeController::class, 'index'])->name('home');
Route::get('/kategori', [HomeController::class, 'kategoryPage'])->name('kategori');
Route::get('/kategori/{id}', [HomeController::class, 'kategori'])->name('kategori.show');
Route::get('/konten/{id}', [HomeController::class, 'show'])->name('konten.show');
Route::get('/keanggotaan', [HomeController::class, 'keanggotaan'])->name('keanggotaan');
Route::get('/tentang-kami', [HomeController::class, 'tentang'])->name('tentangKami');

/*
|--------------------------------------------------------------------------
| ROUTE AUTENTIKASI (Login, Register, Logout)
|--------------------------------------------------------------------------
*/
Route::controller(AuthController::class)->group(function () {
    Route::get('/login', 'showLoginForm')->name('login');
    Route::post('/login', 'login');
    Route::get('/register', 'showRegisterForm')->name('register');
    Route::post('/register', 'register');
    Route::post('/logout', 'logout')->name('logout');
});

/*
|--------------------------------------------------------------------------
| ROUTE YANG HARUS LOGIN (Semua Role)
|--------------------------------------------------------------------------
*/
Route::middleware(['auth'])->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'dashboard'])->name('dashboard');
    Route::get('/struktur', [StrukturController::class, 'index'])->name('struktur.index');

    Route::get('/ai-assistant', [AiAssistantController::class, 'index'])->name('ai.index');
    Route::post('/ai-assistant/query', [AiAssistantController::class, 'query'])->name('ai.query');
    Route::delete('/ai-assistant/history/{aiQuery}', [AiAssistantController::class, 'destroyHistory'])->name('ai.history.destroy');
    Route::delete('/ai-assistant/history', [AiAssistantController::class, 'clearHistory'])->name('ai.history.clear');
});

/*
|--------------------------------------------------------------------------
| ROUTE ADMIN (Hanya Bisa Diakses oleh Role: Admin)
|--------------------------------------------------------------------------
*/
Route::middleware(['auth', 'role:admin'])->group(function () {
    /*
    |--------------------------------------------------------------------------
    | AGENDA & PRESENSI
    |--------------------------------------------------------------------------
    */
    Route::get('/agenda/presensi/{id}', [AgendaController::class, 'presensiIndex'])->name('agenda.presensi.index');
    Route::get('/agenda/admin', [AgendaController::class, 'agendaIndex'])->name('agenda.admin.index');
    Route::get('/agenda/{id}/admin', [AgendaController::class, 'agendaShow'])->name('agenda.admin.show');
    Route::get('/agenda/admin/create', [AgendaController::class, 'agendaCreate'])->name('agenda.admin.create');
    Route::post('/agenda', [AgendaController::class, 'agendaStore'])->name('agenda.store');
    Route::get('/agenda/{id}/edit', [AgendaController::class, 'agendaEdit'])->name('agenda.edit');
    Route::put('/agenda/{id}', [AgendaController::class, 'agendaUpdate'])->name('agenda.update');
    Route::delete('/agenda/{id}', [AgendaController::class, 'agendaDestroy'])->name('agenda.destroy');

    Route::post('/agenda/{id}/presensi/open', [AgendaController::class, 'presensiOpen'])->name('presensi.open');
    Route::post('/agenda/{id}/presensi/close', [AgendaController::class, 'presensiClose'])->name('presensi.close');
    Route::get('/agenda/{id}/presensi', [AgendaController::class, 'presensiShow'])->name('presensi.show');

    /*
    |--------------------------------------------------------------------------
    | NOTULEN AGENDA
    |--------------------------------------------------------------------------
    */
    Route::get('/agenda/notulen/create', [AgendaController::class, 'notulenCreate'])->name('notulen.create');
    Route::post('/agenda/notulen', [AgendaController::class, 'notulenStore'])->name('notulen.store');
    Route::get('/agenda/notulen/{notulen}/edit', [AgendaController::class, 'notulenEdit'])->name('notulen.edit');
    Route::put('/agenda/notulen/{notulen}', [AgendaController::class, 'notulenUpdate'])->name('notulen.update');
    Route::get('/agenda/notulen/{id}', [AgendaController::class, 'notulenShow'])->name('notulen.show');

    /*
    |--------------------------------------------------------------------------
    | PERLENGKAPAN & PEMINJAMAN
    |--------------------------------------------------------------------------
    */
    Route::get('/perlengkapan/admin', [PerlengkapanController::class, 'perlengkapanIndex'])->name('perlengkapan.admin.index');
    Route::get('/perlengkapan/create', [PerlengkapanController::class, 'perlengkapanCreate'])->name('perlengkapan.create');
    Route::post('/perlengkapan', [PerlengkapanController::class, 'perlengkapanStore'])->name('perlengkapan.store');
    Route::get('/perlengkapan/{perlengkapan}/edit', [PerlengkapanController::class, 'perlengkapanEdit'])->name('perlengkapan.edit');
    Route::put('/perlengkapan/{perlengkapan}', [PerlengkapanController::class, 'perlengkapanUpdate'])->name('perlengkapan.update');
    Route::delete('/perlengkapan/{perlengkapan}', [PerlengkapanController::class, 'perlengkapanDestroy'])->name('perlengkapan.destroy');
    Route::get('/perlengkapan/peminjaman/tanggapan', [PerlengkapanController::class, 'daftarPengajuan'])->name('peminjaman.tanggapan');
    Route::get('/perlengkapan/{perlengkapan}/admin', [PerlengkapanController::class, 'perlengkapanShow'])->name('perlengkapan.admin.show');
    Route::post('/perlengkapan/peminjaman/{user_id}/{perlengkapan_id}', [PerlengkapanController::class, 'tanggapi'])->name('peminjaman.tanggapi');

    /*
    |--------------------------------------------------------------------------
    | KEUANGAN
    |--------------------------------------------------------------------------
    */
    Route::get('/finance/admin/index', [FinanceController::class, 'index'])->name('finance.admin.index');
    Route::get('/finance/kas/create', [FinanceController::class, 'createKas'])->name('finance.kas.create');
    Route::post('/finance/kas/store', [FinanceController::class, 'storeKas'])->name('finance.kas.store');
    Route::get('/finance/dana-lain/create', [FinanceController::class, 'createDanaLain'])->name('finance.dana-lain.create');
    Route::post('/finance/dana-lain/store', [FinanceController::class, 'storeDanaLain'])->name('finance.dana_lain.store');
    Route::get('/finance/pengeluaran/create', [FinanceController::class, 'createPengeluaran'])->name('finance.pengeluaran.create');
    Route::post('/finance/pengeluaran/store', [FinanceController::class, 'storePengeluaran'])->name('finance.pengeluaran.store');
    Route::get('/finance/hutang', [FinanceController::class, 'daftarHutang'])->name('finance.hutang');
    Route::post('/finance/hutang/{id}/selesai', [FinanceController::class, 'selesaikanHutang'])->name('finance.selesai_hutang');

    /*
    |--------------------------------------------------------------------------
    | PROFIL & MANAJEMEN PENGGUNA
    |--------------------------------------------------------------------------
    */
    Route::get('/profile/index', [ProfileController::class, 'index'])->name('profile.index');
    Route::get('/profile/edit/{identitas}', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::put('/profile/update/{identitas}', [ProfileController::class, 'update'])->name('profile.update');
    Route::get('/profile/create-admin', [ProfileController::class, 'create'])->name('profile.create-admin');
    Route::post('/profile/store-admin', [ProfileController::class, 'store'])->name('profile.store-admin');

    Route::get('/manageUsers', [ManageUsersController::class, 'index'])->name('manageUsers.index');
    Route::get('/manageUsers/create', [ManageUsersController::class, 'create'])->name('manageUsers.create');
    Route::post('/manageUsers', [ManageUsersController::class, 'store'])->name('manageUsers.store');
    Route::get('/manageUsers/{id}', [ManageUsersController::class, 'show'])->name('manageUsers.show');
    Route::get('/manageUsers/{id}/edit', [ManageUsersController::class, 'edit'])->name('manageUsers.edit');
    Route::put('/manageUsers/{id}', [ManageUsersController::class, 'update'])->name('manageUsers.update');
    Route::delete('/manageUsers/{id}', [ManageUsersController::class, 'destroy'])->name('manageUsers.destroy');
    Route::get('/profile/edit-profile', [ManageUsersController::class, 'editProfile'])->name('profile.edit-profile');
    Route::put('/profile/update-profile', [ManageUsersController::class, 'updateProfile'])->name('profile.update-profile');

    /*
    |--------------------------------------------------------------------------
    | KONTEN (Konten, Kategori, Banner)
    |--------------------------------------------------------------------------
    */
    Route::get('/content', [ContentController::class, 'index'])->name('content.index');
    Route::get('/content/konten/create', [ContentController::class, 'create'])->name('konten.create');
    Route::post('/content', [ContentController::class, 'contentStore'])->name('content.store');
    Route::get('/content/{id}', [ContentController::class, 'contentShow'])->name('content.show');
    Route::get('/content/{id}/edit', [ContentController::class, 'edit'])->name('content.edit');
    Route::put('/content/{id}/update', [ContentController::class, 'update'])->name('content.update');
    Route::delete('/content/{id}', [ContentController::class, 'destroy'])->name('content.destroy');

    Route::get('/content/kategori/create', [ContentController::class, 'createCategory'])->name('content.kategori.create');
    Route::post('/content/kategori', [ContentController::class, 'storeCategory'])->name('content.kategori.store');
    Route::get('/content/kategori/{id}/edit', [ContentController::class, 'editCategory'])->name('content.kategori.edit');
    Route::put('/content/kategori/{id}', [ContentController::class, 'updateCategory'])->name('content.kategori.update');
    Route::delete('/content/kategori/{id}', [ContentController::class, 'destroyCategory'])->name('content.kategori.destroy');

    Route::get('/content/kategori/banner-create', [ContentController::class, 'bannerCreate'])->name('content.banneer-create');
    Route::post('/content/kategori/banner', [ContentController::class, 'bannerStore'])->name('content.banner.store');
    Route::get('/content/banner/{id}/edit', [ContentController::class, 'bannerEdit'])->name('content.banner.edit');
    Route::put('/content/banner/{id}', [ContentController::class, 'bannerUpdate'])->name('content.banner.update');
    Route::delete('/content/banner/{id}', [ContentController::class, 'bannerDestroy'])->name('content.banner.destroy');

    /*
    |--------------------------------------------------------------------------
    | STRUKTUR ORGANISASI
    |--------------------------------------------------------------------------
    */
    Route::get('/struktur/create', [StrukturController::class, 'create'])->name('struktur.create');
    Route::post('/struktur', [StrukturController::class, 'store'])->name('struktur.store');
    Route::get('/struktur/{id}/edit', [StrukturController::class, 'edit'])->name('struktur.edit');
    Route::put('/struktur/{id}', [StrukturController::class, 'update'])->name('struktur.update');
    Route::delete('/struktur/{id}', [StrukturController::class, 'destroy'])->name('struktur.destroy');

    /*
    |--------------------------------------------------------------------------
    | BROADCAST & UNDANGAN
    |--------------------------------------------------------------------------
    */
    Route::resource('broadcast', BroadcastController::class)->except('show');
    Route::post('/broadcast/send', [BroadcastController::class, 'send'])->name('broadcast.send');

    Route::resource('undangan', UndanganController::class);
    Route::get('/undangan/{id}/pdf', [UndanganController::class, 'exportPdf'])->name('undangan.pdf');
    Route::get('/undangan/{id}/word', [UndanganController::class, 'exportWord'])->name('undangan.word');

    Route::get('/ai-assistant/insight', [AiAssistantController::class, 'insight'])->name('ai.insight');
});

/*
|--------------------------------------------------------------------------
| ROUTE ANGGOTA (Hanya Bisa Diakses oleh Role: Anggota)
|--------------------------------------------------------------------------
*/
Route::middleware(['auth', 'role:anggota'])->group(function () {
    /*
    |--------------------------------------------------------------------------
    | DASHBOARD & PROFIL
    |--------------------------------------------------------------------------
    */
    Route::get('/anggota/dashboard', [DashboardController::class, 'anggotaDashboard'])->name('anggota.dashboard');

    Route::get('/profile', [ProfileController::class, 'index'])->name('anggota.profile.index');
    Route::get('/profile/edit', [ManageUsersController::class, 'editProfile'])->name('anggota.profile.edit-profile');
    Route::get('/profile/{identitas}/edit', [ProfileController::class, 'edit'])->name('profile.anggota.edit');
    Route::put('/profile/{identitas}/anggota-update', [ProfileController::class, 'update'])->name('profile.anggota-update');
    Route::get('/profile/anggota/create', [ProfileController::class, 'create'])->name('profile.anggota.create');
    Route::put('/profile/anggota/update', [ManageUsersController::class, 'updateProfile'])->name('profile.anggota.update');
    Route::post('/profile/anggota/store', [ProfileController::class, 'store'])->name('profile.anggota.store');

    /*
    |--------------------------------------------------------------------------
    | AGENDA & NOTULEN
    |--------------------------------------------------------------------------
    */
    Route::get('/agenda/anggota/index', [AgendaController::class, 'agendaIndex'])->name('agenda.anggota.index');
    Route::get('/agenda/{id}/anggota/show', [AgendaController::class, 'agendaShow'])->name('agenda.anggota.show');
    Route::post('/agenda/{id}/presensi', [AgendaController::class, 'presensiStore'])->name('presensi.store');
    Route::get('/agenda/notulen/{id}', [AgendaController::class, 'notulenShow'])->name('notulen.show');

    /*
    |--------------------------------------------------------------------------
    | PERLENGKAPAN & PEMINJAMAN
    |--------------------------------------------------------------------------
    */
    Route::get('/perlengkapan/anggota/index', [PerlengkapanController::class, 'perlengkapanIndex'])->name('perlengkapan.anggota.index');
    Route::get('/perlengkapan/{perlengkapan}/anggota/show', [PerlengkapanController::class, 'perlengkapanShow'])->name('perlengkapan.anggota.show');
    Route::get('/peminjaman', [PerlengkapanController::class, 'peminjamanIndex'])->name('peminjaman.index');
    Route::get('/perlengkapan/peminjaman/create/{id}', [PerlengkapanController::class, 'peminjamanCreate'])->name('peminjaman.create');
    Route::post('/perlengkapan/peminjaman', [PerlengkapanController::class, 'peminjamanStore'])->name('peminjaman.store');

    /*
    |--------------------------------------------------------------------------
    | KEUANGAN
    |--------------------------------------------------------------------------
    */
    Route::get('/finance/anggota/index', [FinanceController::class, 'index'])->name('finance.anggota.index');
});
