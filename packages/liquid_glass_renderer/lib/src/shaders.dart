// ignore_for_file: public_member_api_docs

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:meta/meta.dart';

final String _shadersRoot =
    !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')
        ? ''
        : 'packages/liquid_glass_plus/';

@internal
abstract class ShaderKeys {
  const ShaderKeys._();

  static final blendedGeometry =
      '${_shadersRoot}lib/assets/shaders/liquid_glass_geometry_blended.frag';

  static final liquidGlassRender =
      '${_shadersRoot}lib/assets/shaders/liquid_glass_final_render.frag';
}
