<?php

namespace App\Observers;

use App\Models\Notulen;
use App\Services\AiDocumentBuilder;
use App\Services\AiKnowledgeSyncService;

class NotulenObserver
{
    public function __construct(private AiKnowledgeSyncService $sync)
    {
    }

    public function saved(Notulen $n): void
    {
        $doc = AiDocumentBuilder::notulen($n);
        $this->sync->sync($doc['division'], $doc['source_type'], $doc['id'], $doc['content']);
    }

    public function deleted(Notulen $n): void
    {
        $this->sync->delete('kegiatan', 'notulen', $n->id);
    }
}
