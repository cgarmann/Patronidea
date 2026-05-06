import 'package:flutter/material.dart';

abstract final class AppColors {
  static const cream = Color(0xFFF8F3E8);
  static const creamDeep = Color(0xFFEFE5D3);
  static const surface = Color(0xFFFFFCF6);
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const line = Color(0xFFE2D7C5);
  static const ink = Color(0xFF071B2F);
  static const graphite = Color(0xFF6D756D);

  static const green = Color(0xFF0FA36B);
  static const greenDark = Color(0xFF087A53);
  static const greenSoft = Color(0xFFE8F6EF);
  static const teal = Color(0xFF00A6A6);
  static const blue = Color(0xFF1557C0);

  static const terracotta = Color(0xFFD15F3C);
  static const ochre = Color(0xFFF4A261);
  static const patinaTeal = Color(0xFF2A9D8F);
  static const volcanic950 = Color(0xFF1C1917);
  static const volcanic900 = Color(0xFF292524);
  static const volcanic800 = Color(0xFF44403C);
  static const labBlack = Color(0xFF100D0C);
  static const labPanel = Color(0xFF171311);
  static const labPanelRaised = Color(0xFF1F1916);
  static const labLine = Color(0xFF332A25);
  static const labMuted = Color(0xFF8D8178);

  static const success = green;
  static const warning = Color(0xFFD68A16);
  static const error = Color(0xFFD83A34);

  // Compatibility aliases for screens that are still being migrated.
  static const cyan = green;
  static const accentTint = greenSoft;
  static const purple = blue;
  static const purpleLight = Color(0xFF5C8DF6);
  static const labAccent = green;
  static const labAccentSoft = greenSoft;
  static const lightBg = cream;
  static const lightSurface = surfaceRaised;
  static const lightCard = surfaceRaised;
  static const lightBorder = line;
  static const lightText = ink;
  static const lightSubtext = graphite;
  static const paper = cream;
  static const paperSurface = surface;
  static const paperLine = line;
  static const leather = greenDark;
  static const rust = warning;
  static const blueprint = blue;

  static const darkBg = Color(0xFF06140F);
  static const darkSurface = Color(0xFF0B1D16);
  static const darkCard = Color(0xFF10271E);
  static const darkBorder = Color(0xFF254336);
  static const darkText = Color(0xFFF4F7F2);
  static const darkSubtext = Color(0xFFAAB8AD);

  static const gradientCyan = LinearGradient(
    colors: [green, teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientPurple = LinearGradient(
    colors: [greenDark, blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientHero = LinearGradient(
    colors: [green, teal, blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
