import 'package:flutter/material.dart';
import 'package:template/src/design_system/app_logo.dart';
import 'package:template/src/extensions/index.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AppLogo(),
            16.gap,
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}
