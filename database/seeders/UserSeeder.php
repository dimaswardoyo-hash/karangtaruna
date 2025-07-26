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
            'email' => 'dimaswardoyo10@gmail.com',
            'password' => Hash::make('uluketel'),
            'role' => 'admin',
        ]);

        $faker = Faker::create();

        // 999 Anggota
        for ($i = 1; $i <= 999; $i++) {
            User::create([
                'name' => 'Anggota ' . $i,
                'email' => 'anggota' . $i . '@gmail.com',
                'password' => Hash::make('uluketel'),
                'role' => 'anggota',
            ]);
        }
    }
}