<?php

namespace App\Http\Controllers;

use App\Models\Barang;
use App\Models\Kategori;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB; // ← Tambahkan ini

class BarangController extends Controller
{
    public function index()
    {
        $barangs = Barang::with('kategori')->get();
        return response()->json($barangs);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'kode_Barang' => 'required|string|max:255|unique:barang,kode_Barang',
            'nama_Barang' => 'required|string|max:255',
            'id_kategori' => 'required|exists:kategori,id_kategori',
            'jumlah' => 'required|integer|min:0',
            'satuan' => 'required|string|max:50'
        ]);

        $barang = Barang::create($validated);

        return response()->json([
            'message' => 'Barang berhasil ditambahkan',
            'data' => $barang
        ], 201);
    }

    public function show($id)
    {
        $barang = Barang::with('kategori')->findOrFail($id);
        return response()->json($barang);
    }

    public function update(Request $request, $id)
    {
        $validated = $request->validate([
            'kode_Barang' => 'sometimes|required|string|max:255|unique:barang,kode_Barang,' . $id . ',id_barang',
            'nama_Barang' => 'sometimes|required|string|max:255',
            'id_kategori' => 'sometimes|required|exists:kategori,id_kategori',
            'jumlah' => 'sometimes|required|integer|min:0',
            'satuan' => 'sometimes|required|string|max:50'
        ]);

        $barang = Barang::findOrFail($id);
        $barang->update($validated);
        return response()->json($barang);
    }

    public function destroy($id)
    {
        // Hapus dulu data relasi dari barang_popularity
        DB::table('barang')->where('id_barang', $id)->delete();

        // Lalu hapus barang utama
        $barang = Barang::where('id_barang', $id)->first();
        if (!$barang) {
            return response()->json(['message' => 'Barang tidak ditemukan'], 404);
        }

        $barang->delete();

        return response()->json(['message' => 'Barang berhasil dihapus'], 200);
    }
}
