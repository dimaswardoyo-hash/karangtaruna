<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Kategori extends Model
{
    use HasFactory;
    protected $fillable = ['nama_kategori', 'gambar_kategori'];

    public function kontens()
    {
        return $this->belongsToMany(Konten::class, 'kategori_konten');
    }
}
