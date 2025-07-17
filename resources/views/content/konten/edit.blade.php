@extends('layouts.dashboard')

@section('content')
    <div class="section-content section-dashboard-home" data-aos="fade-up">
        <div class="container-fluid">
            <div class="dashboard-heading mb-4">
                <h2 class="dashboard-title">Edit Konten</h2>
                <p class="dashboard-subtitle">
                    Perbarui data konten yang sudah ada
                </p>
            </div>

            <div class="dashboard-content">
                <div class="row">
                    <div class="col-md-12">
                        <div class="card shadow-sm border-0">
                            <div class="card-body">

                                {{-- Tampilkan Error Validasi --}}
                                @if ($errors->any())
                                    <div class="alert alert-danger">
                                        <ul class="mb-0">
                                            @foreach ($errors->all() as $error)
                                                <li>{{ $error }}</li>
                                            @endforeach
                                        </ul>
                                    </div>
                                @endif

                                <form method="POST" action="{{ route('content.update', $konten->id) }}"
                                    enctype="multipart/form-data">
                                    @csrf
                                    @method('PUT')

                                    {{-- Pilih Kategori --}}
                                    <div class="mb-3">
                                        <label class="form-label">Kategori</label><br>
                                        <div class="d-flex flex-wrap gap-3">
                                            @foreach ($kategoris as $kategori)
                                                <div class="form-check me-3">
                                                    <input type="checkbox" class="form-check-input" name="kategori_id[]"
                                                        value="{{ $kategori->id }}" id="kategori_{{ $kategori->id }}"
                                                        {{ $konten->kategoris->contains($kategori->id) ? 'checked' : '' }}>
                                                    <label class="form-check-label" for="kategori_{{ $kategori->id }}">
                                                        {{ $kategori->nama_kategori }}
                                                    </label>
                                                </div>
                                            @endforeach
                                        </div>
                                    </div>

                                    {{-- Nama Konten --}}
                                    <div class="mb-3">
                                        <label>Nama Konten</label>
                                        <input type="text" name="nama_konten" class="form-control"
                                            value="{{ old('nama_konten', $konten->nama_konten) }}" required>
                                    </div>

                                    {{-- Tanggal Konten --}}
                                    <div class="mb-3">
                                        <label>Tanggal Konten</label>
                                        <input type="date" name="tanggal_konten" class="form-control"
                                            value="{{ old('tanggal_konten', $konten->tanggal_konten) }}" required>
                                    </div>

                                    {{-- Deskripsi --}}
                                    <div class="mb-3">
                                        <label>Deskripsi</label>
                                        <textarea name="deskripsi" id="editor" class="form-control" rows="6">{{ old('deskripsi', $konten->deskripsi) }}</textarea>
                                    </div>

                                    {{-- Gambar Konten --}}
                                    @foreach (['gambar1', 'gambar2', 'gambar3'] as $gambar)
                                        <div class="mb-3">
                                            <label>{{ ucfirst($gambar) }} (Opsional)</label>
                                            @if ($konten->$gambar)
                                                <div class="mb-2">
                                                    <img src="{{ asset('storage/' . $konten->$gambar) }}"
                                                        alt="{{ $gambar }}" width="200" class="img-thumbnail">
                                                </div>
                                            @endif
                                            <input type="file" name="{{ $gambar }}" class="form-control">
                                        </div>
                                    @endforeach

                                    {{-- Tombol --}}
                                    <div class="d-flex justify-content-between">
                                        <a href="{{ route('content.index') }}" class="btn btn-danger ms-2">Batal</a>
                                        <button type="submit" class="btn btn-primary">Perbarui</button>
                                    </div>
                                </form>

                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    {{-- CKEditor --}}
    <script src="https://cdn.ckeditor.com/ckeditor5/39.0.1/classic/ckeditor.js"></script>
    <script>
        ClassicEditor
            .create(document.querySelector('#editor'))
            .catch(error => {
                console.error(error);
            });
    </script>
@endsection
