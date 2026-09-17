import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'controllers/pet_controller.dart';
import 'ui/pet_overlay_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WindowManager for Desktop (macOS / Windows / Linux)
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(330, 360),
      center: false,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      title: 'Liil Buddy',
      alwaysOnTop: true,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setAsFrameless();
      await windowManager.setHasShadow(false);
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final controller = await PetController.create();

  runApp(LiilBuddyApp(controller: controller));
}

class LiilBuddyApp extends StatelessWidget {
  final PetController controller;

  const LiilBuddyApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liil Buddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        fontFamily: Platform.isMacOS ? '.SF Pro Text' : 'Segoe UI',
      ),
      home: PetOverlayScreen(controller: controller),
    );
  }
}
