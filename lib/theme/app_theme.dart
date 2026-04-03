import 'package:flutter/material.dart';

enum SnackBarType { success, error, warning, info }

class AppColors {
  // Core Palette
  static const Color background = Color(0xFF0A0A12);
  static const Color surface = Color(0xFF111120);
  static const Color card = Color(0xFF161628);
  static const Color cardLight = Color(0xFF1E1E35);

  // Brand
  static const Color primary = Color(0xFF7C4DFF);
  static const Color primaryLight = Color(0xFF9E72FF);
  static const Color primaryDark = Color(0xFF5C2BE0);
  static const Color accent = Color(0xFF00E5FF);
  static const Color accentSecondary = Color(0xFF29D9A1);

  // Text
  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF8888AA);
  static const Color textMuted = Color(0xFF55556A);

  // Status
  static const Color success = Color(0xFF29D9A1);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFFF5252);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A30), Color(0xFF111120)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF0A0A12), Color(0xFF150E30), Color(0xFF0A0A12)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        fontFamily: 'Poppins',
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardLight,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintStyle: const TextStyle(color: AppColors.textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: TextStyle(
              fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 10),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle:
              TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontFamily: 'Poppins'),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white.withValues(alpha: 0.07),
          thickness: 1,
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textSecondary),
          labelSmall: TextStyle(color: AppColors.textMuted),
        ),
      );

  // Shared helper for Arabic theme identical except fontFamily
  static ThemeData arabicTheme() {
    return darkTheme.copyWith(
      textTheme: darkTheme.textTheme.apply(fontFamily: 'Tajawal'),
      appBarTheme: darkTheme.appBarTheme.copyWith(
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Tajawal',
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
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
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
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              fontFamily: 'Poppins')),
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
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
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
