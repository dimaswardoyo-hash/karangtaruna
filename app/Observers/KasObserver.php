<?php

namespace App\Observers;

use App\Models\Kas;
use App\Services\AiDocumentBuilder;
use App\Services\AiKnowledgeSyncService;

class KasObserver
{
    public function __construct(private AiKnowledgeSyncService $sync)
    {
    }

    public function saved(Kas $kas): void
    {
        $doc = AiDocumentBuilder::kas($kas);
        $this->sync->sync($doc['division'], $doc['source_type'], $doc['id'], $doc['content']);
    }

    public function deleted(Kas $kas): void
    {
        $this->sync->delete('keuangan', 'kas', $kas->id);
    }
}
