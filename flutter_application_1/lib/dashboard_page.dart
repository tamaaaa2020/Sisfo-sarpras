import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? _userName;
  bool _isLoadingUser = true;

  List<dynamic> barangList = [];
  List<dynamic> kategoriList = [];
  List<dynamic> peminjamanList = [];

  bool _isLoadingBarang = false;
  bool _isLoadingPeminjaman = false;

  bool _isSubmitting = false;
  bool _isSubmittingReturn = false;

  // Untuk search dan form peminjaman
  String search = '';
  String? selectedBarangNama;
  int jumlahPinjam = 1;
  DateTime? tanggalPinjam = DateTime.now();

  // Form pengembalian
  String? selectedPeminjaman;
  DateTime? tanggalKembali = DateTime.now();
  String kondisiBarang = 'baik';

  final formKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchBarang();
    _fetchKategori();
    _fetchPeminjaman();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson != null) {
      final userMap = jsonDecode(userJson);
      setState(() {
        _userName = userMap['name'] ?? 'User';
        _isLoadingUser = false;
      });
    } else {
      _logout();
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> _fetchBarang() async {
    setState(() {
      _isLoadingBarang = true;
    });

    final token = await _getToken();
    if (token == null) {
      _logout();
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/barang'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          barangList = data is List
              ? data
              : (data['data'] is List ? data['data'] : []);
        });
      } else {
        print('Gagal fetch barang: ${res.body}');
      }
    } catch (e) {
      print('Exception fetch barang: $e');
    } finally {
      setState(() {
        _isLoadingBarang = false;
      });
    }
  }

  Future<void> _fetchKategori() async {
    final token = await _getToken();
    if (token == null) {
      _logout();
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/kategori'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          kategoriList = data is List
              ? data
              : (data['data'] is List ? data['data'] : []);
        });
      } else {
        print('Gagal fetch kategori: ${res.body}');
      }
    } catch (e) {
      print('Exception fetch kategori: $e');
    }
  }

  Future<void> _fetchPeminjaman() async {
    setState(() {
      _isLoadingPeminjaman = true;
    });

    final token = await _getToken();
    final userId = await _getUserId();

    if (token == null || userId == null) {
      _logout();
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/peminjaman'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List<dynamic> allPeminjaman =
            data is List ? data : (data['data'] is List ? data['data'] : []);
        final userPeminjaman = allPeminjaman.where((p) =>
            p['id_user'].toString() == userId.toString() &&
            p['status'] == 'pinjam').toList();

        setState(() {
          peminjamanList = userPeminjaman;
        });
      } else {
        print('Gagal fetch peminjaman: ${res.body}');
      }
    } catch (e) {
      print('Exception fetch peminjaman: $e');
    } finally {
      setState(() {
        _isLoadingPeminjaman = false;
      });
    }
  }

  Future<void> _handlePeminjaman() async {
    if (selectedBarangNama == null ||
        selectedBarangNama!.isEmpty ||
        jumlahPinjam < 1 ||
        tanggalPinjam == null) {
      _showSnackBar('Pastikan semua data sudah terisi dengan benar!');
      return;
    }

    final selectedBarang = barangList.firstWhere(
      (barang) => barang['nama_Barang'] == selectedBarangNama,
      orElse: () => null,
    );

    if (selectedBarang == null) {
      _showSnackBar('Barang tidak ditemukan.');
      return;
    }

    final userId = await _getUserId();
    if (userId == null) {
      _showSnackBar('User ID tidak ditemukan.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final token = await _getToken();
    if (token == null) {
      _logout();
      return;
    }

    try {
      final res = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/peminjaman'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_user': userId,
          'id_barang': selectedBarang['id_barang'],
          'jumlah': jumlahPinjam,
          'tanggal_pinjam': tanggalPinjam!.toIso8601String().split('T').first,
        }),
      );

      final result = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnackBar('Menunggu konfirmasi Admin!');
        await _fetchBarang();
        setState(() {
          selectedBarangNama = null;
          jumlahPinjam = 1;
          tanggalPinjam = DateTime.now();
        });
      } else {
        _showSnackBar(result['message'] ?? 'Gagal meminjam barang.');
        print('API Error: $result');
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan saat meminjam barang.');
      print('Exception peminjaman: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _handlePengembalian() async {
    if (selectedPeminjaman == null ||
        selectedPeminjaman!.isEmpty ||
        tanggalKembali == null ||
        kondisiBarang.isEmpty) {
      _showSnackBar('Pastikan semua data pengembalian sudah terisi!');
      return;
    }

    setState(() {
      _isSubmittingReturn = true;
    });

    final token = await _getToken();
    if (token == null) {
      _logout();
      return;
    }

    try {
      final res = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/pengembalian'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_peminjaman': selectedPeminjaman,
          'tanggal_kembali': tanggalKembali!.toIso8601String().split('T').first,
          'kondisi': kondisiBarang,
        }),
      );

      final result = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnackBar('Pengembalian berhasil diproses!');
        await _fetchPeminjaman();
        await _fetchBarang();
        setState(() {
          selectedPeminjaman = null;
          tanggalKembali = DateTime.now();
          kondisiBarang = 'baik';
        });
      } else {
        _showSnackBar(result['message'] ?? 'Gagal mengembalikan barang.');
        print('API Error: $result');
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan saat mengembalikan barang.');
      print('Exception pengembalian: $e');
    } finally {
      setState(() {
        _isSubmittingReturn = false;
      });
    }
  }

  void _showSnackBar(String message) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.blue.shade800,
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  List<dynamic> get filteredBarangList {
    if (search.isEmpty) return barangList;
    return barangList
        .where((item) =>
            (item['nama_Barang'] as String)
                .toLowerCase()
                .contains(search.toLowerCase()))
        .toList();
  }

  String _getKategoriName(int idKategori) {
    final kategori = kategoriList.firstWhere(
        (k) => k['id_kategori'] == idKategori,
        orElse: () => null);
    if (kategori != null) return kategori['name_Kategori'] ?? 'Tidak Diketahui';
    return 'Tidak Diketahui';
  }

  String _getPeminjamanDetail(String idPeminjaman) {
    final peminjaman = peminjamanList.firstWhere(
      (p) => p['id_peminjaman'].toString() == idPeminjaman,
      orElse: () => null,
    );
    if (peminjaman == null) return "Tidak ditemukan";

    final barang = barangList.firstWhere(
      (b) => b['id_barang'] == peminjaman['id_barang'],
      orElse: () => null,
    );

    final namaBarang = barang != null ? barang['nama_Barang'] ?? 'Unknown' : 'Unknown';
    final jumlah = peminjaman['jumlah'] ?? 0;

    return "$namaBarang ($jumlah unit)";
  }

  void _selectTanggalPinjam() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: tanggalPinjam ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade800,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != tanggalPinjam) {
      setState(() {
        tanggalPinjam = picked;
      });
    }
  }

  void _selectTanggalKembali() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: tanggalKembali ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.blue.shade800,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null && picked != tanggalKembali) {
      setState(() {
        tanggalKembali = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        title: Text(
          'Dashboard User',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoadingUser
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchBarang();
                await _fetchKategori();
                await _fetchPeminjaman();
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with greeting and search
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade800,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(20, 10, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat datang,',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            _userName ?? 'User',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 15),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Cari barang...',
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.search, color: Colors.blue.shade800),
                                prefixIconConstraints: BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  search = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Daftar Barang Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Daftar Barang',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),

                    // List Barang
                    _isLoadingBarang
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : filteredBarangList.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.inventory_2_outlined,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Tidak ada data barang.',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: filteredBarangList.length,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemBuilder: (context, index) {
                                  final barang = filteredBarangList[index];
                                  return Card(
                                    margin: EdgeInsets.only(bottom: 12),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blue.shade100,
                                        child: Text(
                                          barang['nama_Barang']?.substring(0, 1).toUpperCase() ?? 'B',
                                          style: TextStyle(
                                            color: Colors.blue.shade800,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        barang['nama_Barang'] ?? '-',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Icon(Icons.qr_code, size: 14, color: Colors.grey),
                                              SizedBox(width: 5),
                                              Text('Kode: ${barang['kode_Barang'] ?? '-'}'),
                                            ],
                                          ),
                                          SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Icon(Icons.category, size: 14, color: Colors.grey),
                                              SizedBox(width: 5),
                                              Text('${_getKategoriName(barang['id_kategori'] ?? 0)}'),
                                            ],
                                          ),
                                          SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Icon(Icons.inventory, size: 14, color: Colors.grey),
                                              SizedBox(width: 5),
                                              Text('Tersedia: ${barang['jumlah'] ?? '0'} unit'),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.shopping_cart_outlined, color: Colors.blue.shade800),
                                        onPressed: () {
                                          setState(() {
                                            selectedBarangNama = barang['nama_Barang'];
                                          });

                                          // Scroll to form peminjaman
                                          Scrollable.ensureVisible(
                                            formKey.currentContext!,
                                            duration: Duration(milliseconds: 500),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),

                    SizedBox(height: 30),

                    // Form Peminjaman
                    Container(
                      key: formKey,
                      padding: EdgeInsets.all(20),
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.edit_document,
                                color: Colors.blue.shade800,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Form Peminjaman',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 30),
                          SizedBox(height: 5),

                          // Dropdown Barang
                          Text(
                            'Pilih Barang',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 15),
                                border: InputBorder.none,
                                hintText: 'Pilih barang yang akan dipinjam',
                              ),
                              items: barangList
                                  .map<DropdownMenuItem<String>>((barang) =>
                                      DropdownMenuItem<String>(
                                          value: barang['nama_Barang'],
                                          child: Text(barang['nama_Barang'] ?? '-')))
                                  .toList(),
                              value: selectedBarangNama,
                              onChanged: (val) {
                                setState(() {
                                  selectedBarangNama = val;
                                });
                              },
                              isExpanded: true,
                              icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue.shade800),
                            ),
                          ),
                          SizedBox(height: 20),

                          // Jumlah Barang
                          Text(
                            'Jumlah Pinjam',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline, color: Colors.blue.shade800),
                                  onPressed: () {
                                    if (jumlahPinjam > 1) {
                                      setState(() {
                                        jumlahPinjam--;
                                      });
                                    }
                                  },
                                ),
                                Expanded(
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    initialValue: jumlahPinjam.toString(),
                                    onChanged: (val) {
                                      final n = int.tryParse(val);
                                      if (n != null && n > 0) {
                                        setState(() {
                                          jumlahPinjam = n;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add_circle_outline, color: Colors.blue.shade800),
                                  onPressed: () {
                                    setState(() {
                                      jumlahPinjam++;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),

                          // Tanggal Pinjam
                          Text(
                            'Tanggal Pinjam',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          SizedBox(height: 8),
                          GestureDetector(
                            onTap: _selectTanggalPinjam,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.blue.shade800),
                                  SizedBox(width: 10),
                                  Text(
                                    tanggalPinjam != null
                                        ? DateFormat('dd MMMM yyyy').format(tanggalPinjam!)
                                        : 'Pilih tanggal',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Spacer(),
                                  Icon(Icons.arrow_drop_down, color: Colors.blue.shade800),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 30),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _handlePeminjaman,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade800,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                              child: _isSubmitting
                                  ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.shopping_cart),
                                        SizedBox(width: 10),
                                        Text(
                                          'Ajukan Peminjaman',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form Pengembalian
                    Container(
                      padding: EdgeInsets.all(20),
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.assignment_return, color: Colors.blue.shade800),
                              SizedBox(width: 10),
                              Text(
                                'Form Pengembalian',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 30),
                          SizedBox(height: 5),

                          _isLoadingPeminjaman
                              ? Center(child: CircularProgressIndicator())
                              : peminjamanList.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Tidak ada barang yang sedang dipinjam.',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Dropdown pilih peminjaman
                                        Text(
                                          'Pilih Peminjaman',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              color: Colors.blue.shade900),
                                        ),
                                        SizedBox(height: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: DropdownButtonFormField<String>(
                                            decoration: InputDecoration(
                                              contentPadding: EdgeInsets.symmetric(horizontal: 15),
                                              border: InputBorder.none,
                                              hintText: 'Pilih peminjaman yang akan dikembalikan',
                                            ),
                                            items: peminjamanList
                                                .map<DropdownMenuItem<String>>((peminjaman) =>
                                                    DropdownMenuItem<String>(
                                                      value: peminjaman['id_peminjaman'].toString(),
                                                      child: Text(_getPeminjamanDetail(peminjaman['id_peminjaman'].toString())),
                                                    ))
                                                .toList(),
                                            value: selectedPeminjaman,
                                            onChanged: (val) {
                                              setState(() {
                                                selectedPeminjaman = val;
                                              });
                                            },
                                            isExpanded: true,
                                            icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue.shade800),
                                          ),
                                        ),
                                        SizedBox(height: 20),

                                        // Tanggal Kembali
                                        Text(
                                          'Tanggal Kembali',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              color: Colors.blue.shade900),
                                        ),
                                        SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: _selectTanggalKembali,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.calendar_today, color: Colors.blue.shade800),
                                                SizedBox(width: 10),
                                                Text(
                                                  tanggalKembali != null
                                                      ? DateFormat('dd MMMM yyyy').format(tanggalKembali!)
                                                      : 'Pilih tanggal',
                                                  style: TextStyle(fontSize: 16),
                                                ),
                                                Spacer(),
                                                Icon(Icons.arrow_drop_down, color: Colors.blue.shade800),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 20),

                                        // Kondisi Barang
                                        Text(
                                          'Kondisi Barang',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              color: Colors.blue.shade900),
                                        ),
                                        SizedBox(height: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: DropdownButtonFormField<String>(
                                            decoration: InputDecoration(
                                              contentPadding: EdgeInsets.symmetric(horizontal: 15),
                                              border: InputBorder.none,
                                            ),
                                            items: [
                                              DropdownMenuItem(value: 'baik', child: Text('Baik')),
                                              DropdownMenuItem(value: 'rusak ringan', child: Text('Rusak Ringan')),
                                              DropdownMenuItem(value: 'rusak berat', child: Text('Rusak Berat')),
                                              DropdownMenuItem(value: 'hilang', child: Text('Hilang')),
                                            ],
                                            value: kondisiBarang,
                                            onChanged: (val) {
                                              setState(() {
                                                kondisiBarang = val ?? 'baik';
                                              });
                                            },
                                            isExpanded: true,
                                            icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue.shade800),
                                          ),
                                        ),
                                        SizedBox(height: 30),

                                        // Submit Button
                                        SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: ElevatedButton(
                                            onPressed: _isSubmittingReturn ? null : _handlePengembalian,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue.shade800,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              elevation: 2,
                                            ),
                                            child: _isSubmittingReturn
                                                ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                                : Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.assignment_return),
                                                      SizedBox(width: 10),
                                                      Text(
                                                        'Kembalikan Barang',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                        ],
                      ),
                    ),

                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}
