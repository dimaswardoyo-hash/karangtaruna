@extends('layouts.dashboard')

@section('content')
    <div class="section-content section-dashboard-home">
        <div class="container-fluid">
            <div class="dashboard-heading">
                <h2>Detail Agenda</h2>
            </div>
            <div class="dashboard-content">
                <div class="card mb-2 mt-4">
                    <div class="card-body">

                        {{-- Informasi Agenda --}}
                        <table class="table table-bordered table-striped mb-4">
                            <tr>
                                <td style="width: 180px;"><strong>Nama Agenda</strong></td>
                                <td>{{ $agenda->nama_agenda }}</td>
                            </tr>
                            <tr>
                                <td><strong>Kategori</strong></td>
                                <td>{{ ucfirst($agenda->kategori) }}</td>
                            </tr>
                            <tr>
                                <td><strong>Lokasi</strong></td>
                                <td>{{ $agenda->lokasi }}</td>
                            </tr>
                            <tr>
                                <td><strong>Waktu</strong></td>
                                <td>
                                    {{ \Carbon\Carbon::parse($agenda->waktu_mulai)->format('d-m-Y H:i') }}
                                    -
                                    {{ \Carbon\Carbon::parse($agenda->waktu_selesai)->format('d-m-Y H:i') }}
                                </td>
                            </tr>
                            <tr>
                                <td><strong>Deskripsi</strong></td>
                                <td>{{ $agenda->deskripsi }}</td>
                            </tr>
                            <tr>
                                <td><strong>Foto</strong></td>
                                <td>
                                    @if ($agenda->foto)
                                        <img src="{{ asset('storage/' . $agenda->foto) }}" alt="Foto Agenda"
                                            style="max-width: 300px;" class="img-fluid mt-2">
                                    @else
                                        <span class="text-muted">Tidak ada foto.</span>
                                    @endif
                                </td>
                            </tr>
                        </table>

                        @php
                            $user = Auth::user();
                            $now = now();
                            $start = $agenda->waktu_mulai;
                            $end = $agenda->waktu_selesai;
                        @endphp

                        {{-- Presensi hanya untuk agenda kategori "rapat" --}}
                        @if (strtolower($agenda->kategori) === 'rapat')

                            {{-- Presensi saat acara berlangsung --}}
                            @if ($now->between($start, $end))
                                <div class="alert alert-success">
                                    <strong>Acara sedang berlangsung.</strong>
                                </div>

                                @if ($user->role === 'admin')
                                    @if ($agenda->presensi_open)
                                        <form action="{{ route('presensi.close', $agenda->id) }}" method="POST"
                                            class="mb-3">
                                            @csrf
                                            <button type="submit" class="btn btn-danger">Tutup Presensi</button>
                                        </form>
                                    @else
                                        <form action="{{ route('presensi.open', $agenda->id) }}" method="POST">
                                            @csrf
                                            <button type="submit" class="btn btn-success">Buka Presensi</button>
                                        </form>
                                    @endif

                                    {{-- Token dan daftar presensi --}}
                                    @if ($agenda->presensi_open)
                                        <div class="mt-3">
                                            <p>
                                                <strong>Kode Presensi:</strong>
                                                {{ substr($agenda->generateToken(), 0, 6) }}<br>
                                                <small>Refresh halaman untuk kode terbaru (otomatis berganti setiap 1
                                                    menit)</small>
                                            </p>
                                        </div>

                                        @if ($agenda->presensis->count())
                                            <div class="mt-4">
                                                <h5>Daftar Hadir:</h5>
                                                <table class="table table-striped table-bordered">
                                                    <thead>
                                                        <tr>
                                                            <th>No</th>
                                                            <th>Nama</th>
                                                            <th>Waktu Presensi</th>
                                                            <th>Token</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        @foreach ($agenda->presensis as $i => $presensi)
                                                            <tr>
                                                                <td>{{ $i + 1 }}</td>
                                                                <td>{{ $presensi->user->name ?? 'Tidak diketahui' }}</td>
                                                                <td>{{ \Carbon\Carbon::parse($presensi->waktu_presensi)->format('d-m-Y H:i:s') }}
                                                                </td>
                                                                <td>{{ $presensi->token_yang_dipakai }}</td>
                                                            </tr>
                                                        @endforeach
                                                    </tbody>
                                                </table>
                                            </div>
                                        @else
                                            <p class="text-muted">Belum ada yang hadir.</p>
                                        @endif
                                    @endif
                                @elseif ($user->role === 'anggota')
                                    @php
                                        $alreadyPresensi = $agenda->presensis->where('user_id', $user->id)->count() > 0;
                                    @endphp

                                    @if ($agenda->presensi_open)
                                        @if ($alreadyPresensi)
                                            <p class="text-success mt-2"><strong>Anda telah melakukan presensi.</strong></p>
                                        @else
                                            {{-- Form presensi langsung --}}
                                            <form action="{{ route('presensi.store', $agenda->id) }}" method="POST"
                                                class="mt-3">
                                                @csrf
                                                <div class="form-group">
                                                    <label for="token">Masukkan Kode Presensi:</label>
                                                    <input type="text" name="token" id="token" class="form-control"
                                                        required>
                                                </div>
                                                <button type="submit" class="btn btn-primary mt-2">Absen Sekarang</button>
                                            </form>
                                        @endif
                                    @else
                                        <p class="text-muted">Presensi belum dibuka oleh admin.</p>
                                    @endif
                                @endif

                                {{-- Presensi ditutup jika acara selesai --}}
                            @elseif ($now->gt($end))
                                <div class="alert alert-secondary">
                                    <strong>Acara telah selesai.</strong>
                                </div>
                                <a href="{{ route('agenda.presensi.index', $agenda->id) }}" class="btn btn-primary mt-2">
                                    Lihat Daftar Hadir
                                </a>

                                {{-- Acara belum dimulai --}}
                            @elseif ($now->lt($start))
                                <div class="alert alert-info">
                                    <strong>Acara belum dimulai.</strong>
                                </div>
                            @endif

                            {{-- Notulen --}}
                            @php $notulen = $agenda->notulen; @endphp
                            <div class="mt-4">
                                @if ($user->role === 'admin')
                                    @if ($notulen)
                                        <a href="{{ route('notulen.edit', $notulen->id) }}" class="btn btn-warning">
                                            Edit Notulen
                                        </a>
                                    @else
                                        <a href="{{ route('notulen.create', ['agenda_id' => $agenda->id]) }}"
                                            class="btn btn-warning">
                                            Tambah Notulen
                                        </a>
                                    @endif
                                @else
                                    @if ($notulen)
                                        <a href="{{ route('notulen.show', $notulen->id) }}" class="btn btn-info">
                                            Lihat Notulen
                                        </a>
                                    @endif
                                @endif
                            </div>

                        @endif

                        <a href="{{ auth()->user()->role === 'admin' ? route('agenda.admin.index') : route('agenda.anggota.index') }}"
                            class="btn btn-danger mt-4">Kembali</a>
                    </div>
                </div>
            </div>
        </div>
    </div>

    {{-- Modal Feedback Presensi --}}
    @if (session('success') || session('error'))
        <script>
            window.addEventListener('DOMContentLoaded', function() {
                $('#feedbackModal').modal('show');
            });
        </script>

        <div class="modal fade" id="feedbackModal" tabindex="-1" role="dialog" aria-labelledby="feedbackModalLabel"
            aria-hidden="true">
            <div class="modal-dialog" role="document">
                <div class="modal-content">
                    <div class="modal-header {{ session('success') ? 'bg-success' : 'bg-danger' }}">
                        <h5 class="modal-title text-white" id="feedbackModalLabel">
                            {{ session('success') ? 'Presensi Berhasil' : 'Presensi Gagal' }}
                        </h5>
                        <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body">
                        {{ session('success') ?? session('error') }}
                    </div>
                    <div class="modal-footer">
                        <button class="btn btn-light" data-dismiss="modal">Tutup</button>
                    </div>
                </div>
            </div>
        </div>
    @endif
@endsection
