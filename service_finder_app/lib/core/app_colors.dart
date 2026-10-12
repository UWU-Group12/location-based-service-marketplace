import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF1C1B1F);
  static const Color secondary = Color(0xFFF3F8FF);

  // Backgrounds
  static const Color background = Color.fromARGB(255, 250, 251, 255);
  static const Color providerCard = Color(0xFFF0F0F2);
  static const Color customerCard = Color.fromARGB(255, 255, 255, 255);
  static const Color googleButton = Color(0xFFF1F1F1);

  // Soft tints behind category illustrations
  static const Color categoryTintRose = Color(0xFFFDECEC);
  static const Color categoryTintRosePressed = Color(0xFFF8DADA);
  static const Color categoryTintBlue = Color(0xFFE3F2FD);
  static const Color categoryTintAmber = Color(0xFFFFF3E0);
  static const Color categoryTintGreen = Color(0xFFE8F5E9);

  // Near-black used for text on the tinted cards
  static const Color onTintPrimary = Color(0xFF1C1B1F);
  static const Color onTintPrimaryMuted = Color(0x991C1B1F);

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
