import 'package:flutter/material.dart';
import 'package:template/src/extensions/index.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 80,
    this.tooltip,
  });

  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    // TODO: change darkMode and lightMode with app logo
    final darkMode = FlutterLogo(
      size: size,
    );
    final lightMode = FlutterLogo(
      size: size,
    );

    if (context.isDarkMode) {
      return darkMode.tooltip(tooltip ?? 'Teta');
    }
    return lightMode.tooltip(tooltip ?? 'Teta');
  }
}
