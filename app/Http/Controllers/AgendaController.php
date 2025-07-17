<?php

namespace App\Http\Controllers;

use App\Models\Agenda;
use App\Models\Notulen;
use App\Models\Presensi;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AgendaController extends Controller
{
    // ========================= Agenda Method =========================
    public function agendaIndex()
    {
        $agenda = Agenda::all();
        return view('agenda.index', compact('agenda'));
    }

    public function agendaShow($id)
    {
        $agenda = Agenda::findOrFail($id);
        return view('agenda.show', compact('agenda'));
    }

    public function agendaCreate()
    {
        return view('agenda.create');
    }

    public function agendaStore(Request $request)
    {
        $request->validate([
            'nama_agenda' => 'required|string',
            'kategori' => 'required|in:kegiatan,rapat',
            'deskripsi' => 'required',
            'waktu_mulai' => 'required|date',
            'waktu_selesai' => 'required|date|after:waktu_mulai',
            'lokasi' => 'required|string',
        ]);

        if ($request->kategori === 'kegiatan') {
            $request->validate([
                'foto' => 'required|image|mimes:jpg,jpeg,png,webp|max:5000',
            ]);
        } else {
            $request->validate([
                'foto' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:5000',
            ]);
        }

        $data = $request->only(['nama_agenda', 'kategori', 'deskripsi', 'waktu_mulai', 'waktu_selesai', 'lokasi']);

        if ($request->hasFile('foto')) {
            $data['foto'] = $request->file('foto')->store('foto_agenda', 'public');
        }

        Agenda::create($data);

        return redirect()->route('agenda.admin.index')->with('success', 'Agenda berhasil dibuat');
    }

    public function agendaDestroy($id)
    {
        $agenda = Agenda::findOrFail($id);

        // Hapus semua presensi terkait
        $agenda->presensis()->delete();

        // Hapus notulen jika ada
        if ($agenda->notulen) {
            $agenda->notulen()->delete();
        }

        // Hapus file foto jika ada dan file-nya masih ada di storage
        if ($agenda->foto && file_exists(storage_path('app/public/' . $agenda->foto))) {
            unlink(storage_path('app/public/' . $agenda->foto));
        }

        // Hapus agendanya
        $agenda->delete();

        return redirect()->route('agenda.admin.index')->with('success', 'Agenda dan seluruh data terkait berhasil dihapus.');
    }

    // ========================= Presensi Method =========================
    public function presensiOpen($id)
    {
        $agenda = Agenda::findOrFail($id);

        if (now()->lt($agenda->waktu_mulai) || now()->gt($agenda->waktu_selesai)) {
            return redirect()->back()->with('error', 'Waktu presensi belum tersedia.');
        }

        $agenda->presensi_open = true;
        $agenda->save();

        Presensi::updateOrCreate(
            [
                'agenda_id' => $agenda->id,
                'user_id' => Auth::id(),
            ],
            [
                'waktu_presensi' => now(),
                'token_yang_dipakai' => substr(str()->random(6), 0, 6),
            ],
        );

        return redirect()->route('agenda.admin.show', $agenda->id)->with('success', 'Presensi dibuka.');
    }
    public function presensiClose($id)
    {
        $agenda = Agenda::findOrFail($id);

        $agenda->presensi_open = false;
        $agenda->save();

        return redirect()->route('agenda.admin.show', $agenda->id)->with('success', 'Presensi telah ditutup.');
    }

    public function presensiStore(Request $request, $id)
    {
        $agenda = Agenda::findOrFail($id);

        if (now()->lt($agenda->waktu_mulai) || now()->gt($agenda->waktu_selesai) || !$agenda->presensi_open) {
            return redirect()->back()->with('error', 'Presensi tidak tersedia saat ini.');
        }

        $request->validate([
            'token' => 'required|string',
        ]);

        $validToken = substr($agenda->generateToken(), 0, 6);

        if ($request->token !== $validToken) {
            return redirect()->back()->with('error', 'Token tidak valid atau sudah kedaluwarsa.');
        }

        Presensi::updateOrCreate(
            [
                'agenda_id' => $agenda->id,
                'user_id' => Auth::id(),
            ],
            [
                'waktu_presensi' => now(),
                'token_yang_dipakai' => $request->token,
            ],
        );

        return redirect()->back()->with('success', 'Presensi berhasil dilakukan.');
    }

    public function presensiIndex($id)
    {
        $agenda = Agenda::findOrFail($id);
        $presensi = $agenda->presensis;

        return view('agenda.presensi.index', compact('agenda', 'presensi'));
    }

    // ========================= Notulen Method =========================
    public function notulenCreate(Request $request)
    {
        $agenda_id = $request->agenda_id;
        return view('agenda.notulen.create', compact('agenda_id'));
    }

    public function notulenStore(Request $request)
    {
        $request->validate([
            'agenda_id' => 'required|exists:agendas,id',
            'pembicara' => 'required|string|max:255',
            'poin_pembahasan' => 'required|string',
            'notulen' => 'required|string',
        ]);

        Notulen::create([
            'agenda_id' => $request->agenda_id,
            'pembicara' => $request->pembicara,
            'poin_pembahasan' => $request->poin_pembahasan,
            'notulen' => $request->notulen,
        ]);

        return redirect()->route('agenda.admin.show', $request->agenda_id)->with('success', 'Notulen berhasil disimpan.');
    }

    public function notulenEdit(Notulen $notulen)
    {
        return view('agenda.notulen.edit', compact('notulen'));
    }

    public function notulenUpdate(Request $request, Notulen $notulen)
    {
        $request->validate([
            'pembicara' => 'required|string|max:255',
            'notulen' => 'required|string',
            'poin_pembahasan' => 'nullable|string',
        ]);

        $notulen->update([
            'pembicara' => $request->pembicara,
            'notulen' => $request->notulen,
            'poin_pembahasan' => $request->poin_pembahasan,
        ]);

        return redirect()->route('agenda.admin.show', $notulen->agenda_id)->with('success', 'Notulen berhasil diperbarui.');
    }

    public function notulenShow($id)
    {
        $notulen = Notulen::with('agenda')->findOrFail($id);
        return view('agenda.notulen.show', compact('notulen'));
    }
}
