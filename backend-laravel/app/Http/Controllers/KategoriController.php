<?php

namespace App\Http\Controllers;

use App\Models\Kategori;
use Illuminate\Http\Request;

class KategoriController extends Controller
{
    public function index()
    {
        $kategoris = Kategori::all();
        return response()->json($kategoris);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name_Kategori' => 'required|string|max:255'
        ]);

        $kategori = Kategori::create($validated);
        return response()->json($kategori, 201);
    }

    public function show($id)
    {
        $kategori = Kategori::findOrFail($id);
        return response()->json($kategori);
    }

    public function update(Request $request, $id)
    {
        $validated = $request->validate([
            'name_Kategori' => 'required|string|max:255'
        ]);

        $kategori = Kategori::findOrFail($id);
        $kategori->update($validated);
        return response()->json($kategori);
    }

    public function destroy($id)
    {
        Kategori::findOrFail($id)->delete();
        return response()->json(['message' => 'Kategori deleted successfully']);
    }
}