import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'helpers.dart';

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
