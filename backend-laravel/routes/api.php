<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\BarangController;
use App\Http\Controllers\PeminjamanController;
use App\Http\Controllers\PengembalianController;
use App\Http\Controllers\KategoriController;
use App\Http\Controllers\LaporanController;

// AUTH
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::get('/kategori', [KategoriController::class, 'index']);
Route::post('/kategori', [KategoriController::class, 'store']);
Route::get('/kategori/{id}', [KategoriController::class, 'show']);
Route::put('/kategori/{id}', [KategoriController::class, 'update']);
Route::delete('/kategori/{id}', [KategoriController::class, 'destroy']);

// Barang Routes
Route::get('/barang', [BarangController::class, 'index']);
Route::post('/barang', [BarangController::class, 'store']);
Route::get('/barang/{id}', [BarangController::class, 'show']);
Route::put('/barang/{id}', [BarangController::class, 'update']);
Route::delete('/barang/{id}', [BarangController::class, 'destroy']);

// Peminjaman Routes
Route::get('/peminjaman', [PeminjamanController::class, 'index']);
Route::post('/peminjaman', [PeminjamanController::class, 'store']);
Route::get('/peminjaman/{id}', [PeminjamanController::class, 'show']);
Route::put('/peminjaman/{id}', [PeminjamanController::class, 'update']);
Route::delete('/peminjaman/{id}', [PeminjamanController::class, 'destroy']);
Route::put('/peminjaman/{id}/approve', [PeminjamanController::class, 'approve']);
Route::put('/peminjaman/{id}/reject', [PeminjamanController::class, 'reject']);


// Pengembalian Routes
Route::get('/pengembalian', [PengembalianController::class, 'index']);
Route::post('/pengembalian', [PengembalianController::class, 'store']);
Route::get('/pengembalian/{id}', [PengembalianController::class, 'show']);
Route::put('/pengembalian/{id}', [PengembalianController::class, 'update']);
Route::delete('/pengembalian/{id}', [PengembalianController::class, 'destroy']);

//Laporan
Route::get('/laporan', [LaporanController::class, 'generateReport']);


// LOGOUT (opsional)
Route::post('/logout', [AuthController::class, 'logout']);
