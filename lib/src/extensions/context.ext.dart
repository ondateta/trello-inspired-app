import 'package:flutter/material.dart';
import 'package:template/src/design_system/responsive_values.dart';

extension UtilsContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  TextTheme get texts => Theme.of(this).textTheme;
  ThemeData get theme => Theme.of(this);

  Size get screenSize => MediaQuery.of(this).size;
  Orientation get orientation => MediaQuery.of(this).orientation;

  T responsiveV<T>({
    T Function()? mobile,
    T Function()? tablet,
    T Function()? desktop,
    T Function()? orElse,
  }) =>
      responsiveValue(
        this,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
        orElse: orElse,
      );

  T platformV<T>({
    required T Function() orElse,
    T Function()? web,
    T Function()? ios,
    T Function()? android,
    T Function()? windows,
    T Function()? macos,
  }) =>
      platformValue(
        this,
        orElse: orElse,
        web: web,
        ios: ios,
        android: android,
        windows: windows,
        macos: macos,
      );

  T orientationV<T>({
    required T Function() portrait,
    required T Function() landscape,
  }) =>
      orientationValue(
        this,
        portrait: portrait,
        landscape: landscape,
      );
}
