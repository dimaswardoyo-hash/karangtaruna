@extends('layouts.dashboard')

@section('content')
<div class="container-fluid">

    <h1 class="h3 mb-4 text-gray-800">AI Assistant Karang Taruna</h1>

    <div class="row">
        <div class="col-lg-8">
            <div class="card shadow mb-4">
                <div class="card-header py-3">
                    <h6 class="m-0 font-weight-bold text-primary">Tanya seputar Keuangan, Kegiatan, atau Perlengkapan</h6>
                </div>
                <div class="card-body">
                    <div id="chat-window" style="max-height: 420px; overflow-y: auto;" class="mb-3">
                        <div class="text-muted small">Contoh: "Berapa total pengeluaran bulan ini?", "Agenda apa yang akan datang?", "Barang apa saja yang sedang dipinjam?"</div>
                    </div>

                    <form id="ai-form" class="form-inline">
                        @csrf
                        <input type="text" id="question" name="question" class="form-control flex-grow-1 mr-2"
                               placeholder="Tulis pertanyaan Anda..." required maxlength="1000">
                        <button type="submit" class="btn btn-primary">Kirim</button>
                    </form>
                </div>
            </div>
        </div>

        <div class="col-lg-4">
            <div class="card shadow mb-4">
                <div class="card-header py-3">
                    <h6 class="m-0 font-weight-bold text-primary">Riwayat Pertanyaan Anda</h6>
                </div>
                <div class="card-body">
                    @forelse ($riwayat as $r)
                        <div class="mb-3 pb-2 border-bottom">
                            <div class="font-weight-bold small">{{ $r->question }}</div>
                            <div class="text-muted small">Agent: {{ $r->agent_used ?? '-' }} &middot; {{ $r->created_at->diffForHumans() }}</div>
                        </div>
                    @empty
                        <p class="text-muted small mb-0">Belum ada riwayat pertanyaan.</p>
                    @endforelse
                </div>
            </div>
        </div>
    </div>
</div>

{{-- Catatan: layout dashboard.blade.php saat ini tidak punya @stack('scripts'),
     jadi script diletakkan langsung di sini (dijalankan setelah DOM di atasnya ter-render). --}}
<script>
document.getElementById('ai-form').addEventListener('submit', async function (e) {
    e.preventDefault();

    const input = document.getElementById('question');
    const chatWindow = document.getElementById('chat-window');
    const question = input.value;

    chatWindow.insertAdjacentHTML('beforeend', `<div class="mb-2"><strong>Anda:</strong> ${question}</div>`);
    input.value = '';
    input.disabled = true;

    try {
        const res = await fetch("{{ route('ai.query') }}", {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': document.querySelector('input[name=_token]').value,
            },
            body: JSON.stringify({ question }),
        });

        const data = await res.json();

        if (!res.ok) {
            chatWindow.insertAdjacentHTML('beforeend', `<div class="mb-2 text-danger"><strong>Sistem:</strong> ${data.error ?? 'Terjadi kesalahan.'}</div>`);
        } else {
            chatWindow.insertAdjacentHTML('beforeend', `<div class="mb-3"><strong>${data.agent_used ?? 'AI Assistant'}:</strong> ${data.answer} <span class="text-muted small">(${data.latency_ms} ms)</span></div>`);
        }
    } catch (err) {
        chatWindow.insertAdjacentHTML('beforeend', `<div class="mb-2 text-danger"><strong>Sistem:</strong> Tidak dapat terhubung ke AI service.</div>`);
    }

    input.disabled = false;
    chatWindow.scrollTop = chatWindow.scrollHeight;
});
</script>
@endsection
