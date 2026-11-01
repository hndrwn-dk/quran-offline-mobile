import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Asset key of the cylindrical fold shader (declared in `pubspec.yaml`).
const String kPageCurlShaderAsset = 'shaders/page_curl.frag';

Future<ui.FragmentProgram?>? _programFuture;

/// Loads the shader program once per process.
///
/// A failed load is cached as `null` so a broken/unsupported shader never stalls
/// every page turn: the painter's mesh fallback takes over.
Future<ui.FragmentProgram?> loadPageCurlProgram() {
  return _programFuture ??= _loadProgram();
}

Future<ui.FragmentProgram?> _loadProgram() async {
  try {
    final program = await ui.FragmentProgram.fromAsset(kPageCurlShaderAsset);
    debugPrint('[MushafCurl] shader program loaded ($kPageCurlShaderAsset)');
    return program;
  } catch (error) {
    debugPrint('[MushafCurl] shader unavailable, CustomPainter fallback: $error');
    return null;
  }
}

/// Creates a shader instance for one painter owner.
///
/// Each instance owns a small uniform block and the two image samplers; the
/// caller disposes it (`FragmentShader.dispose`).
Future<ui.FragmentShader?> loadPageCurlShader() async {
  final program = await loadPageCurlProgram();
  return program?.fragmentShader();
}

/// Test hook: forget the cached program/failure.
@visibleForTesting
void resetPageCurlShaderCache() {
  _programFuture = null;
}
