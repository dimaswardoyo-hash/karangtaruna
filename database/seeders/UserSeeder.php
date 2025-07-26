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
        User::create([
            'name' => 'Anggota 1',
            'email' => 'anggota1@gmail.com',
            'password' => Hash::make('uluketel'),
            'role' => 'anggota',
        ]);
        User::create([
            'name' => 'Anggota 2',
            'email' => 'anggota2@gmail.com',
            'password' => Hash::make('uluketel'),
            'role' => 'anggota',
        ]);
    }
}
