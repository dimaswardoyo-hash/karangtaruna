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
        Schema::create('ai_evaluations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ai_query_id')->constrained()->cascadeOnDelete();
            $table->float('accuracy_score')->nullable();
            $table->float('effectiveness_score')->nullable();
            $table->float('efficiency_score')->nullable();
            $table->float('explainability_score')->nullable();
            $table->float('hallucination_score')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ai_evaluations');
    }
};
