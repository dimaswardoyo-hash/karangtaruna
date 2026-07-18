<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AiEvaluation extends Model
{
    use HasFactory;

    protected $fillable = ['ai_query_id', 'accuracy_score', 'effectiveness_score', 'efficiency_score', 'explainability_score', 'hallucination_score', 'notes'];

    public function aiQuery()
    {
        return $this->belongsTo(AiQuery::class, 'ai_query_id');
    }
}
