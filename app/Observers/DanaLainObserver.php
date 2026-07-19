<?php

namespace App\Observers;

use App\Models\DanaLain;
use App\Services\AiDocumentBuilder;
use App\Services\AiKnowledgeSyncService;

class DanaLainObserver
{
    public function __construct(private AiKnowledgeSyncService $sync)
    {
    }

    public function saved(DanaLain $d): void
    {
        $doc = AiDocumentBuilder::danaLain($d);
        $this->sync->sync($doc['division'], $doc['source_type'], $doc['id'], $doc['content']);
    }

    public function deleted(DanaLain $d): void
    {
        $this->sync->delete('keuangan', 'dana_lain', $d->id);
    }
}
