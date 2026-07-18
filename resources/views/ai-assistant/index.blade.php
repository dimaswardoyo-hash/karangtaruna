@extends('layouts.dashboard')

@section('content')
    <div class="container-fluid">

        <h1 class="h3 mb-4 text-gray-800">AI Assistant Karang Taruna</h1>

        <div class="row">
            <div class="col-lg-8">
                <div class="card shadow mb-4">
                    <div class="card-header py-3">
                        <h6 class="m-0 font-weight-bold text-primary">Tanya seputar Keuangan, Kegiatan, atau Perlengkapan
                        </h6>
                    </div>
                    <div class="card-body">
                        <div id="chat-window" style="max-height: 480px; overflow-y: auto;" class="mb-3 px-1">
                            <div class="text-muted small mb-3">
                                Contoh: "Berapa total pengeluaran bulan ini?", "Agenda apa yang akan datang?", "Barang apa
                                saja yang sedang dipinjam?"
                            </div>
                        </div>

                        <div id="typing-indicator" class="text-muted small mb-2" style="display: none;">
                            <span class="spinner-border spinner-border-sm mr-1"
                                style="width: 0.8rem; height: 0.8rem;"></span>
                            AI Assistant sedang mengetik...
                        </div>

                        <form id="ai-form" class="form-inline">
                            @csrf
                            <input type="text" id="question" name="question" class="form-control flex-grow-1 mr-2"
                                placeholder="Tulis pertanyaan Anda..." required maxlength="1000" autocomplete="off">
                            <button type="submit" id="ai-submit-btn" class="btn btn-primary">Kirim</button>
                        </form>
                    </div>
                </div>
            </div>

            <div class="col-lg-4">
                <div class="card shadow mb-4">
                    <div class="card-header py-3">
                        <h6 class="m-0 font-weight-bold text-primary">Riwayat Pertanyaan Anda</h6>
                    </div>
                    <div class="card-body" id="riwayat-list">
                        @forelse ($riwayat as $r)
                            <div class="mb-3 pb-2 border-bottom riwayat-item">
                                <div class="font-weight-bold small">{{ $r->question }}</div>
                                <div class="text-muted small">Agent: {{ $r->agent_used ?? '-' }} &middot;
                                    {{ $r->created_at->diffForHumans() }}</div>
                            </div>
                        @empty
                            <p class="text-muted small mb-0" id="riwayat-empty">Belum ada riwayat pertanyaan.</p>
                        @endforelse
                    </div>
                </div>
            </div>
        </div>
    </div>

    {{-- Catatan: layout dashboard.blade.php saat ini tidak punya @stack('scripts'),
     jadi script diletakkan langsung di sini (dijalankan setelah DOM di atasnya ter-render). --}}
    <style>
        .chat-bubble-user,
        .chat-bubble-ai,
        .chat-bubble-error {
            max-width: 85%;
            padding: 8px 12px;
            border-radius: 10px;
            margin-bottom: 10px;
            font-size: 0.9rem;
            line-height: 1.45;
            white-space: pre-wrap;
            word-break: break-word;
        }

        .chat-bubble-user {
            background: #4e73df;
            color: #fff;
            margin-left: auto;
        }

        .chat-bubble-ai {
            background: #f1f3f9;
            color: #2c2c2a;
        }

        .chat-bubble-error {
            background: #fbeaea;
            color: #a32d2d;
            border: 1px solid #f0999599;
        }

        .chat-row {
            display: flex;
        }

        .chat-row.justify-end {
            justify-content: flex-end;
        }

        .chat-meta {
            font-size: 0.72rem;
            color: #888780;
            margin-top: -6px;
            margin-bottom: 10px;
        }

        .chat-meta.text-right {
            text-align: right;
        }

        .evaluation-badges span {
            display: inline-block;
            font-size: 0.68rem;
            padding: 1px 6px;
            border-radius: 10px;
            background: #e1f5ee;
            color: #085041;
            margin-right: 4px;
        }
    </style>

    <script>
        document.getElementById('ai-form').addEventListener('submit', async function(e) {
            e.preventDefault();

            const input = document.getElementById('question');
            const chatWindow = document.getElementById('chat-window');
            const typingIndicator = document.getElementById('typing-indicator');
            const submitBtn = document.getElementById('ai-submit-btn');
            const question = input.value.trim();
            if (!question) return;

            function escapeHtml(text) {
                const div = document.createElement('div');
                div.textContent = text;
                return div.innerHTML;
            }

            chatWindow.insertAdjacentHTML('beforeend', `
        <div class="chat-row justify-end">
            <div class="chat-bubble-user">${escapeHtml(question)}</div>
        </div>
    `);

            input.value = '';
            input.disabled = true;
            submitBtn.disabled = true;
            typingIndicator.style.display = 'block';
            chatWindow.scrollTop = chatWindow.scrollHeight;

            try {
                const res = await fetch("{{ route('ai.query') }}", {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': document.querySelector('input[name=_token]').value,
                    },
                    body: JSON.stringify({
                        question
                    }),
                });

                const rawText = await res.text();
                let data;
                try {
                    data = JSON.parse(rawText);
                } catch (parseErr) {
                    chatWindow.insertAdjacentHTML('beforeend', `
                <div class="chat-row">
                    <div class="chat-bubble-error">
                        <strong>Sistem:</strong> Server mengembalikan respons tidak terduga (status ${res.status}).
                        Kemungkinan sesi login habis, atau ada error di server. Coba muat ulang halaman.
                    </div>
                </div>
            `);
                    typingIndicator.style.display = 'none';
                    input.disabled = false;
                    submitBtn.disabled = false;
                    input.focus();
                    return;
                }

                if (!res.ok) {
                    chatWindow.insertAdjacentHTML('beforeend', `
                <div class="chat-row">
                    <div class="chat-bubble-error"><strong>Sistem:</strong> ${escapeHtml(data.error ?? 'Terjadi kesalahan.')}</div>
                </div>
            `);
                } else {
                    const agent = data.agent_used ?? 'AI Assistant';
                    let badges = '';
                    if (data.evaluation) {
                        const ev = data.evaluation;
                        const pct = (v) => v === null || v === undefined ? '-' : Math.round(v * 100) + '%';
                        badges = `
                    <div class="evaluation-badges mt-1">
                        <span>Akurasi ${pct(ev.accuracy)}</span>
                        <span>Efektivitas ${pct(ev.effectiveness)}</span>
                        <span>Eksplainabilitas ${pct(ev.explainability)}</span>
                    </div>
                `;
                    }

                    chatWindow.insertAdjacentHTML('beforeend', `
                <div class="chat-row">
                    <div>
                        <div class="chat-bubble-ai">
                            <div class="small font-weight-bold text-primary mb-1">${escapeHtml(agent)}</div>
                            ${escapeHtml(data.answer ?? '')}
                            ${badges}
                        </div>
                        <div class="chat-meta">${data.latency_ms ?? 0} ms${data.warning ? ' &middot; ' + escapeHtml(data.warning) : ''}</div>
                    </div>
                </div>
            `);

                    const riwayatList = document.getElementById('riwayat-list');
                    const riwayatEmpty = document.getElementById('riwayat-empty');
                    if (riwayatEmpty) riwayatEmpty.remove();
                    riwayatList.insertAdjacentHTML('afterbegin', `
                <div class="mb-3 pb-2 border-bottom riwayat-item">
                    <div class="font-weight-bold small">${escapeHtml(data.question ?? question)}</div>
                    <div class="text-muted small">Agent: ${escapeHtml(agent)} &middot; baru saja</div>
                </div>
            `);
                }
            } catch (err) {
                chatWindow.insertAdjacentHTML('beforeend', `
            <div class="chat-row">
                <div class="chat-bubble-error">
                    <strong>Sistem:</strong> Tidak dapat menjangkau server Laravel. Cek koneksi internet Anda atau muat ulang halaman.
                </div>
            </div>
        `);
            }

            typingIndicator.style.display = 'none';
            input.disabled = false;
            submitBtn.disabled = false;
            input.focus();
            chatWindow.scrollTop = chatWindow.scrollHeight;
        });
    </script>
@endsection
