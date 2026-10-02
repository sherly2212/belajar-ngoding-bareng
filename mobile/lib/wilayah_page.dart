// mobile/lib/wilayah_page.dart
// Halaman: daftar kab/kota Sumbar dari API publik
// + tarik ke bawah untuk memuat ulang

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Bentuk satu data (sesuai JSON dari API)
class Wilayah {
  final String id;
  final String nama;

  Wilayah({required this.id, required this.nama});

  factory Wilayah.fromJson(Map<String, dynamic> json) {
    return Wilayah(id: json['id'] as String, nama: json['name'] as String);
  }
}

// Fungsi yang memanggil API
Future<List<Wilayah>> ambilWilayah() async {
  final res = await http.get(
    Uri.parse(
      'https://www.emsifa.com/api-wilayah-indonesia/api/regencies/13.json',
    ),
  );

  if (res.statusCode != 200) {
    throw Exception('Gagal memuat data (HTTP ${res.statusCode})');
  }

  final List<dynamic> data = jsonDecode(res.body);
  return data.map((e) => Wilayah.fromJson(e as Map<String, dynamic>)).toList();
}

class WilayahPage extends StatefulWidget {
  const WilayahPage({super.key});

  @override
  State<WilayahPage> createState() => _WilayahPageState();
}

class _WilayahPageState extends State<WilayahPage> {
  List<Wilayah> _data = [];
  bool _loading = true; // loading pertama kali (layar penuh)
  String _error = '';
  DateTime? _terakhir; // kapan "foto" terakhir diambil
  String _kataKunci = '';

  @override
  void initState() {
    super.initState();
    _muat();
  }

  // Ambil data dari API. Kalau gagal, data lama tetap dipertahankan.
  Future<void> _muat() async {
    try {
      final hasil = await ambilWilayah();
      if (!mounted) return;
      setState(() {
        _data = hasil;
        _error = '';
        _loading = false;
        _terakhir = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      // Kalau sudah ada data lama, cukup beri tahu lewat snackbar
      if (_data.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui, menampilkan data lama'),
          ),
        );
      }
    }
  }

  String _jam(DateTime t) {
    String dua(int n) => n.toString().padLeft(2, '0');
    return '${dua(t.hour)}:${dua(t.minute)}:${dua(t.second)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kab/Kota Sumatera Barat')),
      body: _buatIsi(),
    );
  }

  Widget _buatIsi() {
    // 1. Loading pertama kali
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Gagal dan belum punya data sama sekali
    if (_error.isNotEmpty && _data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Terjadi masalah:\n$_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() => _loading = true);
                  _muat();
                },
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Ada data: saring sesuai kolom cari
    final tampil = _data
        .where((w) => w.nama.toLowerCase().contains(_kataKunci.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari kab/kota...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) => setState(() => _kataKunci = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Menampilkan ${tampil.length} dari ${_data.length}\n'
              'Terakhir diperbarui: ${_terakhir == null ? '-' : _jam(_terakhir!)}',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _muat, // dipanggil saat layar ditarik ke bawah
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: tampil.length,
              itemBuilder: (context, i) {
                final w = tampil[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(w.id.substring(2))),
                    title: Text(w.nama),
                    subtitle: Text('Kode: ${w.id}'),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
