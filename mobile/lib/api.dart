import 'dart:convert';

import 'package:http/http.dart' as http;

// IPv4 laptop (hasil ipconfig). Kalau IP berubah, ganti di sini.
const String baseUrl = 'http://10.201.182.131:3000/api/users';

// Error dari API: berisi pesan untuk user dan kode status
// (status null kalau server tidak terjangkau)
class ApiException implements Exception {
  final String message;
  final int? status;
  const ApiException(this.message, [this.status]);

  @override
  String toString() => message;
}

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
      final Future<http.Response> call;
      if (method == 'POST') {
        call = http.post(uri, headers: headers, body: jsonEncode(body));
      } else if (method == 'PATCH') {
        call = http.patch(uri, headers: headers, body: jsonEncode(body));
      } else if (method == 'DELETE') {
        call = http.delete(uri, headers: headers);
      } else {
        call = http.get(uri, headers: headers);
      }
      res = await call.timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const ApiException('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}

    if (res.statusCode >= 400 || data['error'] != null) {
      final plain = res.body.trim();
      final isPlainText =
          plain.isNotEmpty && !plain.startsWith('{') && plain.length < 200;
      throw ApiException(
        data['error']?.toString() ??
            (isPlainText ? plain : 'Input tidak valid atau terjadi kesalahan'),
        res.statusCode,
      );
    }
    return data;
  }
}
