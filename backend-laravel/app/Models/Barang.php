<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Barang extends Model
{
    use HasFactory;

    protected $table = 'barang';
    protected $primaryKey = 'id_barang';
    protected $fillable = [
        'kode_Barang',
        'nama_Barang',
        'id_kategori',
        'jumlah',
        'satuan'
    ];

    public function kategori()
{
    return $this->belongsTo(Kategori::class, 'id_kategori', 'id_kategori');
}


    public function peminjaman()
    {
        return $this->hasMany(Peminjaman::class, 'id_barang');
    }
}