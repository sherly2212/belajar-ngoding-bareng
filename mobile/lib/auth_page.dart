import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'helpers.dart';

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
