import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────
//  VigilPay Design Tokens
// ─────────────────────────────────────────
class VigilColors {
  VigilColors._();

  // Red family
  static const red        = Color(0xFF8C1515);
  static const redDark    = Color(0xFF6A0F0F);
  static const redDeep    = Color(0xFF1E100F); // from login panel
  static const redMuted   = Color(0xFFF5E6E6);
  static const redGlow    = Color(0x388C1515); // 22% opacity

  // Navy family
  static const navy       = Color(0xFF252422);
  static const navyDark   = Color(0xFF1A1917);
  static const navyMid    = Color(0xFF2E2B28);

  // Gold family
  static const gold       = Color(0xFFC9A84C);
  static const goldLight  = Color(0xFFE8C97A);
  static const goldMuted  = Color(0x1FC9A84C); // 12% opacity

  // Stone / neutral family
  static const stone      = Color(0xFFF6F4F1);
  static const stoneMid   = Color(0xFFE8E3DC);
  static const white      = Color(0xFFFFFFFF);

  // Semantic — success
  static const success        = Color(0xFF059669);
  static const successLight   = Color(0xFFECFDF5);
  static const successBorder  = Color(0xFFA7F3D0);

  // Semantic — warning
  static const warning        = Color(0xFFB45309);
  static const warningLight   = Color(0xFFFFFBEB);
  static const warningBorder  = Color(0xFFFDE68A);

  // Semantic — danger (alias of red for clarity)
  static const danger         = red;
  static const dangerLight    = redMuted;

  // Semantic — info (notification blue)
  static const info           = Color(0xFF2563EB);
  static const infoLight      = Color(0xFFEFF6FF);
}

// ─────────────────────────────────────────
//  VigilPay Text Styles
// ─────────────────────────────────────────
class VigilText {
  VigilText._();

  // Display — Playfair Display (serif hero numbers / headings)
  static const String _serif  = 'PlayfairDisplay';
  static const String _sans   = 'Poppins';

  static const displayLarge = TextStyle(
    fontFamily: _serif,
    fontWeight: FontWeight.w900,
    fontSize: 32,
    color: VigilColors.white,
    letterSpacing: -0.8,
    height: 1.1,
  );

  static const displayMedium = TextStyle(
    fontFamily: _serif,
    fontWeight: FontWeight.w900,
    fontSize: 24,
    color: VigilColors.navy,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static const headlineLarge = TextStyle(
    fontFamily: _sans,
    fontWeight: FontWeight.w800,
    fontSize: 18,
    color: VigilColors.navy,
    letterSpacing: -0.3,
  );

  static const headlineMedium = TextStyle(
    fontFamily: _sans,
    fontWeight: FontWeight.w800,
    fontSize: 14.4,
    color: VigilColors.navy,
    letterSpacing: -0.1,
  );

  static const titleMedium = TextStyle(
    fontFamily: _sans,
    fontWeight: FontWeight.w700,
    fontSize: 12.4,
    color: VigilColors.navy,
  );

  static const bodyMedium = TextStyle(
    fontFamily: _sans,
    fontWeight: FontWeight.w400,
    fontSize: 12.4,
    color: VigilColors.navy,
    height: 1.6,
  );

  static const bodySmall = TextStyle(
    fontFamily: _sans,
    fontWeight: FontWeight.w500,
    fontSize: 11.2,
    color: Color(0xFF888888),
    height: 1.55,
  );

  static const labelLarge = TextStyle(
    fontFamily: _sans,
    fontWeight: FontWeight.w800,
    fontSize: 12,
    letterSpacing: 0.06,
    color: VigilColors.white,
  );

  // Section label — the small ALL-CAPS red labels
  static const sectionLabel = TextStyle(
    fontFamily: _sans,
    fontWeight: FontWeight.w800,
    fontSize: 9.6,
    letterSpacing: 2.24,
    color: VigilColors.red,
  );

  // Stat / gauge number
  static const statHero = TextStyle(
    fontFamily: _serif,
    fontWeight: FontWeight.w900,
    fontSize: 33.6,
    color: VigilColors.white,
    letterSpacing: -0.6,
    height: 1.0,
  );
}

// ─────────────────────────────────────────
//  AppTheme
// ─────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,

      // Primary → red
      primary:          VigilColors.red,
      onPrimary:        VigilColors.white,
      primaryContainer: VigilColors.redMuted,
      onPrimaryContainer: VigilColors.redDark,

      // Secondary → gold
      secondary:          VigilColors.gold,
      onSecondary:        VigilColors.navy,
      secondaryContainer: VigilColors.goldMuted,
      onSecondaryContainer: VigilColors.navyDark,

      // Tertiary → navy
      tertiary:          VigilColors.navy,
      onTertiary:        VigilColors.white,
      tertiaryContainer: VigilColors.navyMid,
      onTertiaryContainer: VigilColors.white,

      // Error → semantic danger
      error:          VigilColors.red,
      onError:        VigilColors.white,
      errorContainer: VigilColors.redMuted,
      onErrorContainer: VigilColors.redDark,

      // Surface
      surface:          VigilColors.white,
      onSurface:        VigilColors.navy,
      surfaceContainerHighest: VigilColors.stoneMid,
      surfaceContainerHigh:    VigilColors.stone,
      surfaceContainer:        VigilColors.stone,
      surfaceContainerLow:     VigilColors.white,
      surfaceContainerLowest:  VigilColors.white,
      onSurfaceVariant:        Color(0xFF888888),

      // Outline
      outline:        VigilColors.stoneMid,
      outlineVariant: Color(0xFFCCC8C0),

      // Inverse
      inverseSurface:   VigilColors.navy,
      onInverseSurface: VigilColors.stone,
      inversePrimary:   VigilColors.redMuted,

      shadow:    Color(0x1A000000),
      scrim:     Color(0x66000000),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: VigilColors.stone,

      // ── Typography ──
      fontFamily: 'Poppins',
      textTheme: const TextTheme(
        displayLarge:   VigilText.displayLarge,
        displayMedium:  VigilText.displayMedium,
        headlineLarge:  VigilText.headlineLarge,
        headlineMedium: VigilText.headlineMedium,
        titleMedium:    VigilText.titleMedium,
        bodyMedium:     VigilText.bodyMedium,
        bodySmall:      VigilText.bodySmall,
        labelLarge:     VigilText.labelLarge,
      ),

      // ── AppBar ──
      appBarTheme: const AppBarTheme(
        backgroundColor: VigilColors.navy,
        foregroundColor: VigilColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontWeight: FontWeight.w900,
          fontSize: 18,
          color: VigilColors.white,
          letterSpacing: -0.3,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      // ── Card ──
      cardTheme: CardTheme(
        color: VigilColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: VigilColors.stoneMid, width: 1),
        ),
      ),

      // ── ElevatedButton → primary red ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VigilColors.red,
          foregroundColor: VigilColors.white,
          disabledBackgroundColor: VigilColors.stoneMid,
          disabledForegroundColor: Color(0xFFAAAAAA),
          elevation: 0,
          shadowColor: VigilColors.redGlow,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: VigilText.labelLarge,
        ),
      ),

      // ── OutlinedButton → ghost red ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VigilColors.red,
          side: const BorderSide(color: VigilColors.red, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: VigilText.labelLarge.copyWith(color: VigilColors.red),
        ),
      ),

      // ── TextButton ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VigilColors.red,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),

      // ── FilledButton (for dark / navy contexts) ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: VigilColors.navyMid,
          foregroundColor: VigilColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: VigilText.labelLarge,
        ),
      ),

      // ── InputDecoration (hub-input style) ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VigilColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12.4,
          color: Color(0xFFBBBBBB),
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10.4,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.96,
          color: Color(0xFFAAAAAA),
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10.4,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.96,
          color: VigilColors.red,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: VigilColors.stoneMid, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: VigilColors.stoneMid, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: VigilColors.red, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: VigilColors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: VigilColors.redDark, width: 2),
        ),
        errorStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10.4,
          fontWeight: FontWeight.w600,
          color: VigilColors.red,
        ),
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: VigilColors.white,
        side: const BorderSide(color: VigilColors.stoneMid, width: 1),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF555555),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(
        color: VigilColors.stoneMid,
        thickness: 1,
        space: 1,
      ),

      // ── BottomNavigationBar ──
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: VigilColors.white,
        selectedItemColor: VigilColors.red,
        unselectedItemColor: Color(0xFFAAAAAA),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),

      // ── NavigationBar (M3) ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: VigilColors.white,
        indicatorColor: VigilColors.redMuted,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: VigilColors.red, size: 22);
          }
          return const IconThemeData(color: Color(0xFFAAAAAA), size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 10,
              color: VigilColors.red,
            );
          }
          return const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 10,
            color: Color(0xFFAAAAAA),
          );
        }),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),

      // ── Drawer ──
      drawerTheme: const DrawerThemeData(
        backgroundColor: VigilColors.navy,
        scrimColor: Color(0x66000000),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
      ),

      // ── ListTile ──
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 12.8,
          color: VigilColors.navy,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
          fontSize: 11.2,
          color: Color(0xFF888888),
        ),
        iconColor: Color(0xFF888888),
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: VigilColors.navy,
        contentTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 12.4,
          color: VigilColors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        actionTextColor: VigilColors.gold,
      ),

      // ── Dialog ──
      dialogTheme: DialogTheme(
        backgroundColor: VigilColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: VigilText.headlineMedium,
        contentTextStyle: VigilText.bodyMedium,
      ),

      // ── ProgressIndicator ──
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: VigilColors.red,
        linearTrackColor: VigilColors.stoneMid,
        circularTrackColor: VigilColors.stoneMid,
      ),

      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return VigilColors.white;
          return const Color(0xFFCCCCCC);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return VigilColors.red;
          return VigilColors.stoneMid;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Checkbox ──
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return VigilColors.red;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(VigilColors.white),
        side: const BorderSide(color: VigilColors.stoneMid, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ── Radio ──
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return VigilColors.red;
          return VigilColors.stoneMid;
        }),
      ),

      // ── TabBar ──
      tabBarTheme: const TabBarTheme(
        labelColor: VigilColors.red,
        unselectedLabelColor: Color(0xFFAAAAAA),
        indicatorColor: VigilColors.red,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        dividerColor: VigilColors.stoneMid,
      ),

      // ── Tooltip ──
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: VigilColors.navy,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 6)),
          ],
        ),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 10.4,
          color: VigilColors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      ),

      // ── FloatingActionButton ──
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: VigilColors.red,
        foregroundColor: VigilColors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // ── Badge ──
      badgeTheme: const BadgeThemeData(
        backgroundColor: VigilColors.red,
        textColor: VigilColors.white,
        smallSize: 6,
        largeSize: 16,
        textStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          fontSize: 9,
        ),
      ),

      // ── Slider ──
      sliderTheme: SliderThemeData(
        activeTrackColor: VigilColors.red,
        inactiveTrackColor: VigilColors.stoneMid,
        thumbColor: VigilColors.red,
        overlayColor: VigilColors.redGlow,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
    );
  }

  // ─────────────────────────────────────────
  //  Dark theme — navy/charcoal shell, red accents
  // ─────────────────────────────────────────
  static ThemeData get dark {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.dark,

      primary:          VigilColors.red,
      onPrimary:        VigilColors.white,
      primaryContainer: VigilColors.redDark,
      onPrimaryContainer: VigilColors.redMuted,

      secondary:          VigilColors.gold,
      onSecondary:        VigilColors.navy,
      secondaryContainer: Color(0xFF2A1F08),
      onSecondaryContainer: VigilColors.goldLight,

      tertiary:          VigilColors.stoneMid,
      onTertiary:        VigilColors.navy,
      tertiaryContainer: VigilColors.navyMid,
      onTertiaryContainer: VigilColors.stone,

      error:          VigilColors.red,
      onError:        VigilColors.white,
      errorContainer: VigilColors.redDark,
      onErrorContainer: VigilColors.redMuted,

      surface:          VigilColors.navyDark,
      onSurface:        VigilColors.stone,
      surfaceContainerHighest: VigilColors.navyMid,
      surfaceContainerHigh:    Color(0xFF222020),
      surfaceContainer:        Color(0xFF1E1C1A),
      surfaceContainerLow:     VigilColors.navyDark,
      surfaceContainerLowest:  Color(0xFF141210),
      onSurfaceVariant:        Color(0xFF888480),

      outline:        Color(0xFF3A3733),
      outlineVariant: Color(0xFF2E2B28),

      inverseSurface:   VigilColors.stone,
      onInverseSurface: VigilColors.navy,
      inversePrimary:   VigilColors.redDark,

      shadow:    Color(0x33000000),
      scrim:     Color(0x80000000),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: VigilColors.navyDark,
      fontFamily: 'Poppins',
    );
  }
}