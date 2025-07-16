@extends('layouts.dashboard')

@section('content')
    <!-- Begin Page Content -->
    <div class="container-fluid">

        <!-- Heading -->
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h1 class="h3 text-gray-800 font-weight-bold">Daftar Perlengkapan</h1>
                <p class="text-muted mb-0">Berikut adalah daftar perlengkapan yang tersedia</p>
            </div>
            <div class="d-flex flex-wrap justify-content-end" style="gap: 0.5rem;">
                @if (Auth::user()->role === 'admin')
                    <a href="{{ route('perlengkapan.create') }}" class="btn btn-primary btn-icon-split">
                        <span class="icon text-white-50">
                            <i class="fas fa-plus"></i>
                        </span>
                        <span class="text"> Tambah Barang</span>
                    </a>

                    <a href="{{ route('peminjaman.tanggapan') }}" class="btn btn-success btn-icon-split">
                        <span class="icon text-white-50">
                            <i class="fas fa-check"></i>
                        </span>
                        <span class="text"> Pengajuan Peminjaman</span>
                    </a>
                @elseif (Auth::user()->role === 'anggota')
                    <a href="{{ route('peminjaman.index') }}" class="btn btn-info btn-icon-split">
                        <span class="icon text-white-50">
                            <i class="fas fa-paper-plane"></i>
                        </span>
                        <span class="text"> Ajukan Peminjaman</span>
                    </a>
                @endif
            </div>
        </div>

        <!-- Table Card -->
        <div class="card shadow-sm border-0">
            <div class="card-body">
                <div class="table-responsive">
                    <table id="dataTable" class="table table-bordered table-hover">
                        <thead class="thead-light">
                            <tr>
                                <th>Nama</th>
                                <th>Stok</th>
                                <th style="width: 180px;">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($perlengkapans as $perlengkapan)
                                <tr>
                                    <td>{{ $perlengkapan->nama }}</td>
                                    <td>{{ $perlengkapan->stok }}</td>
                                    <td>
                                        <a href="{{ auth()->user()->role === 'admin' ? route('perlengkapan.admin.show', $perlengkapan->id) : route('perlengkapan.anggota.show', $perlengkapan->id) }}"
                                            class="btn btn-sm btn-info">
                                            <i class="fas fa-info-circle"></i>
                                        </a>
                                        @if (Auth::user()->role === 'admin')
                                            <a href="{{ route('perlengkapan.edit', $perlengkapan->id) }}"
                                                class="btn btn-sm btn-warning text-white">
                                                <i class="fas fa-edit"></i>
                                            </a>
                                            <form action="{{ route('perlengkapan.destroy', $perlengkapan->id) }}"
                                                method="POST" class="d-inline"
                                                onsubmit="return confirm('Yakin ingin menghapus barang ini?')">
                                                @csrf
                                                @method('DELETE')
                                                <button class="btn btn-sm btn-danger">
                                                    <i class="fas fa-trash-alt"></i>
                                                </button>
                                            </form>
                                        @endif
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="3" class="text-center text-muted">Tidak ada perlengkapan tersedia.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

    </div>
    <!-- /.container-fluid -->
@endsection
