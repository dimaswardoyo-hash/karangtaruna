<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Agenda;
use App\Models\Banner;
use App\Models\Identitas;
use App\Models\Kategori;
use App\Models\Konten;
use App\Models\Struktur;
use App\Models\User;

class HomeController extends Controller
{
    public function index()
    {
        $events = Agenda::where('kategori', 'kegiatan')
            ->whereDate('waktu_selesai', '>=', now())
            ->orderBy('waktu_mulai', 'asc')
            ->get()
            ->filter(function ($agenda) {
                return in_array($agenda->status, ['Akan Datang', 'Sedang Berlangsung']);
            });

        // Ambil semua konten terbaru dan semua kategori
        $kontens = Konten::latest()->get();
        $kategoris = Kategori::all();
        $banners = Banner::all();
        return view('pages.home', compact('kontens', 'kategoris', 'banners', 'events'));
    }

    /**
     * Tampilkan konten berdasarkan kategori.
     *
     * @param int $id
     */
    public function kategori($id)
    {
        $kategori = Kategori::findOrFail($id);
        $kontens = $kategori->kontens()->latest()->get();
        $categories = Kategori::all();

        return view('pages.kategori', compact('kategori', 'kontens', 'categories'));
    }

    public function show($id)
    {
        $konten = Konten::with('kategoris')->findOrFail($id);
        return view('pages.detail', compact('konten'));
    }

    public function kategoryPage()
    {
        $kategoris = Kategori::all();
        $kontens = Konten::all();
        return view('pages.page_kategori', compact('kategoris', 'kontens'));
    }

    public function keanggotaan()
    {
        $user = User::with('identitas')->get();
        $strukturs = Struktur::with('user')->get();
        return view('pages.keanggotaan', compact('strukturs', 'user'));
    }
    public function tentang()
    {
        return view('pages.tentang_kami');
    }
}
