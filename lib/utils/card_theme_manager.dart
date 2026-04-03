import 'package:flutter/material.dart';

class CardThemeManager {
  /// Resolves the UI theme (Color) based on the first 4 digits of a card number (BIN).
  static Color getThemeForCard(String cardNumber) {
    if (cardNumber.length < 4) return Colors.blueGrey;

    final String firstFour = cardNumber.substring(0, 4);

    // Common BIN mappings (approximations for identifying Indian issuer banks)
    // HDFC typical ranges -> HDFC Blue
    if (['4386', '4016', '5110', '4156'].contains(firstFour)) {
      return const Color(0xFF00305B); // HDFC Deep Blue
    } 
    // ICICI typical ranges -> ICICI Deep Orange
    else if (['4477', '4053', '4136', '4798'].contains(firstFour)) {
      return const Color(0xFFD64402); // ICICI Deep Orange
    }
    // SBI typical ranges -> SBI Light Blue
    else if (['4304', '5294', '4201', '4166'].contains(firstFour)) {
      return const Color(0xFF00B0F0); // SBI Light Blue / Cyan
    }
    // Axis Bank typical ranges -> Axis Burgundy
    else if (['4376', '4375', '4181'].contains(firstFour)) {
      return const Color(0xFF900020); // Axis Burgundy / Pomegranate
    }

    // Default neutral minimal theme
    return const Color(0xFF1C1C1E); // Dark Grey / Black
  }
}
