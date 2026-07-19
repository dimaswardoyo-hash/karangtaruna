<?php

namespace App\Observers;

use App\Models\Pengeluaran;
use App\Services\AiDocumentBuilder;
use App\Services\AiKnowledgeSyncService;

class PengeluaranObserver
{
    public function __construct(private AiKnowledgeSyncService $sync)
    {
    }

    public function saved(Pengeluaran $p): void
    {
        $doc = AiDocumentBuilder::pengeluaran($p);
        $this->sync->sync($doc['division'], $doc['source_type'], $doc['id'], $doc['content']);
    }

    public function deleted(Pengeluaran $p): void
    {
        $this->sync->delete('keuangan', 'pengeluaran', $p->id);
    }
}
