<?php

namespace App\Http\Controllers;

use App\Models\Banner;
use App\Models\Kategori;
use App\Models\Konten;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ContentController extends Controller
{
    public function index()
    {
        $banners = Banner::latest()->get();
        $kontens = Konten::latest()->get();
        $kategoris = Kategori::all();
        return view('content.index', compact('kontens', 'banners', 'kategoris'));
    }

    // ================== KATEGORI =====================
    public function createCategory()
    {
        return view('content.kategori.create');
    }

    public function storeCategory(Request $request)
    {
        $request->validate([
            'nama_kategori' => 'required|string|max:255',
            'gambar_kategori' => 'required|image|mimes:jpg,jpeg,png,svg|max:2048',
        ]);

        $path = $request->file('gambar_kategori')->store('kategori', 'public');

        Kategori::create([
            'nama_kategori' => $request->nama_kategori,
            'gambar_kategori' => $path,
        ]);

        return redirect()->route('content.index')->with('success', 'Kategori berhasil ditambahkan.');
    }

    public function editCategory($id)
    {
        $kategori = Kategori::findOrFail($id);
        return view('content.kategori.edit', compact('kategori'));
    }

    public function updateCategory(Request $request, $id)
    {
        $request->validate([
            'nama_kategori' => 'required|string|max:255',
            'gambar_kategori' => 'nullable|image|mimes:jpg,jpeg,png,svg|max:2048',
        ]);

        $kategori = Kategori::findOrFail($id);
        $kategori->nama_kategori = $request->nama_kategori;

        if ($request->hasFile('gambar_kategori')) {
            // Hapus gambar lama
            if ($kategori->gambar_kategori && Storage::disk('public')->exists($kategori->gambar_kategori)) {
                Storage::disk('public')->delete($kategori->gambar_kategori);
            }

            $kategori->gambar_kategori = $request->file('gambar_kategori')->store('kategori', 'public');
        }

        $kategori->save();

        return redirect()->route('content.index')->with('success', 'Kategori berhasil diupdate.');
    }

    public function destroyCategory($id)
    {
        $kategori = Kategori::findOrFail($id);

        if ($kategori->gambar_kategori && Storage::disk('public')->exists($kategori->gambar_kategori)) {
            Storage::disk('public')->delete($kategori->gambar_kategori);
        }

        $kategori->delete();

        return back()->with('success', 'Kategori berhasil dihapus.');
    }

    // ================== KONTEN =====================
    public function create()
    {
        $kategoris = Kategori::all();
        return view('content.konten.create', compact('kategoris'));
    }

    public function contentStore(Request $request)
    {
        $request->validate([
            'kategori_id' => 'required|array',
            'kategori_id.*' => 'exists:kategoris,id',
            'nama_konten' => 'required|string|max:255',
            'tanggal_konten' => 'required|date',
            'deskripsi' => 'required|string',
            'gambar1' => 'required|image|mimes:jpg,jpeg,png|max:2048',
            'gambar2' => 'required|image|mimes:jpg,jpeg,png|max:2048',
            'gambar3' => 'required|image|mimes:jpg,jpeg,png|max:2048',
        ]);

        // Simpan konten
        $data = $request->only(['nama_konten', 'tanggal_konten', 'deskripsi']);

        // Simpan masing-masing gambar ke storage
        foreach (['gambar1', 'gambar2', 'gambar3'] as $field) {
            $data[$field] = $request->file($field)->store('konten', 'public');
        }

        $konten = Konten::create($data);

        // Simpan kategori ke pivot table
        $konten->kategoris()->attach($request->kategori_id);
        return redirect()->route('content.index')->with('success', 'Konten berhasil ditambahkan.');
    }

    public function contentShow($id)
    {
        $konten = Konten::with('kategoris')->findOrFail($id);
        return view('content.konten.show', compact('konten'));
    }

    public function edit($id)
    {
        $konten = Konten::findOrFail($id);
        $kategoris = Kategori::all();
        return view('content.konten.edit', compact('konten', 'kategoris'));
    }

    public function update(Request $request, $id)
    {
        $konten = Konten::findOrFail($id);

        $request->validate([
            'kategori_id' => 'required|exists:kategoris,id',
            'nama_konten' => 'required|string|max:255',
            'tanggal_konten' => 'required|date',
            'deskripsi' => 'required|string',
            'gambar1' => 'nullable|image|mimes:jpg,jpeg,png|max:5048',
            'gambar2' => 'nullable|image|mimes:jpg,jpeg,png|max:5048',
            'gambar3' => 'nullable|image|mimes:jpg,jpeg,png|max:5048',
        ]);

        $konten->fill($request->only(['kategori_id', 'nama_konten', 'tanggal_konten', 'deskripsi']));

        foreach (['gambar1', 'gambar2', 'gambar3'] as $gambarField) {
            if ($request->hasFile($gambarField)) {
                Storage::disk('public')->delete($konten->$gambarField);
                $konten->$gambarField = $request->file($gambarField)->store('konten', 'public');
            }
        }

        $konten->save();

        return redirect()->route('content.index')->with('success', 'Konten berhasil diperbarui.');
    }

    public function destroy($id)
    {
        $konten = Konten::findOrFail($id);

        foreach (['gambar1', 'gambar2', 'gambar3'] as $gambarField) {
            if ($konten->$gambarField && Storage::disk('public')->exists($konten->$gambarField)) {
                Storage::disk('public')->delete($konten->$gambarField);
            }
        }

        $konten->delete();

        return redirect()->route('content.index')->with('success', 'Konten berhasil dihapus.');
    }

    // ================== BANNER =====================

    public function bannerCreate()
    {
        return view('content.banner.create');
    }

    public function bannerStore(Request $request)
    {
        $request->validate([
            'gambar_banner' => 'required|image|mimes:jpg,jpeg,png,svg|max:5048',
        ]);

        $path = $request->file('gambar_banner')->store('banner', 'public');

        Banner::create([
            'gambar' => $path,
        ]);

        return redirect()->route('content.index')->with('success', 'Banner berhasil ditambahkan.');
    }

    public function bannerEdit($id)
    {
        $banner = Banner::findOrFail($id);
        return view('content.banner.edit', compact('banner'));
    }

    public function bannerUpdate(Request $request, $id)
    {
        $request->validate([
            'gambar_banner' => 'nullable|image|mimes:jpg,jpeg,png,svg|max:5048',
        ]);

        $banner = Banner::findOrFail($id);

        if ($request->hasFile('gambar_banner')) {
            // Hapus gambar lama jika ada
            if ($banner->gambar && Storage::disk('public')->exists($banner->gambar)) {
                Storage::disk('public')->delete($banner->gambar);
            }

            // Upload gambar baru
            $path = $request->file('gambar_banner')->store('banner', 'public');
            $banner->update(['gambar' => $path]);
        }

        return redirect()->route('content.index')->with('success', 'Banner berhasil diupdate.');
    }

    public function bannerDestroy($id)
    {
        $banner = Banner::findOrFail($id);

        if ($banner->gambar && Storage::disk('public')->exists($banner->gambar)) {
            Storage::disk('public')->delete($banner->gambar);
        }

        $banner->delete();

        return redirect()->route('content.index')->with('success', 'Banner berhasil dihapus.');
    }
}
