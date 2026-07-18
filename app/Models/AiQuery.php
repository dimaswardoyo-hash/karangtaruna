<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AiQuery extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'question', 'agent_used', 'answer', 'sources', 'latency_ms'];

    protected $casts = [
        'sources' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function evaluation()
    {
        return $this->hasOne(AiEvaluation::class);
    }
}
