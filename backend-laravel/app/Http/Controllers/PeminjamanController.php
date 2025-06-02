<?php

namespace App\Http\Controllers;

use App\Models\Peminjaman;
use App\Models\Barang;
use Illuminate\Http\Request;

class PeminjamanController extends Controller
{
    public function index()
    {
        $peminjamans = Peminjaman::with(['user', 'barang'])->get();
        return response()->json($peminjamans);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'id_user' => 'required|exists:users,id_user',
            'id_barang' => 'required|exists:barang,id_barang',
            'jumlah' => 'required|integer|min:1',
            'tanggal_pinjam' => 'required|date',
        ]);

        $barang = Barang::findOrFail($validated['id_barang']);

        if ($barang->jumlah < $validated['jumlah']) {
            return response()->json(['message' => 'Jumlah barang tidak mencukupi'], 400);
        }

        $peminjaman = Peminjaman::create([
            'id_user' => $validated['id_user'],
            'id_barang' => $validated['id_barang'],
            'jumlah' => $validated['jumlah'],
            'tanggal_pinjam' => $validated['tanggal_pinjam'],
            'status' => 'menunggu', // Status awal
        ]);

        return response()->json($peminjaman, 201);
    }

    public function show($id)
    {
        $peminjaman = Peminjaman::with(['user', 'barang'])->findOrFail($id);
        return response()->json($peminjaman);
    }

    public function update(Request $request, $id)
    {
        $validated = $request->validate([
            'id_user' => 'sometimes|required|exists:users,id_user',
            'id_barang' => 'sometimes|required|exists:barang,id_barang',
            'jumlah' => 'sometimes|required|integer|min:1',
            'tanggal_pinjam' => 'sometimes|required|date',
        ]);

        $peminjaman = Peminjaman::findOrFail($id);
        $peminjaman->update($validated);
        return response()->json($peminjaman);
    }

    public function destroy($id)
    {
        $peminjaman = Peminjaman::findOrFail($id);

        // Tambahkan stok kembali hanya jika status sudah dipinjam
        if ($peminjaman->status === 'pinjam') {
            $barang = Barang::findOrFail($peminjaman->id_barang);
            $barang->jumlah += $peminjaman->jumlah;
            $barang->save();
        }

        $peminjaman->delete();
        return response()->json(['message' => 'Peminjaman berhasil dihapus.']);
    }

    public function approve($id)
    {
        $peminjaman = Peminjaman::findOrFail($id);

        if ($peminjaman->status !== 'menunggu') {
            return response()->json(['message' => 'Peminjaman sudah diproses.'], 400);
        }

        $barang = Barang::findOrFail($peminjaman->id_barang);
        if ($barang->jumlah < $peminjaman->jumlah) {
            return response()->json(['message' => 'Stok barang tidak mencukupi.'], 400);
        }

        $barang->jumlah -= $peminjaman->jumlah;
        $barang->save();

        $peminjaman->status = 'pinjam'; // Status setelah disetujui
        $peminjaman->save();

        return response()->json(['message' => 'Peminjaman disetujui dan barang dikurangi.']);
    }

    public function reject($id)
    {
        $peminjaman = Peminjaman::findOrFail($id);

        if ($peminjaman->status !== 'menunggu') {
            return response()->json(['message' => 'Peminjaman sudah diproses.'], 400);
        }

        $peminjaman->status = 'ditolak';
        $peminjaman->save();

        return response()->json(['message' => 'Peminjaman ditolak.']);
    }
}
