import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'controllers/pet_controller.dart';
import 'core/win32_screen.dart';
import 'ui/pet_overlay_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Size displaySize = const Size(1920, 1080);

  // Initialize WindowManager for Desktop (macOS / Windows / Linux)
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();

    // Minimal WindowOptions — actual size/position is set natively below.
    // Using a sane initial size avoids a briefly visible mis-sized window.
    const windowOptions = WindowOptions(
      size: Size(1920, 1080),
      center: false,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      title: 'And Friend',
      alwaysOnTop: true,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      // Remove Win32 chrome (WS_OVERLAPPEDWINDOW) before we size the window,
      // so the entire requested rect becomes client area.
      await windowManager.setAsFrameless();
      await windowManager.setHasShadow(false);
      await windowManager.setBackgroundColor(Colors.transparent);

      if (Platform.isWindows) {
        // Read the primary monitor's physical pixel rect via Win32 APIs
        // (GetSystemMetrics + GetDpiForSystem) and call SetWindowPos directly.
        // This bypasses window_manager's setSize/setFullScreen, which both
        // read window.devicePixelRatio before Flutter initialises it (defaults
        // to 1.0), causing the window to be sized in physical pixels instead
        // of logical pixels and ending up smaller than the screen.
        displaySize = coverFullScreenWin32(fallback: displaySize);
      } else if (Platform.isMacOS || Platform.isLinux) {
        // On macOS/Linux, window_manager.setFullScreen works correctly.
        await windowManager.setFullScreen(true);
        // MediaQuery will give us the real logical size after show(); use a
        // reasonable fallback for setScreenBounds until the first frame.
      }

      // Start in pass-through mode — clicks fall through to desktop apps.
      await windowManager.setIgnoreMouseEvents(true, forward: true);
      await windowManager.show();
    });
  }

  final controller = await PetController.create();
  controller.setScreenBounds(displaySize);

  runApp(AndFriendApp(controller: controller));
}

class AndFriendApp extends StatelessWidget {
  final PetController controller;

  const AndFriendApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'And Friend',
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
