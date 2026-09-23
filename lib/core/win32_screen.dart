import 'dart:ffi' hide Size;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Win32 FFI bindings — only loaded on Windows
// ---------------------------------------------------------------------------

typedef _GetSystemMetricsC = Int32 Function(Int32 nIndex);
typedef _GetSystemMetricsDart = int Function(int nIndex);

typedef _GetDpiForSystemC = Uint32 Function();
typedef _GetDpiForSystemDart = int Function();

typedef _FindWindowExAC = IntPtr Function(
    IntPtr hWndParent, IntPtr hWndChildAfter, Pointer<Utf8> lpszClass, Pointer<Utf8> lpszWindow);
typedef _FindWindowExADart = int Function(
    int hWndParent, int hWndChildAfter, Pointer<Utf8> lpszClass, Pointer<Utf8> lpszWindow);

typedef _SetWindowPosC = Int32 Function(
    IntPtr hWnd, IntPtr hWndInsertAfter, Int32 X, Int32 Y, Int32 cx, Int32 cy, Uint32 uFlags);
typedef _SetWindowPosDart = int Function(
    int hWnd, int hWndInsertAfter, int X, int Y, int cx, int cy, int uFlags);

// SM_CXSCREEN / SM_CYSCREEN — physical pixel dimensions of the primary monitor
const int _smCxScreen = 0;
const int _smCyScreen = 1;

// USER_DEFAULT_SCREEN_DPI
const int _defaultDpi = 96;

// SWP flags: ignore Z-order, do not activate
const int _swpNoActivate = 0x0010;
const int _swpFrameChanged = 0x0020;

// HWND_TOPMOST
const int _hwndTopmost = -1;

// Flutter Win32 window class name (from win32_window.cpp)
const String _flutterWindowClass = 'FLUTTER_RUNNER_WIN32_WINDOW';

/// Reads the primary monitor's physical pixel dimensions and system DPI via
/// Win32 APIs, then positions and sizes the Flutter window to cover the exact
/// monitor rect without relying on window_manager's setSize/setFullScreen
/// (which have a pre-initialization devicePixelRatio = 1.0 bug).
///
/// Returns the logical-pixel [Size] so callers can pass it to setScreenBounds.
/// On non-Windows platforms returns [fallback] unchanged.
Size coverFullScreenWin32({Size fallback = const Size(1920, 1080)}) {
  if (!Platform.isWindows) return fallback;

  try {
    final user32 = DynamicLibrary.open('user32.dll');

    final getSystemMetrics =
        user32.lookupFunction<_GetSystemMetricsC, _GetSystemMetricsDart>('GetSystemMetrics');

    final getDpiForSystem =
        user32.lookupFunction<_GetDpiForSystemC, _GetDpiForSystemDart>('GetDpiForSystem');

    final findWindowExA =
        user32.lookupFunction<_FindWindowExAC, _FindWindowExADart>('FindWindowExA');

    final setWindowPos =
        user32.lookupFunction<_SetWindowPosC, _SetWindowPosDart>('SetWindowPos');

    // Physical pixel dimensions of the primary display
    final physW = getSystemMetrics(_smCxScreen);
    final physH = getSystemMetrics(_smCyScreen);

    // System DPI (e.g. 96 = 100%, 120 = 125%, 144 = 150%)
    final dpi = getDpiForSystem();
    final scale = dpi / _defaultDpi;

    // Logical pixel dimensions Flutter's layout engine will see
    final logicalSize = Size(physW / scale, physH / scale);

    debugPrint(
        'Win32Screen: $physW×$physH physical, DPI=$dpi (${(scale * 100).round()}%), '
        'logical=${logicalSize.width.round()}×${logicalSize.height.round()}');

    // Find our window by class name
    final classNamePtr = _flutterWindowClass.toNativeUtf8();
    try {
      final hwnd = findWindowExA(0, 0, classNamePtr, nullptr.cast<Utf8>());
      if (hwnd != 0) {
        // Position at (0,0) with exact physical dimensions; HWND_TOPMOST keeps
        // it above other windows. SWP_FRAMECHANGED forces the window to re-query
        // its non-client metrics (important after setAsFrameless strips the chrome).
        setWindowPos(
          hwnd,
          _hwndTopmost,
          0, 0,          // x, y
          physW, physH,  // physical pixel width & height
          _swpNoActivate | _swpFrameChanged,
        );
      } else {
        debugPrint('Win32Screen: FindWindowExA returned 0 — window not found yet');
      }
    } finally {
      calloc.free(classNamePtr);
    }

    return logicalSize;
  } catch (e) {
    debugPrint('Win32Screen: error — $e');
    return fallback;
  }
}
