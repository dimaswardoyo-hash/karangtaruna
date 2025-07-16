<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Perlengkapan extends Model
{
    use HasFactory;
    protected $fillable = ['nama', 'deskripsi', 'stok', 'stok_awal'];
    public function peminjamans()
    {
        return $this->hasMany(Peminjaman::class);
    }
    public function getSedangDipinjamAttribute()
    {
        return $this->stok_awal - $this->stok;
    }

    public function users()
    {
        return $this->belongsToMany(User::class, 'peminjamans')
            ->withPivot(['jumlah', 'tanggal_pinjam', 'tanggal_kembali', 'status', 'tanggapan_admin'])
            ->withTimestamps();
    }
}
