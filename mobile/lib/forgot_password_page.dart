import 'package:flutter/material.dart';

import 'api.dart';
import 'helpers.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordPage({super.key, this.initialEmail = ''});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final TextEditingController emailC;
  final codeC = TextEditingController();
  final passC = TextEditingController();
  bool codeSent = false;
  bool loading = false;
  bool hidePass = true;
  String message = '';
  bool ok = false;

  @override
  void initState() {
    super.initState();
    emailC = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    emailC.dispose();
    codeC.dispose();
    passC.dispose();
    super.dispose();
  }

  void showError(String text) {
    setState(() {
      ok = false;
      message = text;
    });
  }

  Future<void> sendCode() async {
    final email = emailC.text.trim();
    if (email.isEmpty) {
      showError('Email tidak boleh kosong');
      return;
    }
    setState(() {
      loading = true;
      message = '';
    });
    try {
      await Api.request('POST', '/forgot-password', body: {'email': email});
      if (!mounted) return;
      setState(() {
        codeSent = true;
        ok = true;
        message = 'Jika email terdaftar, kode 6 angka sudah dikirim. Cek inbox dan folder Spam.';
      });
    } catch (e) {
      if (!mounted) return;
      showError(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resetPassword() async {
    final code = codeC.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      showError('Kode harus 6 angka');
      return;
    }
    if (passC.text.length < 6) {
      showError('Password baru minimal 6 karakter');
      return;
    }
    setState(() {
      loading = true;
      message = '';
    });
    try {
      await Api.request(
        'POST',
        '/reset-password',
        body: {
          'email': emailC.text.trim(),
          'code': code,
          'newPassword': passC.text,
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showError(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Lupa password')),
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
                      codeSent
                          ? Icons.mark_email_read_outlined
                          : Icons.lock_reset,
                      size: 38,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    codeSent ? 'Masukkan kode' : 'Reset password',
                    style: tt.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    codeSent
                        ? 'Kode 6 angka dikirim ke emailmu'
                        : 'Kami kirim kode reset ke emailmu',
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
                          TextField(
                            controller: emailC,
                            enabled: !codeSent,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              if (!loading && !codeSent) sendCode();
                            },
                            decoration: inputDeco('Email', Icons.mail_outline),
                          ),
                          if (codeSent) ...[
                            const SizedBox(height: 14),
                            TextField(
                              controller: codeC,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textInputAction: TextInputAction.next,
                              decoration: inputDeco(
                                'Kode 6 angka',
                                Icons.pin_outlined,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: passC,
                              obscureText: hidePass,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) {
                                if (!loading) resetPassword();
                              },
                              decoration: inputDeco(
                                'Password baru',
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
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed: loading
                                  ? null
                                  : (codeSent ? resetPassword : sendCode),
                              child: loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      codeSent
                                          ? 'Simpan password'
                                          : 'Kirim kode',
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (codeSent)
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => setState(() {
                              codeSent = false;
                              message = '';
                              codeC.clear();
                              passC.clear();
                            }),
                      child: const Text('Ganti email / kirim ulang kode'),
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
