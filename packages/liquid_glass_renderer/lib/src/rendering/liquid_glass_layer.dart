// ignore_for_file: avoid_setters_without_getters

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:liquid_glass_renderer/src/internal/render_liquid_glass_geometry.dart';
import 'package:liquid_glass_renderer/src/internal/transform_tracking_repaint_boundary_mixin.dart';
import 'package:liquid_glass_renderer/src/liquid_glass_render_scope.dart';
import 'package:liquid_glass_renderer/src/logging.dart';
import 'package:liquid_glass_renderer/src/rendering/fake_glass_effects_mixin.dart';
import 'package:liquid_glass_renderer/src/rendering/liquid_glass_render_object.dart';
import 'package:liquid_glass_renderer/src/shaders.dart';
import 'package:meta/meta.dart';

/// Represents a layer of multiple [LiquidGlass] shapes that have shared
/// [LiquidGlassSettings] and will be rendered together.
///
/// If you create a [LiquidGlassLayer] with one or more [LiquidGlass] widgets,
/// the liquid glass effect will be rendered where this layer is.
///
/// Make sure not to stack any other widgets between the [LiquidGlassLayer] and
/// the [LiquidGlass] widgets, otherwise the liquid glass effect will be behind
/// them.
///
/// ## Example
///
/// ```dart
/// Widget build(BuildContext context) {
///   return LiquidGlassLayer(
///     child: Column(
///       children: [
///         LiquidGlass(
///           shape: LiquidRoundedSuperellipse(
///             borderRadius: 10,
///           ),
///           child: const SizedBox.square(
///             dimension: 100,
///           ),
///         ),
///         const SizedBox(height: 16),
///         LiquidGlass(
///           shape: const LiquidOval(),
///           child: const SizedBox.square(
///             dimension: 100,
///           ),
///         ),
///       ],
///     ),
///   );
/// }
/// ```
class LiquidGlassLayer extends StatefulWidget {
  /// Creates a new [LiquidGlassLayer] with the given [child] and [settings].
  const LiquidGlassLayer({
    required this.child,
    this.settings = const LiquidGlassSettings(),
    this.fake = false,
    this.useBackdropGroup = false,
    super.key,
  });

  /// The subtree in which you should include at least one [LiquidGlass] widget.
  ///
  /// The [LiquidGlassLayer] will automatically register all [LiquidGlass]
  /// widgets in the subtree as shapes and render them.
  final Widget child;

  /// The settings for the liquid glass effect for all shapes in this layer.
  final LiquidGlassSettings settings;

  /// Whether to use fake glass mode (backdrop filters) instead of shaders.
  final bool fake;

  /// Whether to look up the tree for a [BackdropGroup] to use for this layer's
  /// blur.
  ///
  /// If you have multiple [LiquidGlassLayer]s in a subtree that use the same
  /// background blur, setting this to true can improve performance by sharing
  /// the same backdrop.
  ///
  /// If [fake] is true, this will be ignored, as this widget will already use
  /// a shared backdrop for the fake glass effect.
  ///
  /// Defaults to false.
  final bool useBackdropGroup;

  @override
  State<LiquidGlassLayer> createState() => _LiquidGlassLayerState();
}

class _LiquidGlassLayerState extends State<LiquidGlassLayer>
    with SingleTickerProviderStateMixin {
  late final GeometryRenderLink _link = GeometryRenderLink();

  late final logger = Logger(LgrLogNames.layer);

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final useFakeGlass = widget.fake || !ImageFilter.isShaderFilterSupported;

    if (useFakeGlass && !ImageFilter.isShaderFilterSupported) {
      logger.warning(
          'LiquidGlassLayer is only supported when using Impeller at the '
          'moment. Falling back to FakeGlass for LiquidGlassLayer. '
          'To prevent this warning, enable Impeller, or set '
          'LiquidGlassLayer.fake to true before you use liquid glass widgets '
          'on Skia.');
    }

    if (useFakeGlass) {
      // Use the same rendering pipeline as real glass, but with null shader
      // This enables unified widget grouping and layer behavior
      return RepaintBoundary(
        child: LiquidGlassRenderScope(
          settings: widget.settings,
          useFake: true,
          child: InheritedGeometryRenderLink(
            link: _link,
            child: BackdropGroup(
              child: Builder(
                builder: (context) => _RawShapes(
                  renderShader: null,
                  backdropKey: BackdropGroup.of(context)?.backdropKey,
                  settings: widget.settings,
                  link: _link,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: LiquidGlassRenderScope(
        settings: widget.settings,
        child: InheritedGeometryRenderLink(
          link: _link,
          child: ShaderBuilder(
            assetKey: ShaderKeys.liquidGlassRender,
            (context, shader, child) => _RawShapes(
              renderShader: shader,
              backdropKey: widget.useBackdropGroup
                  ? BackdropGroup.of(context)?.backdropKey
                  : null,
              settings: widget.settings,
              link: _link,
              child: child!,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _RawShapes extends SingleChildRenderObjectWidget {
  const _RawShapes({
    required this.renderShader,
    required this.backdropKey,
    required this.settings,
    required Widget super.child,
    required this.link,
  });

  final FragmentShader? renderShader;
  final BackdropKey? backdropKey;
  final LiquidGlassSettings settings;
  final GeometryRenderLink link;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderLiquidGlassLayer(
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      renderShader: renderShader,
      backdropKey: backdropKey,
      settings: settings,
      link: link,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderLiquidGlassLayer renderObject,
  ) {
    renderObject
      ..link = link
      ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context)
      ..renderShader = renderShader
      ..settings = settings
      ..backdropKey = backdropKey;
  }
}

@internal
class RenderLiquidGlassLayer extends LiquidGlassRenderObject
    with TransformTrackingRenderObjectMixin, FakeGlassEffectsMixin {
  RenderLiquidGlassLayer({
    required super.renderShader,
    required super.backdropKey,
    required super.devicePixelRatio,
    required super.settings,
    required super.link,
  });

  @override
  LiquidGlassSettings get fakeGlassSettings => settings;

  final _shaderHandle = LayerHandle<BackdropFilterLayer>();
  final _blurLayerHandle = LayerHandle<BackdropFilterLayer>();
  final _clipPathLayerHandle = LayerHandle<ClipPathLayer>();
  final _clipRectLayerHandle = LayerHandle<ClipRectLayer>();

  // Layer handles for fake glass rendering
  final _fakeGlassBlurLayerHandle = LayerHandle<BackdropFilterLayer>();
  final _fakeGlassFrostedClipPathLayerHandle = LayerHandle<ClipPathLayer>();
  final _fakeGlassNonFrostedClipPathLayerHandle = LayerHandle<ClipPathLayer>();
  final _fakeGlassNonFrostedFilterLayerHandle =
      LayerHandle<BackdropFilterLayer>();

  // Cache for saturation matrix
  double? _cachedSaturationValue;
  List<double>? _cachedSaturationMatrix;
  List<double> _getSaturationMatrix(double saturation) {
    if (_cachedSaturationMatrix != null &&
        _cachedSaturationValue == saturation) {
      return _cachedSaturationMatrix!;
    }
    _cachedSaturationValue = saturation;
    _cachedSaturationMatrix = createSaturationMatrix(saturation);
    return _cachedSaturationMatrix!;
  }

  /// Builds a combined filter for fake glass effects.
  /// Returns null if no filter effects are needed.
  ImageFilter? _buildFakeGlassFilter({
    required bool frosted,
    required Rect bounds,
  }) {
    final baseRefraction = settings.fakeGlassRefraction;
    final refraction = frosted
        ? baseRefraction * settings.fakeGlassRefractionFrostedMultiplier
        : baseRefraction;

    // Use bounding box center for the refraction effect
    final center = bounds.center;

    final refractionFilter = refraction > 0
        ? createRefractionFilter(center, refraction, bounds.size)
        : null;

    // Boost saturation to match real glass shader appearance
    final boostedSaturation =
        (1.0 + (settings.effectiveSaturation - 1.0) * kFakeGlassSaturationMultiplier)
            .clamp(0.0, double.infinity);
    final saturationFilter = boostedSaturation != 1.0
        ? ColorFilter.matrix(_getSaturationMatrix(boostedSaturation))
        : null;

    ImageFilter? combinedFilter;

    if (frosted) {
      final blurFilter = ImageFilter.blur(
        sigmaX: settings.effectiveBlur,
        sigmaY: settings.effectiveBlur,
        tileMode: TileMode.mirror,
      );

      // Compose: refraction -> saturation -> blur
      combinedFilter = blurFilter;
      if (saturationFilter != null) {
        combinedFilter = ImageFilter.compose(
          inner: saturationFilter,
          outer: combinedFilter,
        );
      }
      if (refractionFilter != null) {
        combinedFilter = ImageFilter.compose(
          inner: refractionFilter,
          outer: combinedFilter,
        );
      }
    } else {
      // Non-frosted: only refraction (and optionally saturation)
      combinedFilter = refractionFilter;
      if (saturationFilter != null && combinedFilter != null) {
        combinedFilter = ImageFilter.compose(
          inner: saturationFilter,
          outer: combinedFilter,
        );
      } else if (saturationFilter != null) {
        combinedFilter = saturationFilter;
      }
    }

    return combinedFilter;
  }

  @override
  Size get desiredMatteSize => switch (owner?.rootNode) {
        final RenderView rv => rv.size,
        final RenderBox rb => rb.size,
        _ => Size.zero,
      };

  @override
  Matrix4 get matteTransform => getTransformTo(null);

  @override
  void onTransformChanged() {
    needsGeometryUpdate = true;
    markNeedsPaint();
  }

  final _nonFrostedClipPathLayerHandle = LayerHandle<ClipPathLayer>();

  @override
  void paintLiquidGlass(
    PaintingContext context,
    Offset offset,
    List<(RenderLiquidGlassGeometry, GeometryCache, Matrix4)> shapes,
    Rect boundingBox,
  ) {
    if (!attached) return;

    // Separate shapes into frosted and non-frosted
    final frostedShapes =
        <(RenderLiquidGlassGeometry, GeometryCache, Matrix4)>[];
    final nonFrostedShapes =
        <(RenderLiquidGlassGeometry, GeometryCache, Matrix4)>[];

    for (final shape in shapes) {
      if (!shape.$1.attached) continue;
      final isFrosted = shape.$2.shapes.firstOrNull?.frosted ?? true;
      if (isFrosted) {
        frostedShapes.add(shape);
      } else {
        nonFrostedShapes.add(shape);
      }
    }

    final shaderLayer = (_shaderHandle.layer ??= BackdropFilterLayer())
      ..filter = ImageFilter.shader(renderShader!);

    // 1. Apply blur ONLY to frosted shapes
    if (frostedShapes.isNotEmpty && settings.effectiveBlur > 0) {
      final blurLayer = (_blurLayerHandle.layer ??= BackdropFilterLayer())
        ..backdropKey = backdropKey
        ..filter = ImageFilter.blur(
          tileMode: TileMode.mirror,
          sigmaX: settings.effectiveBlur,
          sigmaY: settings.effectiveBlur,
        );

      final frostedClipPath = Path();
      for (final geometry in frostedShapes) {
        frostedClipPath.addPath(
          geometry.$2.path,
          Offset.zero,
          matrix4: geometry.$3.storage,
        );
      }

      _clipPathLayerHandle.layer = context.pushClipPath(
        needsCompositing,
        offset,
        boundingBox,
        frostedClipPath,
        (context, offset) {
          context.pushLayer(
            blurLayer,
            (context, offset) {
              // Paint inside-glass content for frosted shapes
              paintShapeContents(
                context,
                offset,
                frostedShapes,
                insideGlass: true,
              );
            },
            offset,
          );
        },
        oldLayer: _clipPathLayerHandle.layer,
      );
    } else {
      _blurLayerHandle.layer = null;
      _clipPathLayerHandle.layer = null;
    }

    // 2. Paint inside-glass content for non-frosted shapes (no blur)
    if (nonFrostedShapes.isNotEmpty) {
      final nonFrostedClipPath = Path();
      for (final geometry in nonFrostedShapes) {
        nonFrostedClipPath.addPath(
          geometry.$2.path,
          Offset.zero,
          matrix4: geometry.$3.storage,
        );
      }

      _nonFrostedClipPathLayerHandle.layer = context.pushClipPath(
        needsCompositing,
        offset,
        boundingBox,
        nonFrostedClipPath,
        (context, offset) {
          // Paint inside-glass content for non-frosted shapes (no blur)
          paintShapeContents(
            context,
            offset,
            nonFrostedShapes,
            insideGlass: true,
          );
        },
        oldLayer: _nonFrostedClipPathLayerHandle.layer,
      );
    } else {
      _nonFrostedClipPathLayerHandle.layer = null;
    }

    // 3. Apply shader to ALL shapes
    _clipRectLayerHandle.layer = context.pushClipRect(
      needsCompositing,
      offset,
      boundingBox,
      (context, offset) {
        context.pushLayer(
          shaderLayer,
          (context, offset) {
            paintShapeContents(
              context,
              offset,
              shapes,
              insideGlass: false,
            );
          },
          offset,
        );
      },
      oldLayer: _clipRectLayerHandle.layer,
    );
  }

  @override
  void paintFakeGlass(
    PaintingContext context,
    Offset offset,
    List<(RenderLiquidGlassGeometry, GeometryCache, Matrix4)> shapes,
    Rect boundingBox,
  ) {
    if (!attached) return;

    // Separate shapes into frosted and non-frosted
    final frostedShapes =
        <(RenderLiquidGlassGeometry, GeometryCache, Matrix4)>[];
    final nonFrostedShapes =
        <(RenderLiquidGlassGeometry, GeometryCache, Matrix4)>[];

    for (final shape in shapes) {
      if (!shape.$1.attached) continue;
      final isFrosted = shape.$2.shapes.firstOrNull?.frosted ?? true;
      if (isFrosted) {
        frostedShapes.add(shape);
      } else {
        nonFrostedShapes.add(shape);
      }
    }

    // 1. Apply combined filter (blur + refraction + saturation) to frosted shapes
    if (frostedShapes.isNotEmpty) {
      final combinedFilter = _buildFakeGlassFilter(
        frosted: true,
        bounds: boundingBox,
      );

      final frostedClipPath = Path();
      for (final geometry in frostedShapes) {
        frostedClipPath.addPath(
          geometry.$2.path,
          Offset.zero,
          matrix4: geometry.$3.storage,
        );
      }

      if (combinedFilter != null) {
        final blurLayer =
            (_fakeGlassBlurLayerHandle.layer ??= BackdropFilterLayer())
              ..backdropKey = backdropKey
              ..filter = combinedFilter;

        _fakeGlassFrostedClipPathLayerHandle.layer = context.pushClipPath(
          needsCompositing,
          offset,
          boundingBox,
          frostedClipPath,
          (context, offset) {
            context.pushLayer(
              blurLayer,
              (context, offset) {
                // Paint inside-glass content for frosted shapes
                paintShapeContents(
                  context,
                  offset,
                  frostedShapes,
                  insideGlass: true,
                );

                // Paint fake glass visual effects for each frosted shape
                for (final (_, geometry, transform) in frostedShapes) {
                  final transformedPath =
                      geometry.path.transform(transform.storage);
                  final transformedBounds = MatrixUtils.transformRect(
                    transform,
                    geometry.bounds,
                  );
                  paintFakeGlassEffects(
                    context.canvas,
                    transformedPath,
                    transformedBounds,
                    frosted: true,
                    visibility: settings.visibility,
                  );
                }
              },
              offset,
            );
          },
          oldLayer: _fakeGlassFrostedClipPathLayerHandle.layer,
        );
      } else {
        // No filter needed, just clip and paint
        _fakeGlassBlurLayerHandle.layer = null;
        _fakeGlassFrostedClipPathLayerHandle.layer = context.pushClipPath(
          needsCompositing,
          offset,
          boundingBox,
          frostedClipPath,
          (context, offset) {
            paintShapeContents(
              context,
              offset,
              frostedShapes,
              insideGlass: true,
            );

            for (final (_, geometry, transform) in frostedShapes) {
              final transformedPath =
                  geometry.path.transform(transform.storage);
              final transformedBounds = MatrixUtils.transformRect(
                transform,
                geometry.bounds,
              );
              paintFakeGlassEffects(
                context.canvas,
                transformedPath,
                transformedBounds,
                frosted: true,
                visibility: settings.visibility,
              );
            }
          },
          oldLayer: _fakeGlassFrostedClipPathLayerHandle.layer,
        );
      }
    } else {
      _fakeGlassBlurLayerHandle.layer = null;
      _fakeGlassFrostedClipPathLayerHandle.layer = null;
    }

    // 2. Paint non-frosted shapes (with refraction/saturation but no blur)
    if (nonFrostedShapes.isNotEmpty) {
      final nonFrostedFilter = _buildFakeGlassFilter(
        frosted: false,
        bounds: boundingBox,
      );

      final nonFrostedClipPath = Path();
      for (final geometry in nonFrostedShapes) {
        nonFrostedClipPath.addPath(
          geometry.$2.path,
          Offset.zero,
          matrix4: geometry.$3.storage,
        );
      }

      if (nonFrostedFilter != null) {
        final filterLayer =
            (_fakeGlassNonFrostedFilterLayerHandle.layer ??=
                BackdropFilterLayer())
              ..backdropKey = backdropKey
              ..filter = nonFrostedFilter;

        _fakeGlassNonFrostedClipPathLayerHandle.layer = context.pushClipPath(
          needsCompositing,
          offset,
          boundingBox,
          nonFrostedClipPath,
          (context, offset) {
            context.pushLayer(
              filterLayer,
              (context, offset) {
                // Paint inside-glass content for non-frosted shapes
                paintShapeContents(
                  context,
                  offset,
                  nonFrostedShapes,
                  insideGlass: true,
                );

                // Paint fake glass visual effects for each non-frosted shape
                for (final (_, geometry, transform)
                    in nonFrostedShapes) {
                  final transformedPath =
                      geometry.path.transform(transform.storage);
                  final transformedBounds = MatrixUtils.transformRect(
                    transform,
                    geometry.bounds,
                  );
                  paintFakeGlassEffects(
                    context.canvas,
                    transformedPath,
                    transformedBounds,
                    frosted: false,
                    visibility: settings.visibility,
                  );
                }
              },
              offset,
            );
          },
          oldLayer: _fakeGlassNonFrostedClipPathLayerHandle.layer,
        );
      } else {
        // No filter needed, just clip and paint
        _fakeGlassNonFrostedFilterLayerHandle.layer = null;
        _fakeGlassNonFrostedClipPathLayerHandle.layer = context.pushClipPath(
          needsCompositing,
          offset,
          boundingBox,
          nonFrostedClipPath,
          (context, offset) {
            paintShapeContents(
              context,
              offset,
              nonFrostedShapes,
              insideGlass: true,
            );

            for (final (_, geometry, transform) in nonFrostedShapes) {
              final transformedPath =
                  geometry.path.transform(transform.storage);
              final transformedBounds = MatrixUtils.transformRect(
                transform,
                geometry.bounds,
              );
              paintFakeGlassEffects(
                context.canvas,
                transformedPath,
                transformedBounds,
                frosted: false,
                visibility: settings.visibility,
              );
            }
          },
          oldLayer: _fakeGlassNonFrostedClipPathLayerHandle.layer,
        );
      }
    } else {
      _fakeGlassNonFrostedClipPathLayerHandle.layer = null;
      _fakeGlassNonFrostedFilterLayerHandle.layer = null;
    }

    // 3. Paint outside-glass content for all shapes
    paintShapeContents(context, offset, shapes, insideGlass: false);
  }

  @override
  void dispose() {
    _blurLayerHandle.layer = null;
    _shaderHandle.layer = null;
    _clipPathLayerHandle.layer = null;
    _clipRectLayerHandle.layer = null;
    _nonFrostedClipPathLayerHandle.layer = null;
    _fakeGlassBlurLayerHandle.layer = null;
    _fakeGlassFrostedClipPathLayerHandle.layer = null;
    _fakeGlassNonFrostedClipPathLayerHandle.layer = null;
    _fakeGlassNonFrostedFilterLayerHandle.layer = null;
    super.dispose();
  }
}
