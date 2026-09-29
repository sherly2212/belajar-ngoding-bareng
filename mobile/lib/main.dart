import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// IPv4 laptop (hasil ipconfig). Kalau IP berubah, ganti di sini.
const String baseUrl = 'http://10.13.46.147:3000/api/users';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Belajar Ngoding',
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    home: const Gate(),
  );
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

// Penentu tampilan: sudah punya token -> Profil, belum -> Login/Daftar
class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  String? token;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      setState(() {
        token = p.getString('token');
        loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (token == null) {
      return AuthPage(onLoggedIn: (t) => setState(() => token = t));
    }
    return ProfilePage(
      token: token!,
      onLoggedOut: () => setState(() => token = null),
    );
  }
}

class AuthPage extends StatefulWidget {
  final void Function(String token) onLoggedIn;
  const AuthPage({super.key, required this.onLoggedIn});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool isLogin = true;
  bool loading = false;
  String message = '';
  bool ok = false;

  Future<void> submit() async {
    setState(() {
      loading = true;
      message = '';
    });
    try {
      if (isLogin) {
        final res = await Api.request(
          'POST',
          '/login',
          body: {'email': emailC.text, 'password': passC.text},
        );
        final token = res['data'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        widget.onLoggedIn(token);
      } else {
        await Api.request(
          'POST',
          '',
          body: {
            'name': nameC.text,
            'email': emailC.text,
            'password': passC.text,
          },
        );
        setState(() {
          isLogin = true;
          ok = true;
          message = 'Daftar berhasil, silakan login';
          passC.clear();
        });
      }
    } catch (e) {
      setState(() {
        ok = false;
        message = e.toString();
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Belajar Ngoding')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            isLogin ? 'Login' : 'Daftar',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          if (message.isNotEmpty)
            Text(
              message,
              style: TextStyle(color: ok ? Colors.green : Colors.red),
            ),
          const SizedBox(height: 12),
          if (!isLogin) ...[
            TextField(
              controller: nameC,
              decoration: const InputDecoration(
                labelText: 'Nama',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: emailC,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passC,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: loading ? null : submit,
            child: Text(
              loading ? 'Memproses...' : (isLogin ? 'Masuk' : 'Daftar'),
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              isLogin = !isLogin;
              message = '';
            }),
            child: Text(
              isLogin ? 'Belum punya akun? Daftar' : 'Sudah punya akun? Login',
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  final String token;
  final VoidCallback onLoggedOut;
  const ProfilePage({
    super.key,
    required this.token,
    required this.onLoggedOut,
  });
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = '';
  String email = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<void> load() async {
    try {
      final res = await Api.request('GET', '/current', token: widget.token);
      setState(() {
        name = res['data']['name'];
        email = res['data']['email'];
        loading = false;
      });
    } catch (_) {
      // token tidak valid lagi -> kembali ke login
      await clearToken();
      widget.onLoggedOut();
    }
  }

  Future<void> logout() async {
    try {
      await Api.request('DELETE', '/logout', token: widget.token);
    } catch (_) {}
    await clearToken();
    widget.onLoggedOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil kamu')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nama: $name',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Email: $email',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: logout, child: const Text('Logout')),
                ],
              ),
            ),
    );
  }
}
