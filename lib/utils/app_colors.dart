import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Private constructor

  // 🧁 Cream Foundation - Warm and inviting
  static const background = Color(0xFFFDF8F2);  // Warm cream (main background)
  static const surface = Color(0xFFFFF9F0);     // Lighter cream (cards)
  static const surfaceLight = Color(0xFFFFFFFA); // Off-white (elevated)
  static const border = Color(0xFFE8E0D5);      // Soft warm gray (borders)

  // 🌑 Dark Accents - For contrast and readability
  static const darkPrimary = Color(0xFF2C3E50);  // Deep slate (primary dark)
  static const darkSecondary = Color(0xFF34495E); // Softer slate
  static const darkAccent = Color(0xFF1E2B38);   // Almost black (deep accents)

  // 📝 Text - Warm grayscale
  static const textPrimary = Color(0xFF2C3E50);   // Deep slate (headings)
  static const textSecondary = Color(0xFF5D6D7E); // Warm gray (body)
  static const textMuted = Color(0xFF8A9AAB);     // Soft gray (hints)
  static const textLight = Color(0xFFBFB8AF);     // Light warm (disabled)

  // 🎯 Accent Colors - Warm and purposeful
  static const success = Color(0xFF4A7C59);  // Sage green (pass)
  static const error = Color(0xFFC44545);    // Warm red (fail)
  static const accent = Color(0xFFC38E6B);   // Terracotta (highlights)
  static const warning = Color(0xFFE6B87A);  // Warm amber
  
  // 📈 Chart Colors - Earthy and readable
  static const pass = success;                 // Sage green
  static const fail = error;                   // Warm red
  static const chartGrid = border;             // Reuse border
  static const chartText = textSecondary;      // Warm gray
  static const chartBackground = surface;       // Light cream
  static const chartBorder = border;            // Warm border
  
  // 🎨 Gradients - Warm and subtle
  static const passGradient = LinearGradient(
    colors: [Color(0xFF4A7C59), Color(0xFF6B8F7A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const failGradient = LinearGradient(
    colors: [Color(0xFFC44545), Color(0xFFD97C7C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFFC38E6B), Color(0xFFD9B8A4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // 📊 Chart Areas - Very subtle (8% opacity)
  static Color passArea = const Color(0xFF4A7C59).withValues(alpha: 0.08);
  static Color failArea = const Color(0xFFC44545).withValues(alpha: 0.08);

  // ✨ Shadows - Warm and soft
  static List<BoxShadow> shadow({double blur = 12, double alpha = 0.08}) => [
    BoxShadow(
      color: darkPrimary.withValues(alpha: alpha),
      blurRadius: blur,
      offset: const Offset(0, 4),
    )
  ];
  
  static List<BoxShadow> get chartShadow => shadow(blur: 20, alpha: 0.06);
  
  // 🎯 Interactive States
  static Color hover = darkPrimary.withValues(alpha: 0.04);
  static Color pressed = darkPrimary.withValues(alpha: 0.08);
  static Color selected = accent.withValues(alpha: 0.12);
}

// Usage Examples:
/*
// Warm cream background
Scaffold(
  backgroundColor: AppColors.background,
  body: Container(
    color: AppColors.surface,
    child: Text(
      'Warm Minimal Design',
      style: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
)

// Dark accents for contrast
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.darkPrimary,
    foregroundColor: Colors.white,
  ),
  onPressed: () {},
  child: Text('Primary Action'),
)

// Charts that pop on cream
LineChart(
  data,
  gridColor: AppColors.chartGrid,
  textColor: AppColors.chartText,
  passColor: AppColors.pass,
  failColor: AppColors.fail,
)

// Success/error states
Text(
  'Score: 85%',
  style: TextStyle(
    color: AppColors.success,
    fontWeight: FontWeight.bold,
  ),
)
*/