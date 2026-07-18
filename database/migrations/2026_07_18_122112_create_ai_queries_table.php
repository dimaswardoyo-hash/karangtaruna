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
        Schema::create('ai_queries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->text('question');
            $table->string('agent_used')->nullable(); // Agent_Keuangan | Agent_Kegiatan | Agent_Perlengkapan | Agent_Koordinator
            $table->text('answer')->nullable();
            $table->json('sources')->nullable(); // daftar ai_documents.id yang dipakai sebagai sumber
            $table->unsignedInteger('latency_ms')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ai_queries');
    }
};
