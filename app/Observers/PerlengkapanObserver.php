<?php

namespace App\Observers;

use App\Models\Perlengkapan;
use App\Services\AiDocumentBuilder;
use App\Services\AiKnowledgeSyncService;

class PerlengkapanObserver
{
    public function __construct(private AiKnowledgeSyncService $sync)
    {
    }

    public function saved(Perlengkapan $barang): void
    {
        $doc = AiDocumentBuilder::perlengkapan($barang);
        $this->sync->sync($doc['division'], $doc['source_type'], $doc['id'], $doc['content']);
    }

    public function deleted(Perlengkapan $barang): void
    {
        $this->sync->delete('perlengkapan', 'perlengkapan', $barang->id);
    }
}
