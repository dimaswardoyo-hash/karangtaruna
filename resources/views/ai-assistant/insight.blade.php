@extends('layouts.dashboard')

@section('content')
<div class="container-fluid">

    <h1 class="h3 mb-4 text-gray-800">AI Insight &mdash; Evaluasi Multi-Agent</h1>

    <div class="card shadow mb-4">
        <div class="card-header py-3">
            <h6 class="m-0 font-weight-bold text-primary">Rata-rata Skor Evaluator per Agent</h6>
        </div>
        <div class="card-body">
            <div class="table-responsive">
                <table class="table table-bordered" width="100%">
                    <thead>
                        <tr>
                            <th>Agent</th>
                            <th>Total Query</th>
                            <th>Accuracy</th>
                            <th>Effectiveness</th>
                            <th>Efficiency</th>
                            <th>Explainability</th>
                            <th>Hallucination</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse ($ringkasan as $r)
                            <tr>
                                <td>{{ $r->agent_used ?? '-' }}</td>
                                <td>{{ $r->total }}</td>
                                <td>{{ $r->avg_accuracy !== null ? number_format($r->avg_accuracy, 2) : '-' }}</td>
                                <td>{{ $r->avg_effectiveness !== null ? number_format($r->avg_effectiveness, 2) : '-' }}</td>
                                <td>{{ $r->avg_efficiency !== null ? number_format($r->avg_efficiency, 2) : '-' }}</td>
                                <td>{{ $r->avg_explainability !== null ? number_format($r->avg_explainability, 2) : '-' }}</td>
                                <td>{{ $r->avg_hallucination !== null ? number_format($r->avg_hallucination, 2) : '-' }}</td>
                            </tr>
                        @empty
                            <tr><td colspan="7" class="text-center text-muted">Belum ada data evaluasi.</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <div class="card shadow mb-4">
        <div class="card-header py-3">
            <h6 class="m-0 font-weight-bold text-primary">Riwayat Query Terbaru</h6>
        </div>
        <div class="card-body">
            <div class="table-responsive">
                <table class="table table-bordered" width="100%">
                    <thead>
                        <tr>
                            <th>Pertanyaan</th>
                            <th>Agent</th>
                            <th>Latency</th>
                            <th>Accuracy</th>
                            <th>Hallucination</th>
                            <th>Waktu</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($riwayatTerbaru as $q)
                            <tr>
                                <td>{{ \Illuminate\Support\Str::limit($q->question, 60) }}</td>
                                <td>{{ $q->agent_used ?? '-' }}</td>
                                <td>{{ $q->latency_ms }} ms</td>
                                <td>{{ $q->evaluation?->accuracy_score ?? '-' }}</td>
                                <td>{{ $q->evaluation?->hallucination_score ?? '-' }}</td>
                                <td>{{ $q->created_at->format('d M Y H:i') }}</td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
@endsection
