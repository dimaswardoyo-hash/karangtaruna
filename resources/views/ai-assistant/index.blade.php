@extends('layouts.dashboard')

@section('content')
    <div class="container-fluid ai-page">

        <h1 class="h3 mb-4 text-gray-800">AI Assistant Karang Taruna</h1>

        <div class="row">
            <div class="col-lg-8">
                <div class="ai-card ai-chat-card">
                    <div class="ai-card-header">
                        <span class="ai-header-dot"></span>
                        Tanya seputar Keuangan, Kegiatan, atau Perlengkapan
                    </div>

                    <div id="chat-window" class="ai-chat-window">
                        <div class="ai-hint">
                            Contoh: "Berapa total pengeluaran bulan ini?", "Agenda apa yang akan datang?", "Barang apa saja
                            yang sedang dipinjam?"
                        </div>
                    </div>

                    <div id="typing-indicator" class="ai-typing" style="display: none;">
                        <span class="ai-dot"></span><span class="ai-dot"></span><span class="ai-dot"></span>
                    </div>

                    <form id="ai-form" class="ai-input-row">
                        @csrf
                        <input type="text" id="question" name="question" class="ai-input"
                            placeholder="Tulis pertanyaan Anda..." required maxlength="1000" autocomplete="off">
                        <button type="submit" id="ai-submit-btn" class="ai-send-btn" aria-label="Kirim">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                                stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <line x1="22" y1="2" x2="11" y2="13"></line>
                                <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                            </svg>
                        </button>
                    </form>
                </div>
            </div>

            <div class="col-lg-4">
                <div class="ai-card">
                    <div class="ai-card-header ai-card-header-flex">
                        <span>Riwayat Pertanyaan</span>
                        <button type="button" id="clear-history-btn" class="ai-clear-btn"
                            @if ($riwayat->isEmpty()) style="display:none;" @endif>
                            Hapus semua
                        </button>
                    </div>
                    <div class="ai-riwayat-list" id="riwayat-list">
                        @forelse ($riwayat as $r)
                            <div class="ai-riwayat-item" data-id="{{ $r->id }}">
                                <div class="ai-riwayat-content">
                                    <div class="ai-riwayat-question">{{ $r->question }}</div>
                                    <div class="ai-riwayat-meta">{{ $r->agent_used ?? '-' }} &middot;
                                        {{ $r->created_at->diffForHumans() }}</div>
                                </div>
                                <button type="button" class="ai-delete-btn" data-id="{{ $r->id }}"
                                    aria-label="Hapus riwayat ini">
                                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none"
                                        stroke="currentColor" stroke-width="2" stroke-linecap="round"
                                        stroke-linejoin="round">
                                        <polyline points="3 6 5 6 21 6"></polyline>
                                        <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"></path>
                                        <path d="M10 11v6"></path>
                                        <path d="M14 11v6"></path>
                                        <path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"></path>
                                    </svg>
                                </button>
                            </div>
                        @empty
                            <p class="ai-riwayat-empty" id="riwayat-empty">Belum ada riwayat pertanyaan.</p>
                        @endforelse
                    </div>
                </div>
            </div>
        </div>
    </div>

    {{-- Catatan: layout dashboard.blade.php saat ini tidak punya @stack('scripts'),
     jadi script diletakkan langsung di sini (dijalankan setelah DOM di atasnya ter-render). --}}
    <style>
        .ai-page {
            --ai-accent: #4e73df;
            --ai-accent-dark: #3d5fc4;
        }

        .ai-card {
            background: #fff;
            border: 1px solid #eceef1;
            border-radius: 16px;
            margin-bottom: 1.5rem;
            overflow: hidden;
        }

        .ai-card-header {
            padding: 1rem 1.25rem;
            font-weight: 600;
            font-size: 0.95rem;
            color: #2c2c2a;
            border-bottom: 1px solid #f1f1f1;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .ai-card-header-flex {
            justify-content: space-between;
        }

        .ai-header-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: #1d9e75;
            display: inline-block;
            flex-shrink: 0;
        }

        .ai-clear-btn {
            border: none;
            background: transparent;
            color: #a32d2d;
            font-size: 0.78rem;
            font-weight: 500;
            padding: 4px 8px;
            border-radius: 8px;
            cursor: pointer;
        }

        .ai-clear-btn:hover {
            background: #fbeaea;
        }

        .ai-chat-window {
            max-height: 480px;
            min-height: 320px;
            overflow-y: auto;
            padding: 1.25rem;
        }

        .ai-hint {
            color: #9c9a94;
            font-size: 0.85rem;
            margin-bottom: 1rem;
            line-height: 1.5;
        }

        .ai-row {
            display: flex;
            margin-bottom: 14px;
        }

        .ai-row.end {
            justify-content: flex-end;
        }

        .ai-bubble {
            max-width: 82%;
            padding: 10px 14px;
            border-radius: 14px;
            font-size: 0.9rem;
            line-height: 1.5;
            white-space: pre-wrap;
            word-break: break-word;
        }

        .ai-bubble.user {
            background: var(--ai-accent);
            color: #fff;
            border-bottom-right-radius: 4px;
        }

        .ai-bubble.ai {
            background: #f4f5f8;
            color: #2c2c2a;
            border-bottom-left-radius: 4px;
        }

        .ai-bubble.error {
            background: #fbeaea;
            color: #a32d2d;
        }

        .ai-agent-label {
            font-size: 0.72rem;
            font-weight: 600;
            color: var(--ai-accent);
            margin-bottom: 4px;
        }

        .ai-meta {
            font-size: 0.7rem;
            color: #b4b2a9;
            margin: 4px 0 0 2px;
        }

        .ai-meta.right {
            text-align: right;
            margin-right: 2px;
        }

        .ai-badges {
            margin-top: 8px;
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
        }

        .ai-badge {
            font-size: 0.68rem;
            padding: 2px 9px;
            border-radius: 20px;
            background: #e1f5ee;
            color: #085041;
            font-weight: 500;
        }

        .ai-typing {
            padding: 0 1.25rem;
            margin-bottom: 6px;
            display: flex;
            gap: 4px;
        }

        .ai-dot {
            width: 6px;
            height: 6px;
            border-radius: 50%;
            background: #c4c2b8;
            animation: ai-bounce 1.2s infinite ease-in-out;
        }

        .ai-dot:nth-child(2) {
            animation-delay: 0.15s;
        }

        .ai-dot:nth-child(3) {
            animation-delay: 0.3s;
        }

        @keyframes ai-bounce {

            0%,
            80%,
            100% {
                transform: scale(0.7);
                opacity: 0.5;
            }

            40% {
                transform: scale(1);
                opacity: 1;
            }
        }

        .ai-input-row {
            display: flex;
            gap: 10px;
            padding: 1rem 1.25rem;
            border-top: 1px solid #f1f1f1;
        }

        .ai-input {
            flex: 1;
            border: 1px solid #e3e3e0;
            border-radius: 22px;
            padding: 10px 18px;
            font-size: 0.9rem;
            outline: none;
        }

        .ai-input:focus {
            border-color: var(--ai-accent);
        }

        .ai-send-btn {
            width: 42px;
            height: 42px;
            border-radius: 50%;
            border: none;
            background: var(--ai-accent);
            color: #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            flex-shrink: 0;
        }

        .ai-send-btn:hover {
            background: var(--ai-accent-dark);
        }

        .ai-send-btn:disabled {
            opacity: 0.5;
            cursor: default;
        }

        .ai-riwayat-list {
            padding: 0.5rem 0.75rem 0.75rem;
            max-height: 480px;
            overflow-y: auto;
        }

        .ai-riwayat-item {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 8px;
            padding: 10px 8px;
            border-radius: 10px;
        }

        .ai-riwayat-item:hover {
            background: #f7f7f5;
        }

        .ai-riwayat-content {
            min-width: 0;
        }

        .ai-riwayat-question {
            font-weight: 500;
            font-size: 0.85rem;
            color: #2c2c2a;
            overflow: hidden;
            text-overflow: ellipsis;
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
        }

        .ai-riwayat-meta {
            font-size: 0.72rem;
            color: #9c9a94;
            margin-top: 2px;
        }

        .ai-delete-btn {
            border: none;
            background: transparent;
            color: #b4b2a9;
            padding: 4px;
            border-radius: 6px;
            cursor: pointer;
            flex-shrink: 0;
        }

        .ai-delete-btn:hover {
            background: #fbeaea;
            color: #a32d2d;
        }

        .ai-riwayat-empty {
            color: #9c9a94;
            font-size: 0.85rem;
            padding: 1rem 0.5rem;
            margin: 0;
        }
    </style>

    <script>
        (function() {
            const chatWindow = document.getElementById('chat-window');
            const typingIndicator = document.getElementById('typing-indicator');
            const form = document.getElementById('ai-form');
            const input = document.getElementById('question');
            const submitBtn = document.getElementById('ai-submit-btn');
            const riwayatList = document.getElementById('riwayat-list');
            const clearBtn = document.getElementById('clear-history-btn');
            const csrfToken = document.querySelector('input[name=_token]').value;

            function escapeHtml(text) {
                const div = document.createElement('div');
                div.textContent = text ?? '';
                return div.innerHTML;
            }

            function addRiwayatItem(id, question, agent) {
                const empty = document.getElementById('riwayat-empty');
                if (empty) empty.remove();

                const item = document.createElement('div');
                item.className = 'ai-riwayat-item';
                item.dataset.id = id;
                item.innerHTML = `
            <div class="ai-riwayat-content">
                <div class="ai-riwayat-question">${escapeHtml(question)}</div>
                <div class="ai-riwayat-meta">${escapeHtml(agent)} &middot; baru saja</div>
            </div>
            <button type="button" class="ai-delete-btn" data-id="${id}" aria-label="Hapus riwayat ini">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"></path><path d="M10 11v6"></path><path d="M14 11v6"></path><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"></path></svg>
            </button>
        `;
                riwayatList.prepend(item);
                clearBtn.style.display = '';
            }

            function showEmptyRiwayatIfNeeded() {
                if (!riwayatList.querySelector('.ai-riwayat-item')) {
                    riwayatList.innerHTML =
                        '<p class="ai-riwayat-empty" id="riwayat-empty">Belum ada riwayat pertanyaan.</p>';
                    clearBtn.style.display = 'none';
                }
            }

            form.addEventListener('submit', async function(e) {
                e.preventDefault();

                const question = input.value.trim();
                if (!question) return;

                chatWindow.insertAdjacentHTML('beforeend', `
            <div class="ai-row end">
                <div class="ai-bubble user">${escapeHtml(question)}</div>
            </div>
        `);

                input.value = '';
                input.disabled = true;
                submitBtn.disabled = true;
                typingIndicator.style.display = 'flex';
                chatWindow.scrollTop = chatWindow.scrollHeight;

                try {
                    const res = await fetch("{{ route('ai.query') }}", {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'X-CSRF-TOKEN': csrfToken,
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
                    <div class="ai-row">
                        <div class="ai-bubble error">Server mengembalikan respons tidak terduga (status ${res.status}). Coba muat ulang halaman.</div>
                    </div>
                `);
                        return;
                    }

                    if (!res.ok) {
                        chatWindow.insertAdjacentHTML('beforeend', `
                    <div class="ai-row">
                        <div class="ai-bubble error">${escapeHtml(data.error ?? 'Terjadi kesalahan.')}</div>
                    </div>
                `);
                    } else {
                        const agent = data.agent_used ?? 'AI Assistant';
                        let badges = '';
                        if (data.evaluation) {
                            const ev = data.evaluation;
                            const pct = (v) => (v === null || v === undefined) ? '-' : Math.round(v * 100) +
                                '%';
                            badges = `
                        <div class="ai-badges">
                            <span class="ai-badge">Akurasi ${pct(ev.accuracy)}</span>
                            <span class="ai-badge">Efektivitas ${pct(ev.effectiveness)}</span>
                            <span class="ai-badge">Eksplainabilitas ${pct(ev.explainability)}</span>
                        </div>
                    `;
                        }

                        chatWindow.insertAdjacentHTML('beforeend', `
                    <div class="ai-row">
                        <div>
                            <div class="ai-bubble ai">
                                <div class="ai-agent-label">${escapeHtml(agent)}</div>
                                ${escapeHtml(data.answer ?? '')}
                                ${badges}
                            </div>
                            <div class="ai-meta">${data.latency_ms ?? 0} ms${data.warning ? ' &middot; ' + escapeHtml(data.warning) : ''}</div>
                        </div>
                    </div>
                `);

                        addRiwayatItem(data.id ?? '', data.question ?? question, agent);
                    }
                } catch (err) {
                    chatWindow.insertAdjacentHTML('beforeend', `
                <div class="ai-row">
                    <div class="ai-bubble error">Tidak dapat menjangkau server Laravel. Cek koneksi internet Anda atau muat ulang halaman.</div>
                </div>
            `);
                }

                typingIndicator.style.display = 'none';
                input.disabled = false;
                submitBtn.disabled = false;
                input.focus();
                chatWindow.scrollTop = chatWindow.scrollHeight;
            });

            riwayatList.addEventListener('click', async function(e) {
                const btn = e.target.closest('.ai-delete-btn');
                if (!btn) return;

                const id = btn.dataset.id;
                const item = btn.closest('.ai-riwayat-item');

                try {
                    const res = await fetch(`/ai-assistant/history/${id}`, {
                        method: 'DELETE',
                        headers: {
                            'X-CSRF-TOKEN': csrfToken
                        },
                    });
                    if (res.ok) {
                        item.remove();
                        showEmptyRiwayatIfNeeded();
                    }
                } catch (err) {
                    // biarkan item tetap tampil kalau request gagal, tidak perlu block UI
                }
            });

            clearBtn.addEventListener('click', async function() {
                if (!confirm('Hapus semua riwayat pertanyaan?')) return;

                try {
                    const res = await fetch("{{ route('ai.history.clear') }}", {
                        method: 'DELETE',
                        headers: {
                            'X-CSRF-TOKEN': csrfToken
                        },
                    });
                    if (res.ok) {
                        riwayatList.innerHTML =
                            '<p class="ai-riwayat-empty" id="riwayat-empty">Belum ada riwayat pertanyaan.</p>';
                        clearBtn.style.display = 'none';
                    }
                } catch (err) {
                    // no-op
                }
            });
        })();
    </script>
@endsection
