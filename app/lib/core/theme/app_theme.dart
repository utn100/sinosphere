import 'package:flutter/material.dart';

class AppTheme {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color background  = Color(0xFF020817); // slate-950
  static const Color surface     = Color(0xFF0F172A); // slate-900
  static const Color card        = Color(0xFF1E293B); // slate-800
  static const Color cardBorder  = Color(0xFF334155); // slate-700
  static const Color textPrimary = Color(0xFFF1F5F9); // slate-100
  static const Color textSecond  = Color(0xFF94A3B8); // slate-400
  static const Color textMuted   = Color(0xFF475569); // slate-600

  // Accent
  static const Color hanviet  = Color(0xFFF59E0B); // amber-500  — HV anchor
  static const Color semantic = Color(0xFF10B981); // emerald-500 — semantic
  static const Color phonetic = Color(0xFF3B82F6); // blue-500   — phonetic
  static const Color iconic   = Color(0xFFA855F7); // purple-500 — iconic
  static const Color sky      = Color(0xFF38BDF8); // sky-400    — compounds
  static const Color learned  = Color(0xFF8B5CF6); // violet-500 — user nodes

  // Light palette
  static const Color lightBackground  = Color(0xFFF8FAFC); // slate-50
  static const Color lightSurface     = Color(0xFFFFFFFF);
  static const Color lightCard        = Color(0xFFF1F5F9); // slate-100
  static const Color lightCardBorder  = Color(0xFFE2E8F0); // slate-200
  static const Color lightTextPrimary = Color(0xFF0F172A); // slate-900
  static const Color lightTextSecond  = Color(0xFF475569); // slate-600
  static const Color lightTextMuted   = Color(0xFF94A3B8); // slate-400

  // ── Component type colours ────────────────────────────────────────────────
  static Color componentColor(String type) {
    switch (type) {
      case 'semantic': return semantic;
      case 'phonetic': return phonetic;
      case 'iconic':   return iconic;
      default:         return textSecond;
    }
  }

  static Color componentBg(String type) {
    switch (type) {
      case 'semantic': return semantic.withAlpha(38);
      case 'phonetic': return phonetic.withAlpha(38);
      case 'iconic':   return iconic.withAlpha(38);
      default:         return card;
    }
  }

  static String componentLabel(String type) {
    switch (type) {
      case 'semantic': return 'Biểu ý';
      case 'phonetic': return 'Biểu âm';
      case 'iconic':   return 'Tượng hình';
      default:         return type;
    }
  }

  // ── Resonance colours ─────────────────────────────────────────────────────
  static Color resonanceDot(String resonance) {
    switch (resonance) {
      case 'high':   return hanviet;
      case 'medium': return sky;
      case 'low':    return textMuted;
      default:       return textMuted;
    }
  }

  // ── Dark theme ────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: hanviet,
      secondary: semantic,
      surface: surface,
      onSurface: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: cardBorder, width: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: hanviet, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    textTheme: const TextTheme(
      bodyLarge:  TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textPrimary),
      bodySmall:  TextStyle(color: textSecond),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: hanviet.withAlpha(51),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: hanviet);
        }
        return const IconThemeData(color: textMuted);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: hanviet, fontSize: 11, fontWeight: FontWeight.w700);
        }
        return const TextStyle(color: textMuted, fontSize: 11);
      }),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: cardBorder, thickness: 0.5),
    extensions: const [SinosphereColors.dark],
  );

  // ── Light theme ───────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    colorScheme: const ColorScheme.light(
      primary: hanviet,
      secondary: semantic,
      surface: lightSurface,
      onSurface: lightTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightSurface,
      foregroundColor: lightTextPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: lightCardBorder, width: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: lightCardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: lightCardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: hanviet, width: 1.5),
      ),
      hintStyle: const TextStyle(color: lightTextMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    textTheme: const TextTheme(
      bodyLarge:  TextStyle(color: lightTextPrimary),
      bodyMedium: TextStyle(color: lightTextPrimary),
      bodySmall:  TextStyle(color: lightTextSecond),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: lightSurface,
      indicatorColor: hanviet.withAlpha(38),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: hanviet);
        }
        return const IconThemeData(color: lightTextMuted);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: hanviet, fontSize: 11, fontWeight: FontWeight.w700);
        }
        return const TextStyle(color: lightTextMuted, fontSize: 11);
      }),
    ),
    extensions: const [SinosphereColors.light],
  );
}

// Theme extension for easy access in widgets
class SinosphereColors extends ThemeExtension<SinosphereColors> {
  final Color bg;
  final Color surf;
  final Color cardBg;
  final Color border;
  final Color text;
  final Color textSub;
  final Color textMuted;
  final bool isDark;

  const SinosphereColors({
    required this.bg, required this.surf, required this.cardBg,
    required this.border, required this.text, required this.textSub,
    required this.textMuted, required this.isDark,
  });

  static const dark = SinosphereColors(
    bg: AppTheme.background, surf: AppTheme.surface, cardBg: AppTheme.card,
    border: AppTheme.cardBorder, text: AppTheme.textPrimary,
    textSub: AppTheme.textSecond, textMuted: AppTheme.textMuted, isDark: true,
  );

  static const light = SinosphereColors(
    bg: AppTheme.lightBackground, surf: AppTheme.lightSurface,
    cardBg: AppTheme.lightCard, border: AppTheme.lightCardBorder,
    text: AppTheme.lightTextPrimary, textSub: AppTheme.lightTextSecond,
    textMuted: AppTheme.lightTextMuted, isDark: false,
  );

  @override
  SinosphereColors copyWith({Color? bg, Color? surf, Color? cardBg,
      Color? border, Color? text, Color? textSub, Color? textMuted, bool? isDark}) {
    return SinosphereColors(
      bg: bg ?? this.bg, surf: surf ?? this.surf, cardBg: cardBg ?? this.cardBg,
      border: border ?? this.border, text: text ?? this.text,
      textSub: textSub ?? this.textSub, textMuted: textMuted ?? this.textMuted,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  SinosphereColors lerp(SinosphereColors? other, double t) => this;
}

extension ThemeX on BuildContext {
  SinosphereColors get colors =>
      Theme.of(this).extension<SinosphereColors>() ?? SinosphereColors.dark;
  bool get isDark => colors.isDark;
}
