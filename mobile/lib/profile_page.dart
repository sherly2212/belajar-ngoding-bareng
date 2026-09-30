import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'helpers.dart';

// Penanda: sesi sudah tidak berlaku (token ditolak server)
class _SessionExpired {
  const _SessionExpired();
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

  Future<void> handleExpired() async {
    await clearToken();
    widget.onLoggedOut();
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
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status == 401) {
        // token tidak valid lagi -> kembali ke login
        await handleExpired();
      } else {
        // server tidak terjangkau: jangan paksa logout, cukup beri tahu
        setState(() => loading = false);
        showSnack(ScaffoldMessenger.of(context), e.message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> editName() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<Object>(
      context: context,
      builder: (_) => _EditNameDialog(token: widget.token, currentName: name),
    );
    if (result is _SessionExpired) {
      await handleExpired();
      return;
    }
    if (result is String && mounted) {
      setState(() => name = result);
      showSnack(messenger, 'Nama berhasil diubah');
    }
  }

  Future<void> changePassword() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<Object>(
      context: context,
      builder: (_) => _ChangePasswordDialog(token: widget.token),
    );
    if (result is _SessionExpired) {
      await handleExpired();
      return;
    }
    if (result == true) {
      showSnack(messenger, 'Password berhasil diubah');
    }
  }

  Future<void> deleteAccount() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<Object>(
      context: context,
      builder: (_) => _DeleteAccountDialog(token: widget.token),
    );
    if (result is _SessionExpired) {
      await handleExpired();
      return;
    }
    if (result == true) {
      await clearToken();
      widget.onLoggedOut();
      showSnack(messenger, 'Akun berhasil dihapus');
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
                  const SizedBox(height: 16),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit_outlined),
                          title: const Text('Ubah nama'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: editName,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.lock_reset),
                          title: const Text('Ubah password'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: changePassword,
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
                  const SizedBox(height: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                    onPressed: deleteAccount,
                    child: const Text('Hapus akun'),
                  ),
                  const SizedBox(height: 8),
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

// ---------- Dialog ubah nama ----------

class _EditNameDialog extends StatefulWidget {
  final String token;
  final String currentName;
  const _EditNameDialog({required this.token, required this.currentName});
  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController nameC = TextEditingController(
    text: widget.currentName,
  );
  bool loading = false;
  String error = '';

  @override
  void dispose() {
    nameC.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final err = validateName(nameC.text);
    if (err != null) {
      setState(() => error = err);
      return;
    }
    setState(() {
      loading = true;
      error = '';
    });
    try {
      final newName = nameC.text.trim();
      await Api.request(
        'PATCH',
        '/current',
        token: widget.token,
        body: {'name': newName},
      );
      if (!mounted) return;
      Navigator.pop(context, newName);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status == 401) {
        Navigator.pop(context, const _SessionExpired());
        return;
      }
      setState(() {
        loading = false;
        error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah nama'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              enabled: !loading,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!loading) save();
              },
              decoration: inputDeco('Nama', Icons.person_outline),
            ),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: loading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: loading ? null : save,
          child: loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

// ---------- Dialog ubah password ----------

class _ChangePasswordDialog extends StatefulWidget {
  final String token;
  const _ChangePasswordDialog({required this.token});
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final oldC = TextEditingController();
  final newC = TextEditingController();
  final confirmC = TextEditingController();
  bool hide = true;
  bool loading = false;
  String error = '';

  @override
  void dispose() {
    oldC.dispose();
    newC.dispose();
    confirmC.dispose();
    super.dispose();
  }

  Future<void> save() async {
    String? err;
    if (oldC.text.isEmpty) {
      err = 'Password lama tidak boleh kosong';
    } else {
      err = validatePassword(newC.text);
    }
    if (err == null && newC.text == oldC.text) {
      err = 'Password baru harus berbeda dari password lama';
    }
    if (err == null && confirmC.text != newC.text) {
      err = 'Konfirmasi password tidak sama';
    }
    if (err != null) {
      setState(() => error = err!);
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });
    try {
      await Api.request(
        'POST',
        '/change-password',
        token: widget.token,
        body: {'oldPassword': oldC.text, 'newPassword': newC.text},
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status == 401) {
        Navigator.pop(context, const _SessionExpired());
        return;
      }
      setState(() {
        loading = false;
        error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldC,
              enabled: !loading,
              obscureText: hide,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: inputDeco(
                'Password lama',
                Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    hide
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => hide = !hide),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: newC,
              enabled: !loading,
              obscureText: hide,
              textInputAction: TextInputAction.next,
              decoration: inputDeco('Password baru', Icons.lock_outline),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Minimal 8 karakter, harus ada huruf dan angka',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: confirmC,
              enabled: !loading,
              obscureText: hide,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!loading) save();
              },
              decoration: inputDeco(
                'Konfirmasi password baru',
                Icons.lock_outline,
              ),
            ),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: loading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: loading ? null : save,
          child: loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

// ---------- Dialog hapus akun ----------

class _DeleteAccountDialog extends StatefulWidget {
  final String token;
  const _DeleteAccountDialog({required this.token});
  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final passC = TextEditingController();
  bool hide = true;
  bool loading = false;
  String error = '';

  @override
  void dispose() {
    passC.dispose();
    super.dispose();
  }

  Future<void> delete() async {
    if (passC.text.isEmpty) {
      setState(() => error = 'Masukkan password untuk konfirmasi');
      return;
    }
    setState(() {
      loading = true;
      error = '';
    });
    try {
      await Api.request(
        'POST',
        '/delete-account',
        token: widget.token,
        body: {'password': passC.text},
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status == 401) {
        Navigator.pop(context, const _SessionExpired());
        return;
      }
      setState(() {
        loading = false;
        error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hapus akun?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Akunmu akan dihapus permanen dan tidak bisa dikembalikan. '
              'Masukkan password untuk konfirmasi.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passC,
              enabled: !loading,
              obscureText: hide,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!loading) delete();
              },
              decoration: inputDeco(
                'Password',
                Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    hide
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => hide = !hide),
                ),
              ),
            ),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: loading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
          ),
          onPressed: loading ? null : delete,
          child: loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Hapus'),
        ),
      ],
    );
  }
}
