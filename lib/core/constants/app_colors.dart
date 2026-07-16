import 'package:flutter/material.dart';

class AppColors {
  // Primary Paylens brand colors
  static const Color primaryForest = Color(
    0xFF004B30,
  ); // Forest Green (#004B30)
  static const Color accentLime = Color(0xFFD2F154); // Lime Green (#D2F154)

  // Neutral colors
  static const Color background = Color(
    0xFFF4F6F5,
  ); // Soft off-white/grey-green tint
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Pure white for cards
  static const Color surfaceDark = Color(0xFF1E201E); // Dark surface

  // Text colors
  static const Color textDark = Color(0xFF111412); // Near black
  static const Color textLight = Color(0xFFFFFFFF); // White text
  static const Color textGrey = Color(0xFF6C757D); // Muted grey
  static const Color textLightGrey = Color(0xFFC1C7C4); // Lighter muted grey

  // System/Status colors
  static const Color successGreen = Color(0xFF2E7D32); // Rich green for credits
  static const Color errorRed = Color(
    0xFFD32F2F,
  ); // Vibrant red for debits/errors
  static const Color warningOrange = Color(0xFFF57C00); // Pending states

  // Helper for transparency/overlays
  static const Color forestOverlay = Color(0x1AFFFFFF); // Light white overlay
  static const Color blackOverlay = Color(0xFF000000); // Light white overlay
  static const Color blackDeepOverlay = Color(
    0xFF1E201E,
  ); // Light white overlay
}
