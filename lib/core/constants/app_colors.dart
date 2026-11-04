import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Accents (Emerald & Mint - represents trusted money & liquidity)
  static const Color primary = Color(0xFF059669); // Emerald 600
  static const Color primaryDark = Color(0xFF047857); // Emerald 700
  static const Color primaryLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color accentMint = Color(0xFF10B981); // Emerald 500

  // Secondary Brand (Deep Slate Navy - premium fintech feel)
  static const Color darkSlate = Color(0xFF0F172A); // Slate 900
  static const Color surfaceSlate = Color(0xFF1E293B); // Slate 800
  static const Color cardSlate = Color(0xFF334155); // Slate 700

  // Exchange Type Semantics
  // 1. Cash to Digital (User has Physical Cash) -> Warm Amber / Gold
  static const Color cashColor = Color(0xFFD97706); // Amber 600
  static const Color cashLight = Color(0xFFFEF3C7); // Amber 100

  // 2. Digital to Cash (User has Digital Funds) -> Trust Blue / Indigo
  static const Color digitalColor = Color(0xFF2563EB); // Blue 600
  static const Color digitalLight = Color(0xFFDBEAFE); // Blue 100

  // Background & Surface
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate 100
  static const Color border = Color(0xFFE2E8F0); // Slate 200

  // Typography
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Status & Badges
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cashGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient digitalGradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
