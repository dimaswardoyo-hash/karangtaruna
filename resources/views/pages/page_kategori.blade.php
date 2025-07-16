@extends('layouts.app')

@section('title', 'Semua Kategori')

@section('content')
    <!-- Page Content -->
    <div class="page-content page-home">
        <!-- Semua Kategori -->
        <section class="store-trend-categories">
            <div class="container">
                <div class="row">
                    <div class="col-12" data-aos="fade-up">
                        <h5>All Categories</h5>
                    </div>
                </div>
                <div class="row d-flex justify-content-center">
                    @forelse ($kategoris as $key => $kategori)
                        <div class="col-6 col-md-3 col-lg-2" data-aos="fade-up" data-aos-delay="{{ ($key + 1) * 100 }}">
                            <a href="{{ route('kategori.show', $kategori->id) }}" class="component-categories d-block">
                                <div class="categories-image">
                                    <img src="{{ asset('storage/' . $kategori->gambar_kategori) }}"
                                        alt="{{ $kategori->nama_kategori }}" class="w-100">
                                </div>
                                <p class="categories-text">
                                    {{ $kategori->nama_kategori }}
                                </p>
                            </a>
                        </div>
                    @empty
                        <div class="col-12 text-center py-4" data-aos="fade-up">
                            <p class="text-muted">Belum ada kategori tersedia.</p>
                        </div>
                    @endforelse
                </div>
            </div>
        </section>

        <!-- Semua Konten -->
        <section class="store-new-products mt-4">
            <div class="container">
                <div class="row">
                    <div class="col-12" data-aos="fade-up">
                        <h5>All Products</h5>
                    </div>
                </div>
                <div class="row">
                    @forelse ($kontens as $key => $konten)
                        <div class="col-6 col-md-4 col-lg-3" data-aos="fade-up" data-aos-delay="{{ ($key + 1) * 100 }}">
                            <a href="{{ route('konten.show', $konten->id) }}" class="component-products d-block">
                                <div class="products-thumbnail">
                                    <div class="products-image"
                                        style="background-image: url('{{ asset('storage/' . $konten->gambar1) }}');
                                            background-size: cover;
                                            background-position: center;
                                            height: 200px;
                                            border-radius: 8px;">
                                    </div>
                                </div>
                                <div class="products-text">
                                    {{ Str::limit($konten->nama_konten, 60) }}
                                </div>
                                <div class="products-price">
                                    {{ \Carbon\Carbon::parse($konten->tanggal_konten)->format('d F Y') }}
                                </div>
                            </a>
                        </div>
                    @empty
                        <div class="col-12 text-center py-5" data-aos="fade-up" data-aos-delay="100">
                            <p class="text-muted">Belum ada konten yang tersedia.</p>
                        </div>
                    @endforelse
                </div>
            </div>
        </section>
    </div>
@endsection
