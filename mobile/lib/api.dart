import 'dart:convert';

import 'package:http/http.dart' as http;

// IPv4 laptop (hasil ipconfig). Kalau IP berubah, ganti di sini.
const String baseUrl = 'http://192.168.1.40:3000/api/users';

// Fungsi bantu memanggil API (setara fungsi api() di app.js)
class Api {
  static Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    http.Response res;
    try {
      if (method == 'POST') {
        res = await http.post(uri, headers: headers, body: jsonEncode(body));
      } else if (method == 'DELETE') {
        res = await http.delete(uri, headers: headers);
      } else {
        res = await http.get(uri, headers: headers);
      }
    } catch (_) {
      throw 'Tidak bisa terhubung ke server';
    }
    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    if (res.statusCode >= 400 || data['error'] != null) {
      throw data['error']?.toString() ??
          'Input tidak valid atau terjadi kesalahan';
    }
    return data;
  }
}
