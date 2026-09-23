import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
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

    try {
      final primaryDisplay = await screenRetriever.getPrimaryDisplay();
      displaySize = primaryDisplay.size;
    } catch (e) {
      debugPrint('ScreenRetriever display detection: $e');
    }

    final windowOptions = WindowOptions(
      size: displaySize,
      center: false,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      title: 'And Friend',
      alwaysOnTop: true,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      // Remove chrome/decorations so the requested rect covers client area.
      await windowManager.setAsFrameless();
      await windowManager.setHasShadow(false);
      await windowManager.setBackgroundColor(Colors.transparent);

      if (Platform.isWindows) {
        // Read the primary monitor's physical pixel rect via Win32 APIs
        displaySize = coverFullScreenWin32(fallback: displaySize);
      } else if (Platform.isMacOS) {
        // On macOS, position overlay across primary display without triggering native Spaces
        await windowManager.setPosition(Offset.zero);
        await windowManager.setSize(displaySize);
        await windowManager.setAlwaysOnTop(true);
      } else if (Platform.isLinux) {
        await windowManager.setFullScreen(true);
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
