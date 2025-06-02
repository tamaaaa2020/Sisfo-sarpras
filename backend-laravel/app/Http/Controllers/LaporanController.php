<?php
namespace App\Http\Controllers;

use App\Models\Barang;
use App\Models\Peminjaman;
use App\Models\Pengembalian;
use Illuminate\Http\Request;

class LaporanController extends Controller
{
    public function generateReport()
    {
        // Get the list of all returned items
        $pengembalian = Pengembalian::with(['peminjaman', 'peminjaman.barang'])->get();

        // Get all the peminjaman data
        $peminjaman = Peminjaman::with(['user', 'barang'])->get();

        // Get the most popular items (Barang with the most peminjaman)
        $barangTerpopuler = Barang::withCount('peminjaman')
                                 ->orderBy('peminjaman_count', 'desc')
                                 ->limit(5)
                                 ->get();

        return response()->json([
            'pengembalian' => $pengembalian,
            'peminjaman' => $peminjaman,
            'barang_terpopuler' => $barangTerpopuler
        ]);
    }
}
