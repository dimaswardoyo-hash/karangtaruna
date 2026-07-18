<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use App\Models\AiQuery;
use App\Models\AiEvaluation;

class AiAssistantController extends Controller
{
    /**
     * Halaman chat AI Assistant (bisa diakses admin & anggota).
     */
    public function index()
    {
        $riwayat = AiQuery::where('user_id', auth()->id())
            ->latest()
            ->limit(10)
            ->get();

        return view('ai-assistant.index', compact('riwayat'));
    }

    /**
     * Terima pertanyaan dari form/AJAX, teruskan ke AI service (Python),
     * simpan log + hasil evaluasi, lalu kembalikan jawabannya.
     */
    public function query(Request $request)
    {
        $request->validate([
            'question' => 'required|string|max:1000',
        ]);

        $start = microtime(true);

        try {
            $response = Http::timeout(30)->post(rtrim(config('services.ai_service.url'), '/') . '/query', [
                'question' => $request->input('question'),
                'user_role' => auth()->user()->role,
            ]);
        } catch (\Illuminate\Http\Client\ConnectionException $e) {
            // ai-service belum jalan / alamat AI_SERVICE_URL salah / port ditutup firewall.
            return response()->json(
                [
                    'error' => 'Tidak dapat terhubung ke AI service. Pastikan ai-service (python app.py) sedang berjalan dan AI_SERVICE_URL di .env sudah benar.',
                ],
                502,
            );
        }

        $latencyMs = (int) ((microtime(true) - $start) * 1000);

        if (!$response->successful()) {
            return response()->json(
                [
                    'error' => 'AI service tidak dapat dihubungi. Pastikan ai-service sedang berjalan.',
                ],
                502,
            );
        }

        $data = $response->json();
        // Struktur respons yang diharapkan dari AI service:
        // { answer, agent_used, sources: [ai_document_id, ...], evaluation: { accuracy, effectiveness, efficiency, explainability, hallucination } }

        $aiQuery = AiQuery::create([
            'user_id' => auth()->id(),
            'question' => $request->input('question'),
            'agent_used' => $data['agent_used'] ?? null,
            'answer' => $data['answer'] ?? null,
            'sources' => $data['sources'] ?? [],
            'latency_ms' => $latencyMs,
        ]);

        if (isset($data['evaluation'])) {
            AiEvaluation::create([
                'ai_query_id' => $aiQuery->id,
                'accuracy_score' => $data['evaluation']['accuracy'] ?? null,
                'effectiveness_score' => $data['evaluation']['effectiveness'] ?? null,
                'efficiency_score' => $data['evaluation']['efficiency'] ?? null,
                'explainability_score' => $data['evaluation']['explainability'] ?? null,
                'hallucination_score' => $data['evaluation']['hallucination'] ?? null,
            ]);
        }

        return response()->json([
            'question' => $aiQuery->question,
            'answer' => $aiQuery->answer,
            'agent_used' => $aiQuery->agent_used,
            'latency_ms' => $aiQuery->latency_ms,
        ]);
    }

    /**
     * Dashboard evaluasi (admin only) â€” rata-rata skor evaluator per divisi/agent.
     */
    public function insight()
    {
        $ringkasan = AiEvaluation::join('ai_queries', 'ai_queries.id', '=', 'ai_evaluations.ai_query_id')
            ->selectRaw(
                'ai_queries.agent_used,
                AVG(accuracy_score) as avg_accuracy,
                AVG(effectiveness_score) as avg_effectiveness,
                AVG(efficiency_score) as avg_efficiency,
                AVG(explainability_score) as avg_explainability,
                AVG(hallucination_score) as avg_hallucination,
                COUNT(*) as total',
            )
            ->groupBy('ai_queries.agent_used')
            ->get();

        $riwayatTerbaru = AiQuery::with('evaluation')->latest()->limit(20)->get();

        return view('ai-assistant.insight', compact('ringkasan', 'riwayatTerbaru'));
    }
}
