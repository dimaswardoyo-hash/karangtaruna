<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('ai_documents', function (Blueprint $table) {
            $table->id();
            $table->string('division'); // keuangan | kegiatan | perlengkapan
            $table->string('source_type'); // nama tabel asal: kas, pengeluaran, agenda, dst
            $table->unsignedBigInteger('source_id')->nullable(); // id record asal
            $table->text('content'); // isi dokumen dalam bentuk teks
            $table->timestamp('embedded_at')->nullable(); // null = belum di-embed ke vector DB
            $table->timestamps();

            $table->index(['division', 'source_type']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ai_documents');
    }
};
