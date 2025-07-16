@extends('layouts.dashboard')

@section('content')
    <div class="container-fluid">
        <!-- Page Heading -->
        <h1 class="h3 mb-2 text-gray-800">Daftar Peminjam</h1>
        <p class="mb-4 text-muted">Berikut adalah daftar peminjaman perlengkapan yang diajukan</p>

        <!-- DataTables Example -->
        <div class="card shadow mb-4">
            <div class="card-header py-3 d-flex justify-content-between">
                <h6 class="m-0 font-weight-bold">Tabel Peminjaman</h6>
                <a href="{{ route('perlengkapan.admin.index') }}" class="btn btn-sm btn-danger">Kembali</a>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-bordered text-center" id="dataTable" width="100%" cellspacing="0">
                        <thead class="table-secondary">
                            <tr>
                                <th>Barang</th>
                                <th>Jumlah</th>
                                <th>Peminjam</th>
                                <th>Tanggal Pinjam</th>
                                <th>Tanggal Kembali</th>
                                <th>Status</th>
                                <th>Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse ($perlengkapans as $barang)
                                @forelse ($barang->users as $user)
                                    <tr>
                                        <td>{{ $barang->nama }}</td>
                                        <td>{{ $user->pivot->jumlah }}</td>
                                        <td>{{ $user->name ?? 'Tidak diketahui' }}</td>
                                        <td>{{ \Carbon\Carbon::parse($user->pivot->tanggal_pinjam)->format('d M Y') }}</td>
                                        <td>{{ \Carbon\Carbon::parse($user->pivot->tanggal_kembali)->format('d M Y') }}</td>
                                        <td>
                                            @php
                                                $status = $user->pivot->status;
                                                $badgeClass = match ($status) {
                                                    'berlangsung' => 'badge-warning text-dark',
                                                    'selesai' => 'badge-success',
                                                    'ditolak' => 'badge-danger',
                                                    default => 'badge-secondary',
                                                };
                                            @endphp
                                            <span class="badge {{ $badgeClass }}">{{ ucfirst($status) }}</span>
                                        </td>
                                        <td>
                                            <form action="{{ route('peminjaman.tanggapi', [$user->id, $barang->id]) }}"
                                                method="POST">
                                                @csrf
                                                <select name="status" class="form-control form-control-sm mb-2">
                                                    <option disabled selected>Pilih Status</option>
                                                    <option value="berlangsung" @selected($status === 'berlangsung')>Setujui
                                                    </option>
                                                    <option value="ditolak" @selected($status === 'ditolak')>Tolak</option>
                                                    <option value="selesai" @selected($status === 'selesai')>Selesai</option>
                                                </select>
                                                <textarea name="tanggapan_admin" class="form-control form-control-sm mb-2" rows="1" placeholder="Tanggapan...">{{ old('tanggapan_admin', $user->pivot->tanggapan_admin) }}</textarea>
                                                <button type="submit"
                                                    class="btn btn-sm btn-primary btn-block">Update</button>
                                            </form>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="7" class="text-muted">Belum ada pengajuan peminjaman untuk barang
                                            <strong>{{ $barang->nama }}</strong>.
                                        </td>
                                    </tr>
                                @endforelse
                            @empty
                                <tr>
                                    <td colspan="7" class="text-center text-muted">Tidak ada data peminjaman.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
    <script>
        $(document).ready(function() {
            $('#dataTable').DataTable({
                language: {
                    "search": "Cari:",
                    "lengthMenu": "Tampilkan _MENU_ entri",
                    "info": "Menampilkan _START_ sampai _END_ dari _TOTAL_ entri",
                    "paginate": {
                        "first": "Awal",
                        "last": "Akhir",
                        "next": "→",
                        "previous": "←"
                    },
                    "zeroRecords": "Data tidak ditemukan"
                }
            });
        });
    </script>
@endsection
