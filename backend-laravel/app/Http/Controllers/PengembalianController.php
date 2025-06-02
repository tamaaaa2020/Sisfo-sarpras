<?php

namespace App\Http\Controllers;

use App\Models\Pengembalian;
use App\Models\Peminjaman;
use Illuminate\Http\Request;

class PengembalianController extends Controller
{
    public function index()
    {
        $pengembalians = Pengembalian::with(['peminjaman.user', 'peminjaman.barang'])->get();
        return response()->json($pengembalians);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'id_peminjaman' => 'required|exists:peminjaman,id_peminjaman',
            'tanggal_kembali' => 'required|date',
            'kondisi' => 'required|string|max:255'
        ]);

        // Update peminjaman status
        $peminjaman = Peminjaman::findOrFail($validated['id_peminjaman']);
        $peminjaman->status = 'kembali';
        $peminjaman->save();

        // Return items to stock
        $barang = $peminjaman->barang;
        $barang->jumlah += $peminjaman->jumlah;
        $barang->save();

        $pengembalian = Pengembalian::create($validated);
        return response()->json($pengembalian, 201);
    }

    public function show($id)
    {
        $pengembalian = Pengembalian::with(['peminjaman.user', 'peminjaman.barang'])->findOrFail($id);
        return response()->json($pengembalian);
    }

    public function update(Request $request, $id)
    {
        $validated = $request->validate([
            'id_peminjaman' => 'sometimes|required|exists:peminjaman,id_peminjaman',
            'tanggal_kembali' => 'sometimes|required|date',
            'kondisi' => 'sometimes|required|string|max:255'
        ]);

        $pengembalian = Pengembalian::findOrFail($id);
        $pengembalian->update($validated);
        return response()->json($pengembalian);
    }

    public function destroy($id)
    {
        Pengembalian::findOrFail($id)->delete();
        return response()->json(['message' => 'Pengembalian deleted successfully']);
    }
}