import 'package:flutter/material.dart';

class PoliedroFoodStyle {
  // Cores principais
  static const Color primaryBlue = Color(0xFF0078D7);
  static const Color secondaryOrange = Color(0xFFF7941D);
  static const Color accentYellow = Color(0xFFFFD700);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Color(0xFF757575);
  static const Color background = Color(0xFFF5F7FA);
  static const Color backgroundLight = Color(0xFFE1F5FE); // Adicionado
  static const Color cardBackground = Colors.white;
  static const Color divider = Color(0xFFEEEEEE);
  static const Color error = Color(0xFFE53935);
  static const Color errorRed = Color(0xFFE53935); // Adicionado
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF1E88E5);
  static const Color priceColor = Color(0xFF333333); // Cor neutra para preços
  static const Color orderIdColor = Color(0xFF333333); // Cor neutra para IDs de pedido
  static const Color totalColor = Color(0xFF333333); // Cor neutra para totais

  // Gradientes
  static final LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFE1F5FE),
      Color(0xFFF5F7FA),
    ],
  );

  // Espaçamentos
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Raios de borda
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  // Sombras
  static final List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // Estilos de texto
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textDark,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textDark,
    height: 1.2,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textDark,
    height: 1.2,
  );

  static const TextStyle subtitleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textDark,
    height: 1.3,
  );

  static const TextStyle subtitleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textDark,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textDark,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textDark,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textLight,
    height: 1.5,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: white,
    height: 1.2,
  );

  static const TextStyle priceText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: priceColor,
    height: 1.2,
  );

  static const TextStyle totalText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: totalColor,
    height: 1.2,
  );

  static const TextStyle orderIdText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: orderIdColor,
    height: 1.2,
  );
  
  // Estilo para legendas e rodapés
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textLight,
    height: 1.2,
  );

  // Estilos de botões
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: white,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingL,
      vertical: spacingM,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
    ),
    elevation: 2,
    textStyle: buttonText,
  );

  static final ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: white,
    foregroundColor: primaryBlue,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingL,
      vertical: spacingM,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
      side: const BorderSide(color: primaryBlue),
    ),
    elevation: 0,
    textStyle: buttonText.copyWith(color: primaryBlue),
  );

  static final ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryBlue,
    backgroundColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingM,
      vertical: spacingS,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
    ),
    textStyle: buttonText.copyWith(color: primaryBlue),
  );

  // Decoração para campos de entrada
  static InputDecoration inputDecoration({
    String? labelText,
    String? hintText,
    IconData? prefixIcon,  // Alterado para IconData em vez de Icon
    IconData? suffixIcon,  // Alterado para IconData em vez de Icon
    VoidCallback? onSuffixIconPressed,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      hintStyle: bodyMedium.copyWith(color: textLight),
      filled: true,
      fillColor: white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingM,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: error),
      ),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: textLight) : null,
      suffixIcon: suffixIcon != null
          ? IconButton(
              icon: Icon(suffixIcon, color: textLight),
              onPressed: onSuffixIconPressed,
            )
          : null,
    );
  }

  // Decoração para cards
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(radiusM),
    boxShadow: shadowSmall,
  );

  // Decoração para containers
  static BoxDecoration containerDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(radiusM),
    boxShadow: shadowSmall,
  );
  
  // Decoração para containers com gradiente
  static BoxDecoration gradientContainerDecoration = BoxDecoration(
    gradient: mainGradient,
    borderRadius: BorderRadius.circular(radiusM),
  );
}
