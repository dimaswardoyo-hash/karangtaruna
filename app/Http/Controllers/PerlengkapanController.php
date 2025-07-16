<?php

namespace App\Http\Controllers;

use App\Models\Peminjaman;
use App\Models\Perlengkapan;
use App\Models\User;
use Illuminate\Http\Request;

class PerlengkapanController extends Controller
{
    // ========================= Perlengkapan Method =========================
    public function perlengkapanIndex()
    {
        $perlengkapans = Perlengkapan::all();
        return view('perlengkapan.index', compact('perlengkapans'));
    }

    // Detail barang
    public function perlengkapanShow(Perlengkapan $perlengkapan)
    {
        return view('perlengkapan.show', compact('perlengkapan'));
    }

    // Admin - form tambah barang
    public function perlengkapanCreate()
    {
        return view('perlengkapan.create');
    }

    public function perlengkapanStore(Request $request)
    {
        $request->validate([
            'nama' => 'required|string',
            'deskripsi' => 'nullable|string',
            'stok' => 'required|integer|min:1',
        ]);

        Perlengkapan::create([
            'nama' => $request->nama,
            'deskripsi' => $request->deskripsi,
            'stok' => $request->stok,
            'stok_awal' => $request->stok, // otomatis isi stok_awal
        ]);

        return redirect()->route('perlengkapan.admin.index')->with('success', 'Perlengkapan berhasil ditambahkan.');
    }

    // Admin - edit barang
    public function perlengkapanEdit(Perlengkapan $perlengkapan)
    {
        return view('perlengkapan.edit', compact('perlengkapan'));
    }

    public function perlengkapanUpdate(Request $request, Perlengkapan $perlengkapan)
    {
        $request->validate([
            'nama' => 'required',
            'stok' => 'required|integer|min:0',
        ]);

        $perlengkapan->update($request->all());

        return redirect()->route('perlengkapan.admin.index')->with('success', 'Barang diperbarui');
    }

    public function perlengkapanDestroy(Perlengkapan $perlengkapan)
    {
        $perlengkapan->delete();
        return redirect()->route('perlengkapan.admin.index')->with('success', 'Barang dihapus');
    }

    // ========================= Peminjaman Method =========================
    public function peminjamanIndex()
    {
        $perlengkapans = Perlengkapan::with([
            'users' => function ($q) {
                $q->wherePivot('status', 'berlangsung');
            },
        ])->get();

        foreach ($perlengkapans as $item) {
            $item->status = $item->users->count() > 0 ? 'Dipinjam' : 'Tersedia';
        }

        return view('perlengkapan.pinjam.index', compact('perlengkapans'));
    }

    // FORM CREATE
    public function peminjamanCreate($id)
    {
        $perlengkapan = Perlengkapan::findOrFail($id);
        return view('perlengkapan.pinjam.create', compact('perlengkapan'));
    }

    // STORE
    public function peminjamanStore(Request $request)
    {
        $request->validate([
            'perlengkapan_id' => 'required|exists:perlengkapans,id',
            'jumlah' => 'required|integer|min:1',
            'tanggal_pinjam' => 'required|date',
            'tanggal_kembali' => 'required|date|after_or_equal:tanggal_pinjam',
        ]);

        $perlengkapan = Perlengkapan::findOrFail($request->perlengkapan_id);

        if ($perlengkapan->stok < $request->jumlah) {
            return back()->withErrors(['jumlah' => 'Jumlah melebihi stok tersedia.']);
        }

        auth()
            ->user()
            ->perlengkapans()
            ->attach($request->perlengkapan_id, [
                'jumlah' => $request->jumlah,
                'tanggal_pinjam' => $request->tanggal_pinjam,
                'tanggal_kembali' => $request->tanggal_kembali,
                'status' => 'menunggu',
                'tanggapan_admin' => null,
            ]);

        return redirect()->route('peminjaman.index')->with('success', 'Pengajuan berhasil dikirim.');
    }

    // LIHAT SEMUA PENGAJUAN
    public function daftarPengajuan()
    {
        $perlengkapans = Perlengkapan::with(['users'])->get();
        return view('perlengkapan.pinjam.tanggapan', compact('perlengkapans'));
    }

    // TANGGAPI (ubah status)
    public function tanggapi(Request $request, $user_id, $perlengkapan_id)
    {
        $request->validate([
            'status' => 'required|in:berlangsung,ditolak,selesai',
        ]);

        $user = User::findOrFail($user_id);
        $perlengkapan = Perlengkapan::findOrFail($perlengkapan_id);
        $pivot = $user->perlengkapans()->where('perlengkapan_id', $perlengkapan_id)->first()->pivot;

        if (!in_array($pivot->status, ['menunggu', 'berlangsung'])) {
            return back()->with('error', 'Peminjaman sudah ditanggapi.');
        }

        // Kurangi atau kembalikan stok
        if ($request->status == 'berlangsung') {
            if ($perlengkapan->stok < $pivot->jumlah) {
                return back()->with('error', 'Stok tidak mencukupi.');
            }
            $perlengkapan->stok -= $pivot->jumlah;
        }

        if ($request->status == 'selesai' && $pivot->status == 'berlangsung') {
            $perlengkapan->stok += $pivot->jumlah;
        }

        $perlengkapan->save();

        $user->perlengkapans()->updateExistingPivot($perlengkapan_id, [
            'status' => $request->status,
            'tanggapan_admin' => $request->input('tanggapan_admin', null),
        ]);

        return redirect()->route('peminjaman.tanggapan')->with('success', 'Tanggapan berhasil dikirim.');
    }

    // AUTO CEK & KEMBALIKAN
    public function cekDanKembalikan()
    {
        $perlengkapans = Perlengkapan::with(['users'])->get();

        foreach ($perlengkapans as $barang) {
            foreach ($barang->users as $user) {
                $pivot = $user->pivot;
                if ($pivot->status === 'berlangsung' && now()->gt($pivot->tanggal_kembali)) {
                    $barang->stok += $pivot->jumlah;
                    $barang->save();

                    $user->perlengkapans()->updateExistingPivot($barang->id, [
                        'status' => 'selesai',
                    ]);
                }
            }
        }

        return redirect()->back()->with('success', 'Peminjaman yang lewat waktu otomatis dikembalikan.');
    }
}
