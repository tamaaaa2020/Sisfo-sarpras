<?php

namespace App\Http\Controllers;

use App\Models\Barang;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

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
            'satuan' => 'required|string|max:50',
            'gambar_barang' => 'nullable|image|mimes:jpg,jpeg,png|max:2048'
        ]);

        if ($request->hasFile('gambar_barang')) {
            $validated['gambar_barang'] = $request->file('gambar_barang')->store('uploads/barang', 'public');
        }

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
        $barang = Barang::findOrFail($id);

        $validated = $request->validate([
            'kode_Barang' => 'sometimes|required|string|max:255|unique:barang,kode_Barang,' . $id . ',id_barang',
            'nama_Barang' => 'sometimes|required|string|max:255',
            'id_kategori' => 'sometimes|required|exists:kategori,id_kategori',
            'jumlah' => 'sometimes|required|integer|min:0',
            'satuan' => 'sometimes|required|string|max:50',
            'gambar_barang' => 'nullable|image|mimes:jpg,jpeg,png|max:2048'
        ]);

        if ($request->hasFile('gambar_barang')) {
            // Hapus gambar lama jika ada
            if ($barang->gambar_barang && Storage::disk('public')->exists($barang->gambar_barang)) {
                Storage::disk('public')->delete($barang->gambar_barang);
            }

            $validated['gambar_barang'] = $request->file('gambar_barang')->store('uploads/barang', 'public');
        }

        $barang->update($validated);

        return response()->json([
            'message' => 'Barang berhasil diperbarui',
            'data' => $barang
        ]);
    }

    public function destroy($id)
    {
        $barang = Barang::find($id);

        if (!$barang) {
            return response()->json(['message' => 'Barang tidak ditemukan'], 404);
        }

        // Hapus gambar jika ada
        if ($barang->gambar_barang && Storage::disk('public')->exists($barang->gambar_barang)) {
            Storage::disk('public')->delete($barang->gambar_barang);
        }

        $barang->delete();

        return response()->json(['message' => 'Barang berhasil dihapus'], 200);
    }
}
