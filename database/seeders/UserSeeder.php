<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Faker\Factory as Faker;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // Admin
        User::create([
            'name' => 'Dimas Tampan',
            'email' => 'dimas@gmail.com',
            'password' => Hash::make('uluketel'), 
            'role' => 'admin',
        ]);

        // Anggota 1
        User::create([
            'name' => 'Anggota Satu',
            'email' => 'anggota1@gmail.com',
            'password' => Hash::make('uluketel'),
            'role' => 'anggota',
        ]);

        // Anggota 2
        User::create([
            'name' => 'Anggota Dua',
            'email' => 'anggota2@gmail.com',
            'password' => Hash::make('uluketel'),
            'role' => 'anggota',
        ]);
    }
}
