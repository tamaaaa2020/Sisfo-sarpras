<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // USERS
        DB::table('users')->insert([
            [
                'name' => 'Admin',
                'email' => 'admin@example.com',
                'password' => Hash::make('admin123'),
                'role' => 'admin',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Pratama Ananda Desta',
                'email' => 'pratamaanandadesta@gmail.com',
                'password' => Hash::make('12345678'),
                'role' => 'user',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        // KATEGORI
        DB::table('kategori')->insert([
            [
                'name_Kategori' => 'Elektronik',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name_Kategori' => 'ATK',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        // BARANG
        DB::table('barang')->insert([
            [
                'kode_Barang' => 'EL-001',
                'nama_Barang' => 'Laptop Asus',
                'id_kategori' => '1',
                'jumlah' => 10,
                'satuan' => 'unit',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'kode_Barang' => 'ATK-001',
                'nama_Barang' => 'Pulpen',
                'id_kategori' => '2',
                'jumlah' => 100,
                'satuan' => 'pcs',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        // PEMINJAMAN
        DB::table('peminjaman')->insert([
            [
                'id_user' => '2',
                'id_barang' => '1',
                'jumlah' => 1,
                'tanggal_pinjam' => now()->subDays(3),
                'status' => 'pinjam',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'id_user' => '2',
                'id_barang' => '2',
                'jumlah' => 5,
                'tanggal_pinjam' => now()->subDays(5),
                'status' => 'kembali',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        // PENGEMBALIAN
        DB::table('pengembalian')->insert([
            [
                'id_peminjaman' => '2',
                'tanggal_kembali' => now()->subDays(1),
                'keterangan' => 'Barang kembali dalam kondisi baik',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}
