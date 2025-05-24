import 'package:flutter/material.dart';

/// Guia de estilo para o aplicativo Poliedro Food
/// Baseado na tela inicial redesenhada e na identidade visual do Poliedro
class PoliedroFoodStyle {
  // Cores principais
  static const Color primaryBlue = Color(0xFF0071BC);
  static const Color lightBlue = Color(0xFF00A0E3);
  static const Color accentOrange = Color(0xFFF7941D);
  static const Color errorRed = Color(0xFFED1C24);
  static const Color textDark = Color(0xFF333333);
  static const Color textMedium = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color backgroundLight = Color(0xFFF5F9FF);
  static const Color white = Colors.white;
  
  // Gradientes
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      white,
      Color(0xFFE6F3FF),
    ],
  );
  
  // Tipografia
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: primaryBlue,
    letterSpacing: 1.2,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryBlue,
    letterSpacing: 0.5,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: primaryBlue,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textDark,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    color: textDark,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    color: textMedium,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: textLight,
  );
  
  // Espaçamentos
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Raios de borda
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  
  // Elevações
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];
  
  // Estilos de botões
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: white,
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
    ),
    elevation: 4,
    textStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  );
  
  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: white,
    foregroundColor: primaryBlue,
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
      side: const BorderSide(color: primaryBlue, width: 2),
    ),
    elevation: 0,
    textStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  );
  
  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryBlue,
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
  );
  
  // Decoração de campos de entrada
  static InputDecoration inputDecoration({String? labelText, String? hintText, Widget? prefixIcon}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: errorRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: errorRed, width: 2),
      ),
      labelStyle: const TextStyle(color: textMedium),
      hintStyle: const TextStyle(color: textLight),
    );
  }
  
  // Decoração de cards
  static BoxDecoration cardDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(radiusM),
    boxShadow: shadowSmall,
  );
  
  // Decoração de containers com gradiente
  static BoxDecoration gradientContainerDecoration = BoxDecoration(
    gradient: mainGradient,
    borderRadius: BorderRadius.circular(radiusM),
  );
}
