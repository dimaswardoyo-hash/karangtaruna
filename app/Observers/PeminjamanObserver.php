<?php

namespace App\Observers;

use App\Models\Peminjaman;
use App\Services\AiDocumentBuilder;
use App\Services\AiKnowledgeSyncService;

class PeminjamanObserver
{
    public function __construct(private AiKnowledgeSyncService $sync)
    {
    }

    public function saved(Peminjaman $pinjam): void
    {
        $doc = AiDocumentBuilder::peminjaman($pinjam);
        $this->sync->sync($doc['division'], $doc['source_type'], $doc['id'], $doc['content']);
    }

    public function deleted(Peminjaman $pinjam): void
    {
        $this->sync->delete('perlengkapan', 'peminjaman', $pinjam->id);
    }
}
