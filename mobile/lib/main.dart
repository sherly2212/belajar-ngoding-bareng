import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_page.dart';
import 'profile_page.dart';

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
