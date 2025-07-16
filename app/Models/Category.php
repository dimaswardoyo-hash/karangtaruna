<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    use HasFactory;
    protected $table = 'kategoris';

    protected $fillable = ['nama_kategori', 'gambar_kategori'];
    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }
    public function kontens()
    {
        return $this->belongsToMany(Konten::class, 'kategori_konten');
    }
}
