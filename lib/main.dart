import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:template/config/supabase_config.dart';
import 'package:template/router.dart';
import 'package:template/src/design_system/themes.dart';
import 'package:template/src/views/splash_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      debugShowFloatingThemeButton: true,
      initial: AdaptiveThemeMode.system,
      light: AppThemes.getTheme(Brightness.light),
      dark: AppThemes.getTheme(Brightness.dark),
      builder: (lightTheme, darkTheme) {
        return MaterialApp.router(
          title: 'Trello Clone',
          theme: lightTheme,
          darkTheme: darkTheme,
          routerConfig: router,
          builder: (context, child) => GateWay(
            child: child ?? SplashView(),
          ),
        );
      },
    );
  }
}

class GateWay extends StatefulWidget {
  const GateWay({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<GateWay> createState() => _GateWayState();
}

class _GateWayState extends State<GateWay> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}