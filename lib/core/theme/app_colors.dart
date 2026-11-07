import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color midnight = Color(0xFF0B1B3F);
  static const Color navy = Color(0xFF13285C);
  static const Color primary = Color(0xFF2F5BEA);
  static const Color primaryLight = Color(0xFFE8EEFF);
  static const Color accent = Color(0xFFFF8A3D);
  static const Color accentLight = Color(0xFFFFF1E7);

  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE4E8F1);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color submitted = Color(0xFFF59E0B);
  static const Color submittedBg = Color(0xFFFFF7E6);
  static const Color review = Color(0xFF8B5CF6);
  static const Color reviewBg = Color(0xFFF3EEFF);
  static const Color progress = Color(0xFF2F5BEA);
  static const Color progressBg = Color(0xFFE8EEFF);
  static const Color resolved = Color(0xFF12B76A);
  static const Color resolvedBg = Color(0xFFE7F8EF);
  static const Color rejected = Color(0xFFF04438);
  static const Color rejectedBg = Color(0xFFFEECEB);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [midnight, navy, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
