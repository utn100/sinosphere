import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Core accent palette (shared across modes) ─────────────────────────────
  static const Color hanviet  = Color(0xFFF59E0B); // amber-500 — ZH/HV anchor
  static const Color coral    = Color(0xFFFF6B6B); // coral — primary brand
  static const Color semantic = Color(0xFF10B981); // emerald-500 — semantic/memorize
  static const Color phonetic = Color(0xFF3B82F6); // blue-500 — phonetic
  static const Color iconic   = Color(0xFFA855F7); // purple-500 — iconic
  static const Color sky      = Color(0xFF38BDF8); // sky-400 — compounds
  static const Color learned  = Color(0xFF8B5CF6); // violet-500 — user nodes

  // ── Dark palette (warmer, less cold than slate) ──────────────────────────
  static const Color background  = Color(0xFF0D1117); // warmer dark
  static const Color surface     = Color(0xFF161B22); // GitHub dark
  static const Color card        = Color(0xFF1C2333); // warmer card
  static const Color cardBorder  = Color(0xFF30363D); // warmer border
  static const Color textPrimary = Color(0xFFF0F6FF); // warm white
  static const Color textSecond  = Color(0xFF8B949E); // muted
  static const Color textMuted   = Color(0xFF484F58); // very muted

  // ── Light palette (periwinkle-white, bubbly) ──────────────────────────────
  static const Color lightBackground  = Color(0xFFF0F4FF); // soft periwinkle-white
  static const Color lightSurface     = Color(0xFFFFFFFF);
  static const Color lightCard        = Color(0xFFFFFFFF); // pure white cards
  static const Color lightCardBorder  = Color(0xFFE8EDF5); // soft blue-grey
  static const Color lightTextPrimary = Color(0xFF1A1F36); // warm dark
  static const Color lightTextSecond  = Color(0xFF4A5568); // medium
  static const Color lightTextMuted   = Color(0xFF9BA3AF); // muted

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
      primary: coral,
      secondary: semantic,
      surface: surface,
      onSurface: textPrimary,
    ),
    textTheme: GoogleFonts.nunitoTextTheme(
      const TextTheme(
        bodyLarge:   TextStyle(color: textPrimary),
        bodyMedium:  TextStyle(color: textPrimary),
        bodySmall:   TextStyle(color: textSecond),
        labelLarge:  TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        titleLarge:  TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.nunito(
        color: coral,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: cardBorder, width: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: hanviet, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      height: 68,
      indicatorColor: coral.withAlpha(40),
      indicatorShape: const StadiumBorder(),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: coral);
        }
        return const IconThemeData(color: textMuted);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.nunito(color: coral, fontSize: 11, fontWeight: FontWeight.w700);
        }
        return GoogleFonts.nunito(color: textMuted, fontSize: 11);
      }),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
      primary: coral,
      secondary: semantic,
      surface: lightSurface,
      onSurface: lightTextPrimary,
    ),
    textTheme: GoogleFonts.nunitoTextTheme(
      const TextTheme(
        bodyLarge:   TextStyle(color: lightTextPrimary),
        bodyMedium:  TextStyle(color: lightTextPrimary),
        bodySmall:   TextStyle(color: lightTextSecond),
        labelLarge:  TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w700),
        titleLarge:  TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w800),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightSurface,
      foregroundColor: lightTextPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.nunito(
        color: coral,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 0,
      shadowColor: const Color(0xFF1A1F36).withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: lightCardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: lightCardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: coral, width: 1.5),
      ),
      hintStyle: const TextStyle(color: lightTextMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: lightSurface,
      height: 68,
      indicatorColor: coral.withAlpha(35),
      indicatorShape: const StadiumBorder(),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: coral);
        }
        return IconThemeData(color: lightTextMuted.withAlpha(200));
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.nunito(color: coral, fontSize: 11, fontWeight: FontWeight.w700);
        }
        return GoogleFonts.nunito(color: lightTextMuted, fontSize: 11);
      }),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: lightSurface,
      elevation: 8,
      shadowColor: const Color(0xFF1A1F36).withAlpha(25),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: lightCardBorder, thickness: 0.5),
    extensions: const [SinosphereColors.light],
  );
}

// ── Theme extension ───────────────────────────────────────────────────────────
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
