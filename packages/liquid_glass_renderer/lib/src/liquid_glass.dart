// ignore_for_file: avoid_setters_without_getters

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:liquid_glass_renderer/src/internal/render_liquid_glass_geometry.dart';
import 'package:liquid_glass_renderer/src/internal/transform_tracking_repaint_boundary_mixin.dart';
import 'package:liquid_glass_renderer/src/liquid_glass_render_scope.dart';
import 'package:liquid_glass_renderer/src/rendering/liquid_glass_render_object.dart';
import 'package:liquid_glass_renderer/src/shaders.dart';
import 'package:meta/meta.dart';

/// A liquid glass shape.
///
/// To render liquid glass, you must wrap this in a [LiquidGlassLayer],
/// where the glass effect will be rendered.
///
/// If you only need a single shape with its own settings, you can also use the
/// [LiquidGlass.withOwnLayer] constructor, which will create its own
/// [LiquidGlassLayer] internally.
/// Be mindful that creating many individual layers can be expensive.
///
/// See the [LiquidGlassLayer] documentation for more information.
class LiquidGlass extends StatelessWidget {
  /// Creates a new [LiquidGlass] with the given [child] and [shape].
  ///
  /// This will expect a parent [LiquidGlassLayer] to be present in the widget
  /// tree, where the liquid glass effect will be rendered.
  const LiquidGlass({
    required this.child,
    required this.shape,
    this.frosted,
    this.glassContainsChild = false,
    this.clipBehavior = Clip.hardEdge,
    this.debugLabel,
    super.key,
  }) : ownLayerConfig = null;

  /// Creates a new [LiquidGlass] that creates its own [LiquidGlassLayer].
  ///
  /// While this might seem convenient, creating many individual layers can be
  /// expensive.
  ///
  /// You should prefer rendering multiple [LiquidGlass] shapes that share the
  /// same settings inside a single [LiquidGlassLayer] for better performance.
  const LiquidGlass.withOwnLayer({
    required this.child,
    required this.shape,
    LiquidGlassSettings settings = const LiquidGlassSettings(),
    bool fake = false,
    this.frosted,
    super.key,
    this.glassContainsChild = false,
    this.clipBehavior = Clip.hardEdge,
    this.debugLabel,
  }) : ownLayerConfig = (settings, fake);

  /// The child of this widget.
  ///
  /// You can choose whether this should be rendered "inside" of the glass, or
  /// on top using [glassContainsChild].
  final Widget child;

  /// {@template liquid_glass_renderer.LiquidGlass.shape}
  /// The shape of this glass.
  ///
  /// This is the shape of the glass that will be rendered.
  /// {@endtemplate}
  final LiquidShape shape;

  /// Whether this glass should be rendered "inside" of the glass, or on top.
  ///
  /// If it is rendered inside, the color tint
  /// of the glass will affect the child, and it will also be refracted.
  ///
  /// Defaults to `false`.
  final bool glassContainsChild;

  /// The clip behavior of this glass.
  ///
  /// Defaults to [Clip.hardEdge], so [child] will be clipped to the shape.
  final Clip clipBehavior;

  /// Whether this glass shape should apply backdrop blur (frosted).
  ///
  /// When true, the background behind this shape will be blurred.
  /// When false, only refraction is applied (clear glass).
  ///
  /// If null, uses the default from [LiquidGlassSettings.frosted].
  final bool? frosted;

  /// The settings for this glass if it is supposed to create its own layer.
  final (LiquidGlassSettings settings, bool fake)? ownLayerConfig;

  /// Debug label for logging. When set, enables debug output for FakeGlass.
  final String? debugLabel;

  @override
  Widget build(BuildContext context) {
    // If we have our own layer config, we create our own layer.
    if (ownLayerConfig case (final settings, final fake)) {
      if (fake) {
        return FakeGlass(
          shape: shape,
          settings: settings,
          frosted: frosted,
          debugLabel: debugLabel,
          child: child,
        );
      }

      return LiquidGlassLayer(
        settings: settings,
        child: Builder(builder: _buildGlassContent),
      );
    }

    final useFake = LiquidGlassRenderScope.of(context).useFake;

    if (useFake) {
      return FakeGlass.inLayer(
        shape: shape,
        frosted: frosted,
        debugLabel: debugLabel,
        child: child,
      );
    }

    return _buildGlassContent(context);
  }

  Widget _buildGlassContent(BuildContext context) {
    if (!ImageFilter.isShaderFilterSupported) {
      return FakeGlass.inLayer(
        shape: shape,
        frosted: frosted,
        child: child,
      );
    }

    final settings = LiquidGlassSettings.of(context);
    // Resolve frosted: use widget value if provided, otherwise use settings
    final resolvedFrosted = frosted ?? settings.frosted;

    return ShaderBuilder(
      (context, shader, builtChild) => _RawLiquidGlass(
        shader: shader,
        renderLink: InheritedGeometryRenderLink.of(context)!,
        settings: settings,
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
        shape: shape,
        glassContainsChild: glassContainsChild,
        frosted: resolvedFrosted,
        child: builtChild,
      ),
      assetKey: ShaderKeys.blendedGeometry,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        clipBehavior: clipBehavior,
        child: Opacity(
          opacity: settings.visibility.clamp(0, 1),
          child: GlassGlowLayer(
            child: child,
          ),
        ),
      ),
    );
  }
}

class _RawLiquidGlass extends SingleChildRenderObjectWidget {
  const _RawLiquidGlass({
    required super.child,
    required this.shader,
    required this.renderLink,
    required this.settings,
    required this.devicePixelRatio,
    required this.shape,
    required this.glassContainsChild,
    required this.frosted,
  });

  final FragmentShader shader;
  final GeometryRenderLink renderLink;
  final LiquidGlassSettings settings;
  final double devicePixelRatio;
  final LiquidShape shape;
  final bool glassContainsChild;
  final bool frosted;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderLiquidGlassSingleShape(
      geometryShader: shader,
      renderLink: renderLink,
      settings: settings,
      devicePixelRatio: devicePixelRatio,
      shape: shape,
      glassContainsChild: glassContainsChild,
      frosted: frosted,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderLiquidGlassSingleShape renderObject,
  ) {
    renderObject
      ..renderLink = renderLink
      ..settings = settings
      ..devicePixelRatio = devicePixelRatio
      ..shape = shape
      ..glassContainsChild = glassContainsChild
      ..frosted = frosted;
  }
}

/// Render object for a single liquid glass shape.
///
/// Each shape independently manages its own geometry rendering and caching.
/// This provides better performance than the previous blend group approach,
/// as moving one shape no longer forces other shapes to re-render.
@internal
class RenderLiquidGlassSingleShape extends RenderLiquidGlassGeometry
    with TransformTrackingRenderObjectMixin, LiquidGlassShapeMixin {
  /// Creates a new [RenderLiquidGlassSingleShape].
  RenderLiquidGlassSingleShape({
    required super.renderLink,
    required super.geometryShader,
    required super.settings,
    required super.devicePixelRatio,
    required LiquidShape shape,
    required bool glassContainsChild,
    required bool frosted,
  })  : _shape = shape,
        _glassContainsChild = glassContainsChild,
        _frosted = frosted;

  LiquidShape _shape;

  /// The shape of this glass.
  LiquidShape get shape => _shape;
  set shape(LiquidShape value) {
    if (_shape == value) return;
    _shape = value;
    // Update the path immediately when shape changes
    // (performLayout only runs when size changes)
    if (hasSize) {
      _lastPath = _shape.getOuterPath(Offset.zero & size);
    }
    markGeometryNeedsUpdate(force: true);
    markNeedsPaint();
  }

  bool _glassContainsChild;

  /// Whether the child is rendered inside the glass.
  bool get glassContainsChild => _glassContainsChild;
  set glassContainsChild(bool value) {
    if (_glassContainsChild == value) return;
    _glassContainsChild = value;
    markNeedsPaint();
  }

  bool _frosted;

  /// Whether this shape should apply backdrop blur (frosted glass).
  bool get frosted => _frosted;
  set frosted(bool value) {
    if (_frosted == value) return;
    _frosted = value;
    markGeometryNeedsUpdate(force: true);
    markNeedsPaint();
  }

  late Path _lastPath;

  final _transformLayerHandle = LayerHandle<TransformLayer>();

  @override
  void performLayout() {
    super.performLayout();
    _lastPath = _shape.getOuterPath(Offset.zero & size);
    // Mark geometry needs update when layout changes
    markGeometryNeedsUpdate();
  }

  @override
  void onTransformChanged() {
    markGeometryNeedsUpdate();
    markNeedsPaint();
  }

  @override
  void dispose() {
    _transformLayerHandle.layer = null;
    super.dispose();
  }

  // MARK: RenderLiquidGlassGeometry implementation

  @override
  void updateShaderWithSettings(
    LiquidGlassSettings settings,
    double devicePixelRatio,
  ) {
    geometryShader.setFloatUniforms(initialIndex: 2, (value) {
      value.setFloats([
        settings.refractiveIndex,
        settings.effectiveChromaticAberration,
        settings.effectiveThickness,
        0.0, // blend always 0 for single shapes
      ]);
    });
  }

  @override
  void updateGeometryShaderShapes(List<ShapeGeometry> shapes) {
    if (shapes.isEmpty) return;

    final shapeGeo = shapes.first;
    final center = shapeGeo.shapeBounds.center;
    final shapeSize = shapeGeo.shapeBounds.size;

    geometryShader.setFloatUniforms(initialIndex: 6, (value) {
      value
        ..setFloat(1) // numShapes = 1
        ..setFloat(shapeGeo.rawShapeType.shaderIndex)
        ..setFloat(center.dx * devicePixelRatio)
        ..setFloat(center.dy * devicePixelRatio)
        ..setFloat(shapeSize.width * devicePixelRatio)
        ..setFloat(shapeSize.height * devicePixelRatio)
        ..setFloat(shapeGeo.rawCornerRadius * devicePixelRatio);
    });
  }

  @override
  (Rect, List<ShapeGeometry>, bool) gatherShapeData() {
    if (!hasSize) {
      return (Rect.zero, [], false);
    }

    final bounds = Offset.zero & size;
    final shapeGeometry = ShapeGeometry(
      renderObject: this,
      shape: _shape,
      glassContainsChild: _glassContainsChild,
      shapeBounds: bounds,
      frosted: _frosted,
    );

    // Compare with cached geometry to determine if rebuild needed
    final cached = geometry?.shapes.firstOrNull;
    final needsUpdate = cached == null ||
        cached.shapeBounds != bounds ||
        cached.shape != _shape ||
        cached.frosted != _frosted;

    return (bounds, [shapeGeometry], needsUpdate);
  }

  @override
  void paintShapeContents(
    RenderObject from,
    PaintingContext context,
    Offset offset, {
    required bool insideGlass,
  }) {
    if (_glassContainsChild != insideGlass) return;
    if (!attached) return;

    // Paint child with transform to the requesting render object
    final transform = getTransformTo(from);
    _transformLayerHandle.layer = context.pushTransform(
      needsCompositing,
      offset,
      transform,
      (context, offset) {
        if (child != null) {
          context.paintChild(child!, offset);
        }
      },
      oldLayer: _transformLayerHandle.layer,
    );
  }

  @override
  Path getShapePath() => _lastPath;
}
