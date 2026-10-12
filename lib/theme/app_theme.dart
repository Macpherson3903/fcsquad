import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static CupertinoThemeData get cupertinoTheme {
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryYellow,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      barBackgroundColor: AppColors.backgroundDark,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.primaryYellow,
        textStyle: TextStyle(
          inherit: false,
          fontFamily: 'Montserrat',
          color: AppColors.textWhite,
          fontSize: 17,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return _baseTheme(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      cardColor: const Color(0xFFF4F6FA),
      textColor: AppColors.backgroundDark,
      mutedTextColor: const Color(0xFF5F6E85),
    );
  }

  static ThemeData get darkTheme {
    return _baseTheme(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      cardColor: AppColors.cardColor,
      textColor: AppColors.textWhite,
      mutedTextColor: AppColors.textGray,
    );
  }

  static ThemeData _baseTheme({
    required Brightness brightness,
    required Color scaffoldBackgroundColor,
    required Color cardColor,
    required Color textColor,
    required Color mutedTextColor,
  }) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark()
        : ThemeData.light();

    return ThemeData(
      brightness: brightness,
      fontFamily: 'Montserrat',
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      primaryColor: AppColors.primaryYellow,
      colorScheme: brightness == Brightness.dark
          ? const ColorScheme.dark(
              primary: AppColors.primaryYellow,
              secondary: AppColors.primaryYellowDark,
              surface: AppColors.cardColor,
            )
          : const ColorScheme.light(
              primary: AppColors.primaryYellow,
              secondary: AppColors.primaryYellowDark,
              surface: Color(0xFFF4F6FA),
            ),
      textTheme: base.textTheme
          .apply(
            fontFamily: 'Montserrat',
            bodyColor: textColor,
            displayColor: textColor,
          )
          .copyWith(
            displayLarge: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
            titleLarge: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
            bodyLarge: TextStyle(fontFamily: 'Montserrat', color: textColor),
            bodyMedium: TextStyle(
              fontFamily: 'Montserrat',
              color: mutedTextColor,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.primaryYellow),
        titleTextStyle: const TextStyle(
          color: AppColors.primaryYellow,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scaffoldBackgroundColor,
        unselectedItemColor: mutedTextColor,
        selectedItemColor: AppColors.primaryYellow,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }
}
