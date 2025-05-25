import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF3B82F6); // Bright blue
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);

  // Accent colors
  static const Color accent = Color(0xFF8B5CF6); // Purple
  static const Color accentDark = Color(0xFF7C3AED);
  static const Color accentLight = Color(0xFFA78BFA);

  // Background colors
  static const Color background = Color(0xFF0F172A); // Deep dark blue
  static const Color backgroundSecondary = Color(
    0xFF1E293B,
  ); // Often used for cards or secondary surfaces
  static const Color surface = Color(
    0xFF1E293B,
  ); // Standard surface color for cards, dialogs
  static const Color surfaceLight = Color(
    0xFF334155,
  ); // A lighter variant of surface
  static const Color surfaceSlightlyLighter = Color(
    0xFF27344A,
  ); // Slightly lighter than surface, for subtle distinctions

  // Text colors
  static const Color textPrimary = Color(
    0xFFF1F5F9,
  ); // Main text, high emphasis
  static const Color textSecondary = Color(
    0xFF94A3B8,
  ); // Secondary text, medium emphasis
  static const Color textTertiary = Color(
    0xFF64748B,
  ); // Tertiary text, low emphasis

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(
    0xFF3B82F6,
  ); // Same as primary, can be different

  // Other colors
  static const Color border = Color(
    0xFF334155,
  ); // For borders on inputs, cards etc.
  static const Color divider = Color(0xFF475569);
  static const Color overlay = Color(
    0x80000000,
  ); // For modal overlays, etc. (black with 50% opacity)

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      background,
      backgroundSecondary,
    ], // Using background and a slightly lighter version
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1AFFFFFF),
      Color(0x0DFFFFFF),
    ], // Very subtle whiteish gradient for glass effect
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
