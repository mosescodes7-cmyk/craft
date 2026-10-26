import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';

import 'screens.dart';
import 'splash_screen.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  runApp(
    DevicePreview(
      enabled: false, // Set to false to disable in production
      builder: (context) => const CraftApp(),
    ),
  );
}

class CraftApp extends StatelessWidget {
  const CraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'Craft Orders',
      debugShowCheckedModeBanner: false,
      theme: darkTheme(),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Ensure splash screen shows for at least 5 seconds
    await Future.wait([
      store.load(),
      Future.delayed(const Duration(seconds: 5)),
    ]);

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SplashScreen();
    }
    return const Shell();
  }
}
