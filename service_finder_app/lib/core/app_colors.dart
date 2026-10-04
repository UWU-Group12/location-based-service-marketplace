import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF8B0000);
  static const Color secondary = Color(0xFFF3F8FF);

  // Backgrounds
  static const Color background = Color.fromARGB(255, 250, 251, 255);
  static const Color providerCard = Color(0xFFFFF3F3);
  static const Color customerCard = Color(0xFFF3F8FF);
  static const Color googleButton = Color(0xFFF1F1F1);

  // Soft tints behind category illustrations
  static const Color categoryTintRose = Color(0xFFFDECEC);
  static const Color categoryTintRosePressed = Color(0xFFF8DADA);
  static const Color categoryTintBlue = Color(0xFFE3F2FD);
  static const Color categoryTintAmber = Color(0xFFFFF3E0);
  static const Color categoryTintGreen = Color(0xFFE8F5E9);

  // Dark maroon used for text on the maroon-tinted cards
  static const Color onTintPrimary = Color(0xFF4A1010);
  static const Color onTintPrimaryMuted = Color(0x994A1010);

  // Text
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.black54;
  static const Color hint = Colors.grey;
  static const Color rating = Colors.amber;

  // Status
  static const Color success = Colors.green;
  static const Color info = Colors.blue;
  static const Color warning = Colors.orange;

  // Borders
  static const Color border = Colors.black12;
  static const Color focusedBorder = Colors.black26;
  static const Color error = Colors.redAccent;
}
