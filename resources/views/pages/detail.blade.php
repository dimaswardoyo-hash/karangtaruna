@extends('layouts.app')

@section('title', $konten->nama_konten)

@section('content')
    <style>
        /* Transition untuk animasi */
        .slide-fade-enter-active {
            transition: all 0.2s ease;
        }

        .slide-fade-leave-active {
            transition: all 0.1s ease-in;
        }

        .slide-fade-enter,
        .slide-fade-leave-to {
            transform: translateY(10px);
            opacity: 0.5;
        }

        /* Main Image styling */
        .main-image-wrapper {
            aspect-ratio: 4 / 3;
            width: 100%;
            border-radius: 0.5rem;
            overflow: hidden;
        }

        .main-image {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        /* Thumbnail */
        .thumbnail-image {
            width: 100%;
            aspect-ratio: 4 / 3;
            object-fit: cover;
            border-radius: 6px;
            border: 2px solid transparent;
            transition: 0.3s;
            cursor: pointer;
        }

        .thumbnail-image.active {
            border-color: #28a745;
        }

        @media (max-width: 768px) {
            .thumbnail-image {
                aspect-ratio: 4 / 3;
                max-width: 80px;
                margin-bottom: 10px;
            }
        }
    </style>
    <!-- Page Content -->
    <div class="page-content page-details">
        {{-- Breadcrumb --}}
        <section class="store-breadcrumbs" data-aos="fade-down" data-aos-delay="100">
            <div class="container">
                <div class="row">
                    <div class="col-12">
                        <nav>
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item">
                                    <a href="{{ route('kategori') }}">Konten</a>
                                </li>
                                <li class="breadcrumb-item active">Detail Konten</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>
        </section>

        {{-- Gallery --}}
        <section class="store-gallery" id="gallery">
            <div class="container">
                <div class="row">
                    {{-- Main Image --}}
                    <div class="col-lg-8 mb-3" data-aos="zoom-in">
                        <transition name="slide-fade" mode="out-in">
                            <div class="main-image-wrapper" :key="photos[activePhoto].id">
                                <img :src="photos[activePhoto].url" class="main-image w-100 rounded" alt="">
                            </div>
                        </transition>
                    </div>

                    {{-- Thumbnails --}}
                    <div class="col-lg-2">
                        <div class="row g-2">
                            <div class="col-3 col-lg-12 mb-3" v-for="(photo, index) in photos" :key="photo.id"
                                data-aos="zoom-in" data-aos-delay="100">
                                <a href="#" @click.prevent="changeActive(index)">
                                    <img :src="photo.url" class="thumbnail-image img-fluid rounded"
                                        :class="{ active: index === activePhoto }" alt="">
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        {{-- Konten Info --}}
        <div class="store-details-container" data-aos="fade-up">
            <section class="store-heading">
                <div class="container">
                    <div class="row">
                        <div class="col-lg-8 mt-4">
                            <h1>{{ $konten->nama_konten }}</h1>
                            <div class="owner text-muted">
                                Kategori:
                                @forelse($konten->kategoris as $kategori)
                                    <span class="badge bg-secondary">{{ $kategori->nama_kategori }}</span>
                                @empty
                                    <span class="text-danger">Belum ada kategori</span>
                                @endforelse
                            </div>

                            <div class="text-muted">Tanggal:
                                {{ \Carbon\Carbon::parse($konten->tanggal_konten)->translatedFormat('d F Y') }}
                            </div>
                        </div>
                        {{-- <div class="col-lg-2 mt-3" data-aos="zoom-in">
                            <a href="{{ route('content.edit', $konten->id) }}"
                                class="btn btn-warning px-4 text-white btn-block mb-3">
                                Edit Konten
                            </a>
                        </div> --}}
                    </div>
                </div>
            </section>

            {{-- Deskripsi --}}
            <section class="store-description">
                <div class="container">
                    <div class="row">
                        <div class="col-12 col-lg-8">
                            <h5 class="mb-3">Deskripsi Konten</h5>
                            <div>{!! $konten->deskripsi !!}</div>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    </div>

    {{-- Vue.js & AOS --}}
    <script src="https://cdn.jsdelivr.net/npm/vue@2.6.14"></script>
    <script src="https://cdn.jsdelivr.net/npm/aos@2.3.4/dist/aos.js"></script>
    <script>
        new Vue({
            el: "#gallery",
            mounted() {
                AOS.init();
            },
            data: {
                activePhoto: 0,
                photos: [
                    @foreach (['gambar1', 'gambar2', 'gambar3'] as $i => $img)
                        @if ($konten->$img)
                            {
                                id: {{ $i + 1 }},
                                url: "{{ asset('storage/' . $konten->$img) }}"
                            },
                        @endif
                    @endforeach
                ],
            },
            methods: {
                changeActive(index) {
                    this.activePhoto = index;
                }
            }
        });
    </script>
@endsection
