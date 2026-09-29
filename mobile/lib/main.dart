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
    debugShowCheckedModeBanner: false,
    themeMode: ThemeMode.system,
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    darkTheme: ThemeData(
      colorSchemeSeed: Colors.indigo,
      brightness: Brightness.dark,
      useMaterial3: true,
    ),
    home: const Gate(),
  );
}

// Gaya kolom isian yang dipakai berulang
InputDecoration inputDeco(String label, IconData icon, {Widget? suffix}) =>
    InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );

// Pesan singkat di bawah layar
void showSnack(ScaffoldMessengerState messenger, String text) {
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
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
      if (!mounted) return;
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
  bool hidePass = true;
  String message = '';
  bool ok = false;

  @override
  void dispose() {
    nameC.dispose();
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final messenger = ScaffoldMessenger.of(context);
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
        showSnack(messenger, 'Berhasil login');
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
        if (!mounted) return;
        setState(() {
          isLogin = true;
          ok = true;
          message = 'Daftar berhasil, silakan login';
          passC.clear();
        });
        showSnack(messenger, 'Daftar berhasil');
      }
    } catch (e) {
      if (!mounted) return;
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: cs.primaryContainer,
                    child: Icon(
                      isLogin ? Icons.lock_outline : Icons.person_add_alt_1,
                      size: 38,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isLogin ? 'Selamat datang' : 'Buat akun baru',
                    style: tt.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLogin
                        ? 'Masuk untuk melanjutkan'
                        : 'Isi data di bawah untuk mendaftar',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          if (message.isNotEmpty)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ok
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    ok
                                        ? Icons.check_circle_outline
                                        : Icons.error_outline,
                                    color: ok
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      message,
                                      style: TextStyle(
                                        color: ok
                                            ? Colors.green.shade900
                                            : Colors.red.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (!isLogin) ...[
                            TextField(
                              controller: nameC,
                              textInputAction: TextInputAction.next,
                              decoration: inputDeco(
                                'Nama',
                                Icons.person_outline,
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextField(
                            controller: emailC,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: inputDeco('Email', Icons.mail_outline),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: passC,
                            obscureText: hidePass,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              if (!loading) submit();
                            },
                            decoration: inputDeco(
                              'Password',
                              Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(
                                  hidePass
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () =>
                                    setState(() => hidePass = !hidePass),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed: loading ? null : submit,
                              child: loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(isLogin ? 'Masuk' : 'Daftar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() {
                      isLogin = !isLogin;
                      message = '';
                    }),
                    child: Text(
                      isLogin
                          ? 'Belum punya akun? Daftar'
                          : 'Sudah punya akun? Login',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
      if (!mounted) return;
      setState(() {
        name = res['data']['name'];
        email = res['data']['email'];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e.toString().startsWith('Tidak bisa terhubung')) {
        // server tidak terjangkau: jangan paksa logout, cukup beri tahu
        setState(() => loading = false);
        showSnack(ScaffoldMessenger.of(context), e.toString());
      } else {
        // token tidak valid lagi -> kembali ke login
        await clearToken();
        widget.onLoggedOut();
      }
    }
  }

  Future<void> logout() async {
    final messenger = ScaffoldMessenger.of(context);
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Kamu harus login lagi untuk masuk ke akunmu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (yakin != true) return;
    try {
      await Api.request('DELETE', '/logout', token: widget.token);
    } catch (_) {}
    await clearToken();
    widget.onLoggedOut();
    showSnack(messenger, 'Berhasil logout');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                        initial,
                        style: tt.displayMedium?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      name,
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: const Text('Nama'),
                          subtitle: Text(name),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.mail_outline),
                          title: const Text('Email'),
                          subtitle: Text(email),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Tarik ke bawah untuk memuat ulang',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
