import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'forgot_password_page.dart';
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
  final confirmC = TextEditingController();
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
    confirmC.dispose();
    super.dispose();
  }

  void showError(String text) {
    setState(() {
      ok = false;
      message = text;
    });
  }

  Future<void> submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final email = emailC.text.trim();

    if (isLogin) {
      if (email.isEmpty || passC.text.isEmpty) {
        showError('Email dan password tidak boleh kosong');
        return;
      }
    } else {
      final err =
          validateName(nameC.text) ??
          validateEmail(email) ??
          validatePassword(passC.text) ??
          (confirmC.text != passC.text
              ? 'Konfirmasi password tidak sama'
              : null);
      if (err != null) {
        showError(err);
        return;
      }
    }

    setState(() {
      loading = true;
      message = '';
    });
    try {
      if (isLogin) {
        final res = await Api.request(
          'POST',
          '/login',
          body: {'email': email, 'password': passC.text},
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
            'name': nameC.text.trim(),
            'email': email,
            'password': passC.text,
          },
        );
        if (!mounted) return;
        setState(() {
          isLogin = true;
          ok = true;
          message = 'Daftar berhasil, silakan login';
          passC.clear();
          confirmC.clear();
        });
        showSnack(messenger, 'Daftar berhasil');
      }
    } catch (e) {
      if (!mounted) return;
      showError(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget buildMessageBox() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: message.isEmpty
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ok ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    ok ? Icons.check_circle_outline : Icons.error_outline,
                    color: ok ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: ok ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.primaryContainer, cs.surface],
            stops: const [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [cs.primary, cs.tertiary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Icon(
                          isLogin ? Icons.lock_outline : Icons.person_add_alt_1,
                          key: ValueKey(isLogin),
                          size: 42,
                          color: cs.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      shadowColor: cs.primary.withValues(alpha: 0.25),
                      color: cs.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: AutofillGroup(
                          child: Column(
                            children: [
                              buildMessageBox(),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                child: isLogin
                                    ? const SizedBox(width: double.infinity)
                                    : Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 14,
                                        ),
                                        child: TextField(
                                          controller: nameC,
                                          textInputAction: TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.name,
                                          ],
                                          decoration: inputDeco(
                                            'Nama',
                                            Icons.person_outline,
                                          ),
                                        ),
                                      ),
                              ),
                              TextField(
                                controller: emailC,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                decoration: inputDeco(
                                  'Email',
                                  Icons.mail_outline,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: passC,
                                obscureText: hidePass,
                                textInputAction: isLogin
                                    ? TextInputAction.done
                                    : TextInputAction.next,
                                autofillHints: [
                                  isLogin
                                      ? AutofillHints.password
                                      : AutofillHints.newPassword,
                                ],
                                onSubmitted: (_) {
                                  if (isLogin && !loading) submit();
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
                              AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                child: isLogin
                                    ? const SizedBox(width: double.infinity)
                                    : Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'Minimal 8 karakter, harus ada huruf dan angka',
                                                style: tt.bodySmall?.copyWith(
                                                  color: cs.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          TextField(
                                            controller: confirmC,
                                            obscureText: hidePass,
                                            textInputAction:
                                                TextInputAction.done,
                                            autofillHints: const [
                                              AutofillHints.newPassword,
                                            ],
                                            onSubmitted: (_) {
                                              if (!loading) submit();
                                            },
                                            decoration: inputDeco(
                                              'Konfirmasi password',
                                              Icons.lock_outline,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              if (isLogin)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: loading
                                        ? null
                                        : () async {
                                            final done =
                                                await Navigator.push<bool>(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        ForgotPasswordPage(
                                                          initialEmail:
                                                              emailC.text,
                                                        ),
                                                  ),
                                                );
                                            if (done == true && mounted) {
                                              setState(() {
                                                ok = true;
                                                message = 'Password berhasil diubah, silakan login';
                                                passC.clear();
                                              });
                                            }
                                          },
                                    child: const Text('Lupa password?'),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
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
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() {
                        isLogin = !isLogin;
                        message = '';
                        confirmC.clear();
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
      ),
    );
  }
}
