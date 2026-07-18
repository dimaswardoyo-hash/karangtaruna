<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AiDocument extends Model
{
    use HasFactory;

    protected $fillable = ['division', 'source_type', 'source_id', 'content', 'embedded_at'];

    protected $casts = [
        'embedded_at' => 'datetime',
    ];

    public function scopeBelumDiEmbed($query)
    {
        return $query->whereNull('embedded_at');
    }

    public function scopeDivisi($query, string $division)
    {
        return $query->where('division', $division);
    }
}
