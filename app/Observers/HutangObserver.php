<?php

namespace App\Observers;

use App\Models\Hutang;
use App\Services\AiDocumentBuilder;
use App\Services\AiKnowledgeSyncService;

class HutangObserver
{
    public function __construct(private AiKnowledgeSyncService $sync)
    {
    }

    public function saved(Hutang $h): void
    {
        $doc = AiDocumentBuilder::hutang($h);
        $this->sync->sync($doc['division'], $doc['source_type'], $doc['id'], $doc['content']);
    }

    public function deleted(Hutang $h): void
    {
        $this->sync->delete('keuangan', 'hutang', $h->id);
    }
}
