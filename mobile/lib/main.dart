import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_page.dart';
import 'profile_page.dart';

// Warna utama aplikasi. Ganti satu baris ini untuk mengubah tema seluruhnya.
const Color seedColor = Color(0xFF0F766E);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: scheme.onSurface,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: ZoomPageTransitionsBuilder()},
    ),
  );
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Belajar Ngoding',
    debugShowCheckedModeBanner: false,
    themeMode: ThemeMode.system,
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
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
