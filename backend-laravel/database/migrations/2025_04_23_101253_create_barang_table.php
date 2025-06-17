<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('barang', function (Blueprint $table) {
            $table->id('id_barang');
            $table->string('kode_Barang');
            $table->string('nama_Barang');
            $table->unsignedBigInteger('id_kategori');
            $table->integer('jumlah');
            $table->string('satuan');
            $table->string('gambar_barang');
            $table->timestamps();

            $table->foreign('id_kategori')
                  ->references('id_kategori')
                  ->on('kategori')
                  ->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('barang');
    }
};