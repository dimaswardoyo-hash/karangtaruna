<?php

namespace App\Observers;

use App\Models\Agenda;
use App\Services\AiDocumentBuilder;
use App\Services\AiKnowledgeSyncService;

class AgendaObserver
{
    public function __construct(private AiKnowledgeSyncService $sync)
    {
    }

    public function saved(Agenda $a): void
    {
        $doc = AiDocumentBuilder::agenda($a);
        $this->sync->sync($doc['division'], $doc['source_type'], $doc['id'], $doc['content']);
    }

    public function deleted(Agenda $a): void
    {
        $this->sync->delete('kegiatan', 'agenda', $a->id);
    }
}
