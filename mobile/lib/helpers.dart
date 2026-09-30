import 'package:flutter/material.dart';

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

String? validatePassword(String p) {
  if (p.length < 8) return 'Password minimal 8 karakter';
  if (p.length > 100) return 'Password maksimal 100 karakter';
  if (!RegExp(r'[A-Za-z]').hasMatch(p) || !RegExp(r'\d').hasMatch(p)) {
    return 'Password harus mengandung huruf dan angka';
  }
  return null;
}
