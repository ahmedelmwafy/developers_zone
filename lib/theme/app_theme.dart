import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SnackBarType { success, error, warning, info }

class AppColors {
  // Tonal Architecture (Charcoal to Electric Blue)
  static const Color surface = Color(0xFF131313); // Base Layer
  static const Color surfaceContainerLowest = Color(0xFF0E0E0E);
  static const Color surfaceContainerLow = Color(0xFF1C1B1B);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF353534);
  static const Color surfaceBright = Color(0xFF393939); // Interaction Layer

  // Brand (Electric Blue)
  static const Color primary = Color(0xFFC3F5FF);
  static const Color primaryContainer = Color(0xFF00E5FF);
  static const Color surfaceTint = Color(0xFF00DAF3);
  static const Color primaryFixedDim = Color(0xFF00DAF3);

  // Status
  static const Color success = Color(0xFF00E5FF);
  static const Color warning = Color(0xFFFFCC00);
  static const Color error = Color(0xFFFF5252);
  static const Color secondary = Color(0xFF9ECAFF);

  // Text Hierarchy
  static const Color onSurface = Color(0xFFE5E2E1);
  static const Color onSurfaceVariant = Color(0xFFBAC9CC);
  static const Color onPrimary = Color(0xFF00363D);

  // Compatibility Aliases (for existing code)
  static const Color background = surface;
  static const Color accent = primaryContainer;
  static const Color accentSecondary = secondary;
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textMuted = onSurfaceVariant; 
  static const Color card = surfaceContainerLow;
  static const Color cardLight = surfaceContainer;
  static const Color primaryLight = primary;
  static const Color primaryDark = surfaceTint;

  // Ghost Border (15% opacity)
  static Color ghostBorder = const Color(0xFF3B494C).withValues(alpha: 0.15);

  // Signature Gradient (primary to primary_container @ 135deg)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark();
    final interTheme = GoogleFonts.interTextTheme(baseTheme.textTheme);
    final spaceGroteskTheme = GoogleFonts.spaceGroteskTextTheme(baseTheme.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: interTheme.copyWith(
        displayLarge: spaceGroteskTheme.displayLarge?.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
        ),
        headlineLarge: spaceGroteskTheme.headlineLarge?.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: spaceGroteskTheme.headlineMedium?.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: spaceGroteskTheme.titleLarge?.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: interTheme.titleMedium?.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: interTheme.bodyLarge?.copyWith(color: AppColors.onSurface),
        bodyMedium: interTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
      ),
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        error: AppColors.error,
        outlineVariant: AppColors.ghostBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppColors.onSurface),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: AppColors.ghostBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
        hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF3B494C)),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF3B494C)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 24,
      ),
    );
  }

  static ThemeData arabicTheme() {
    final base = darkTheme;
    final cairoTheme = GoogleFonts.cairoTextTheme(base.textTheme);
    final cairoDisplayTheme = GoogleFonts.cairoTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: cairoTheme.copyWith(
        displayLarge: cairoDisplayTheme.displayLarge?.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        headlineLarge: cairoDisplayTheme.headlineLarge?.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: cairoDisplayTheme.headlineMedium?.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: cairoDisplayTheme.titleLarge?.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: cairoTheme.bodyLarge?.copyWith(
          color: AppColors.onSurface,
          height: 1.6,
        ),
        bodyMedium: cairoTheme.bodyMedium?.copyWith(
          color: AppColors.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
  }
}


// Reusable UI helpers
class AppWidgets {
  static Widget gradientButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: onPressed != null ? AppColors.primaryGradient : null,
        color: onPressed == null ? AppColors.cardLight : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10))
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8)
                      ],
                      Text(label,
                          style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  static InputDecoration fieldDecoration(String label, {IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.textSecondary, size: 20)
          : null,
    );
  }

  static Widget glassContainer({
    required Widget child,
    double borderRadius = 24,
    double blur = 14,
    Color? color,
    Border? border,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ??
                  Border.all(color: Colors.white.withValues(alpha: 0.12)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.07),
                  Colors.white.withValues(alpha: 0.03),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  static Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 18)),
        ],
      ),
    );
  }

  static PreferredSizeWidget appBar(String title,
      {List<Widget>? actions, bool centerTitle = false}) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child:
            Container(color: Colors.white.withValues(alpha: 0.06), height: 1),
      ),
    );
  }

  // ── Global SnackBar ──────────────────────────────────────────────────────
  static void showSnackBar(
    BuildContext? context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    ScaffoldMessengerState? messenger,
  }) {
    final colors = {
      SnackBarType.success: AppColors.success,
      SnackBarType.error: AppColors.error,
      SnackBarType.warning: AppColors.warning,
      SnackBarType.info: AppColors.primary,
    };
    final icons = {
      SnackBarType.success: Icons.check_circle_outline_rounded,
      SnackBarType.error: Icons.error_outline_rounded,
      SnackBarType.warning: Icons.warning_amber_rounded,
      SnackBarType.info: Icons.info_outline_rounded,
    };
    final color = colors[type]!;
    final messengerState = messenger ?? ScaffoldMessenger.of(context!);

    messengerState.hideCurrentSnackBar();
    messengerState.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 20)
            ],
          ),
          child: Row(
            children: [
              Icon(icons[type]!, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
