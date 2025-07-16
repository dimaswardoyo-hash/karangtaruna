<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = ['name', 'email', 'password', 'role'];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = ['password', 'remember_token'];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
    ];
    public function identitas()
    {
        return $this->hasOne(Identitas::class, 'user_id');
    }

    public function kas()
    {
        return $this->hasMany(Kas::class);
    }
    public function hutangs()
    {
        return $this->hasMany(Hutang::class);
    }

    public function perlengkapans()
    {
        return $this->belongsToMany(Perlengkapan::class, 'peminjamans')
            ->withPivot(['jumlah', 'tanggal_pinjam', 'tanggal_kembali', 'status', 'tanggapan_admin'])
            ->withTimestamps();
    }
}
