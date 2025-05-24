import 'package:flutter/material.dart';

class PoliedroTheme {
  // Cores principais do Poliedro baseadas no site
  static const Color poliedroGreen = Color(0xFF00A651);
  static const Color poliedroBlue = Color(0xFF0071BC);
  static const Color poliedroOrange = Color(0xFFF7941D);
  static const Color poliedroPurple = Color(0xFF662D91);
  static const Color poliedroRed = Color(0xFFED1C24);
  
  // Cor primária e variações
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF00A651, // Verde Poliedro como cor primária
    <int, Color>{
      50: Color(0xFFE0F7EA),
      100: Color(0xFFB3EAD1),
      200: Color(0xFF80DCB5),
      300: Color(0xFF4DCE99),
      400: Color(0xFF26C485),
      500: Color(0xFF00A651), // Cor base
      600: Color(0xFF009E4A),
      700: Color(0xFF009540),
      800: Color(0xFF008B37),
      900: Color(0xFF007B27),
    },
  );

  // Tema claro
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: primarySwatch,
      primaryColor: poliedroGreen,
      hintColor: poliedroBlue,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: poliedroGreen,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: poliedroOrange,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: poliedroBlue,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: poliedroGreen, width: 2),
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: poliedroGreen,
        secondary: poliedroOrange,
        tertiary: poliedroBlue,
        error: poliedroRed,
      ),
    );
  }
}
