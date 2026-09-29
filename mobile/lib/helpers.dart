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
