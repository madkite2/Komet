import 'package:flutter/material.dart';

class AppLiquidGlass {
  static const bool enabled = true;

  static const double blurSigma = 14;
  static const double spread = 0.3;
  static const double refraction = 9;
  static const double chroma = 0;
  static const double specular = 0.3;
  static const double rimWidth = 4;
  static const Offset light = Offset(-0.4, -1);
  static const double tintFeather = 2;

  static Color navTint(ColorScheme cs) =>
      cs.surface.withValues(alpha: 0.52);

  static Color panelTint(ColorScheme cs) => cs.surface.withValues(alpha: 0.46);
}
