<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>Dashboard - Klaten Asyik</title>

    <!-- Font Awesome -->
    <link href="{{ asset('admin/vendor/fontawesome-free/css/all.min.css') }}" rel="stylesheet">
    <!-- Google Fonts - Nunito -->
    <link href="https://fonts.googleapis.com/css?family=Nunito:200,300,400,600,700,800,900" rel="stylesheet">
    <!-- SB Admin 2 CSS -->
    <link href="{{ asset('admin/css/sb-admin-2.min.css') }}" rel="stylesheet">
    <link href="{{ asset('admin/vendor/datatables/dataTables.bootstrap4.min.css') }}" rel="stylesheet">
</head>

<body id="page-top">
    <div id="wrapper">

        <!-- Sidebar -->
        <ul class="navbar-nav sidebar sidebar-light accordion" id="accordionSidebar">

            <!-- Logo -->
            <a class="sidebar-brand d-flex align-items-center justify-content-center" href="{{ url('/') }}">
                <div class="sidebar-brand-icon">
                    <img src="{{ asset('admin/img/logo.png') }}" class="w-100" alt="Logo Karang Taruna">
                </div>
                <div class="sidebar-brand-text mx-3">Karang Taruna</div>
            </a>

            <hr class="sidebar-divider my-0">

            {{-- === COMMON (Admin & Anggota) === --}}
            <li class="nav-item {{ request()->is('dashboard') ? 'active' : '' }}">
                <a href="{{ url('/dashboard') }}" class="nav-link">
                    <i class="fas fa-tachometer-alt"></i>
                    <span>Dashboard</span>
                </a>
            </li>

            <li class="nav-item {{ request()->is('agenda*') ? 'active' : '' }}">
                <a class="nav-link"
                    href="{{ auth()->user()->role === 'admin' ? route('agenda.admin.index') : route('agenda.anggota.index') }}">
                    <i class="fas fa-calendar-alt"></i>
                    <span>Agenda</span>
                </a>
            </li>

            <li class="nav-item {{ request()->is('perlengkapan*') ? 'active' : '' }}">
                <a class="nav-link"
                    href="{{ auth()->user()->role === 'admin' ? route('perlengkapan.admin.index') : route('perlengkapan.anggota.index') }}">
                    <i class="fas fa-boxes"></i>
                    <span>Perlengkapan</span>
                </a>
            </li>

            <li class="nav-item {{ request()->is('struktur*') ? 'active' : '' }}">
                <a class="nav-link" href="{{ route('struktur.index') }}">
                    <i class="fas fa-sitemap"></i>
                    <span>Struktur Organisasi</span>
                </a>
            </li>

            <li class="nav-item {{ request()->is('finance*') ? 'active' : '' }}">
                <a class="nav-link"
                    href="{{ auth()->user()->role === 'admin' ? route('finance.admin.index') : route('finance.anggota.index') }}">
                    <i class="fas fa-wallet"></i>
                    <span>Keuangan</span>
                </a>
            </li>

            <li class="nav-item {{ request()->is('ai-assistant*') ? 'active' : '' }}">
                <a class="nav-link" href="{{ route('ai.index') }}">
                    <i class="fas fa-robot"></i>
                    <span>AI Assistant</span>
                </a>
            </li>

            {{-- === ADMIN ONLY === --}}
            @if (auth()->check() && auth()->user()->role === 'admin')
                <li class="nav-item {{ request()->is('manageUsers*') ? 'active' : '' }}">
                    <a class="nav-link" href="{{ route('manageUsers.index') }}">
                        <i class="fas fa-users"></i>
                        <span>Kelola Anggota</span>
                    </a>
                </li>

                <li class="nav-item {{ request()->is('content*') ? 'active' : '' }}">
                    <a class="nav-link" href="{{ route('content.index') }}">
                        <i class="fas fa-edit"></i>
                        <span>Edit Konten</span>
                    </a>
                </li>

                <li class="nav-item {{ request()->is('broadcast*') ? 'active' : '' }}">
                    <a class="nav-link" href="{{ route('broadcast.index') }}">
                        <i class="fab fa-whatsapp"></i>
                        <span>Broadcast WA</span>
                    </a>
                </li>

                <li class="nav-item {{ request()->is('undangan*') ? 'active' : '' }}">
                    <a class="nav-link" href="{{ route('undangan.index') }}">
                        <i class="fas fa-envelope"></i>
                        <span>Undangan</span>
                    </a>
                </li>
            @endif

            <hr class="sidebar-divider d-none d-md-block">
            <div class="text-center d-none d-md-inline">
                <button class="rounded-circle border-0" id="sidebarToggle"></button>
            </div>
        </ul>
        <!-- End Sidebar -->

        <!-- Content Wrapper -->
        <div id="content-wrapper" class="d-flex flex-column">
            <div id="content">

                <!-- Topbar -->
                <nav class="navbar navbar-expand navbar-light bg-white topbar mb-4 static-top shadow">
                    <button id="sidebarToggleTop" class="btn btn-link d-md-none rounded-circle mr-3">
                        <i class="fa fa-bars"></i>
                    </button>

                    <!-- Topbar Navbar -->
                    <ul class="navbar-nav ml-auto">
                        @auth
                            <li class="nav-item dropdown no-arrow">
                                <a class="nav-link dropdown-toggle" href="#" id="userDropdown" role="button"
                                    data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                                    <span class="mr-2 d-none d-lg-inline text-gray-600">{{ auth()->user()->name }}</span>
                                    <img class="img-profile rounded-circle" src="{{ asset('admin/img/profile.gif') }}"
                                        alt="Profile">
                                </a>
                                <div class="dropdown-menu dropdown-menu-right shadow animated--grow-in"
                                    aria-labelledby="userDropdown">
                                    <a class="dropdown-item"
                                        href="{{ auth()->user()->role === 'admin' ? route('profile.index') : route('anggota.profile.index') }}">
                                        <i class="fas fa-user fa-sm fa-fw mr-2 text-gray-400"></i>
                                        Profile
                                    </a>

                                    <div class="dropdown-divider"></div>
                                    <a class="dropdown-item" href="#" data-toggle="modal" data-target="#logoutModal">
                                        <i class="fas fa-sign-out-alt fa-sm fa-fw mr-2 text-gray-400"></i>
                                        Logout
                                    </a>
                                </div>
                            </li>
                        @endauth
                    </ul>
                </nav>
                <!-- End of Topbar -->

                {{-- Halaman konten --}}
                <div class="container-fluid">
                    @yield('content')
                </div>
            </div>

            <!-- Footer -->
            <footer class="sticky-footer bg-white mt-auto">
                <div class="container my-auto">
                    <div class="copyright text-center my-auto">
                        <span>&copy; Klaten Asyik 2025</span>
                    </div>
                </div>
            </footer>
            <!-- End of Footer -->
        </div>
    </div>

    <!-- Scroll to Top Button-->
    <a class="scroll-to-top rounded" href="#page-top"><i class="fas fa-angle-up"></i></a>

    <!-- Logout Modal-->
    <div class="modal fade" id="logoutModal" tabindex="-1" role="dialog" aria-labelledby="logoutModalLabel"
        aria-hidden="true">
        <div class="modal-dialog" role="document">
            <form id="logout-form" method="POST" action="{{ route('logout') }}">
                @csrf
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title" id="logoutModalLabel">Keluar dari sistem?</h5>
                        <button class="close" type="button" data-dismiss="modal"><span>&times;</span></button>
                    </div>
                    <div class="modal-body">Pilih "Logout" jika Anda yakin ingin mengakhiri sesi ini.</div>
                    <div class="modal-footer">
                        <button class="btn btn-secondary" type="button" data-dismiss="modal">Batal</button>
                        <button type="submit" class="btn btn-primary">Logout</button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!-- JS Scripts -->
    <script src="{{ asset('admin/vendor/jquery/jquery.min.js') }}"></script>
    <script src="{{ asset('admin/vendor/bootstrap/js/bootstrap.bundle.min.js') }}"></script>
    <script src="{{ asset('admin/vendor/jquery-easing/jquery.easing.min.js') }}"></script>
    <script src="{{ asset('admin/js/sb-admin-2.min.js') }}"></script>
    <script src="{{ asset('admin/vendor/datatables/jquery.dataTables.min.js') }}"></script>
    <script src="{{ asset('admin/vendor/datatables/dataTables.bootstrap4.min.js') }}"></script>
    <script src="{{ asset('admin/js/demo/datatables-demo.js') }}"></script>
</body>

</html>
