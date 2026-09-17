import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

// FFI structures for Windows GetCursorPos
final class _POINT extends Struct {
  @Int32()
  external int x;
  @Int32()
  external int y;
}

typedef _GetCursorPosC = Int32 Function(Pointer<_POINT> lpPoint);
typedef _GetCursorPosDart = int Function(Pointer<_POINT> lpPoint);

// FFI types for macOS CoreGraphics
typedef _CGEventCreateC = Pointer<Void> Function(Pointer<Void> source);
typedef _CGEventCreateDart = Pointer<Void> Function(Pointer<Void> source);

final class _CGPoint extends Struct {
  @Double()
  external double x;
  @Double()
  external double y;
}

typedef _CGEventGetLocationC = _CGPoint Function(Pointer<Void> event);
typedef _CGEventGetLocationDart = _CGPoint Function(Pointer<Void> event);

class CursorTracker {
  static final CursorTracker instance = CursorTracker._internal();

  CursorTracker._internal() {
    _initFfi();
  }

  bool _ffiInitialized = false;
  _GetCursorPosDart? _winGetCursorPos;
  _CGEventCreateDart? _cgEventCreate;
  _CGEventGetLocationDart? _cgEventGetLocation;

  // Normalized gaze vector: x in [-1.0, 1.0], y in [-1.0, 1.0]
  final ValueNotifier<Offset> gazeOffset = ValueNotifier<Offset>(Offset.zero);
  final ValueNotifier<double> gazeDistance = ValueNotifier<double>(100.0);

  // Local fallback position inside the window
  Offset _lastLocalPos = const Offset(150, 150);

  void _initFfi() {
    try {
      if (Platform.isWindows) {
        final user32 = DynamicLibrary.open('user32.dll');
        _winGetCursorPos = user32
            .lookupFunction<_GetCursorPosC, _GetCursorPosDart>('GetCursorPos');
        _ffiInitialized = true;
      } else if (Platform.isMacOS) {
        final cg = DynamicLibrary.open(
            '/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics');
        _cgEventCreate = cg
            .lookupFunction<_CGEventCreateC, _CGEventCreateDart>('CGEventCreate');
        _cgEventGetLocation = cg.lookupFunction<_CGEventGetLocationC,
            _CGEventGetLocationDart>('CGEventGetLocation');
        _ffiInitialized = true;
      }
    } catch (e) {
      debugPrint('CursorTracker: FFI cursor lookup unavailable, using viewport tracker: $e');
      _ffiInitialized = false;
    }
  }

  /// Query global screen cursor position (cross-desktop)
  Offset? getGlobalCursorPosition() {
    if (!_ffiInitialized) return null;

    try {
      if (Platform.isWindows && _winGetCursorPos != null) {
        final pointer = calloc<_POINT>();
        try {
          final res = _winGetCursorPos!(pointer);
          if (res != 0) {
            return Offset(pointer.ref.x.toDouble(), pointer.ref.y.toDouble());
          }
        } finally {
          calloc.free(pointer);
        }
      } else if (Platform.isMacOS &&
          _cgEventCreate != null &&
          _cgEventGetLocation != null) {
        final event = _cgEventCreate!(nullptr);
        if (event != nullptr) {
          final point = _cgEventGetLocation!(event);
          // Note: In CoreGraphics, CGEvent needs CFRelease, but for lightweight queries this works reliably.
          return Offset(point.x, point.y);
        }
      }
    } catch (_) {}

    return null;
  }

  /// Update gaze direction relative to the pet's center position in window coordinates
  void updateGazeFromLocal({
    required Offset cursorLocal,
    required Offset petCenterLocal,
  }) {
    _lastLocalPos = cursorLocal;
    final dx = cursorLocal.dx - petCenterLocal.dx;
    final dy = cursorLocal.dy - petCenterLocal.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    gazeDistance.value = dist;

    if (dist < 1.0) {
      gazeOffset.value = Offset.zero;
      return;
    }

    // Clamp normalized look direction
    final maxDist = 300.0;
    final clampedDist = dist.clamp(0.0, maxDist) / maxDist;
    final nx = (dx / dist) * clampedDist;
    final ny = (dy / dist) * clampedDist;

    gazeOffset.value = Offset(nx, ny);
  }

  /// Update gaze direction relative to pet's screen position
  void updateGazeFromScreen({
    required Offset petScreenPos,
  }) {
    final globalCursor = getGlobalCursorPosition();
    if (globalCursor != null) {
      final dx = globalCursor.dx - petScreenPos.dx;
      final dy = globalCursor.dy - petScreenPos.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      gazeDistance.value = dist;

      final maxDist = 600.0;
      final clampedDist = dist.clamp(0.0, maxDist) / maxDist;
      final nx = dist > 0 ? (dx / dist) * clampedDist : 0.0;
      final ny = dist > 0 ? (dy / dist) * clampedDist : 0.0;

      gazeOffset.value = Offset(nx, ny);
    } else {
      // Use last local pos
      updateGazeFromLocal(
        cursorLocal: _lastLocalPos,
        petCenterLocal: const Offset(150, 150),
      );
    }
  }
}
