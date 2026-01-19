// ignore_for_file: require_trailing_commas

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:liquid_glass_renderer/src/rendering/fake_glass_effects_mixin.dart';
import 'package:liquid_glass_renderer/src/stretch.dart';
import 'package:meta/meta.dart';

/// A widget that aims to provide a similar look to [LiquidGlass], but without
/// the expensive shader.
class FakeGlass extends StatelessWidget {
  /// Creates a new [FakeGlass] widget with the given [child], [shape], and
  /// [settings].
  const FakeGlass({
    required this.shape,
    required this.child,
    LiquidGlassSettings this.settings = const LiquidGlassSettings(),
    this.frosted,
    this.debugLabel,
    super.key,
  });

  /// Creates a new [FakeGlass] widget that takes settings from the nearest
  /// ancestor [LiquidGlassLayer].
  const FakeGlass.inLayer({
    required this.shape,
    required this.child,
    this.frosted,
    this.debugLabel,
    super.key,
  }) : settings = null;

  /// {@macro liquid_glass_renderer.LiquidGlass.shape}
  final LiquidShape shape;

  /// The settings for the glass effect.
  ///
  /// Some properties will not have any effect, such as `thickness` and
  /// `refractiveIndex`, since there is no actual refraction happening.
  final LiquidGlassSettings? settings;

  /// Whether this glass shape should apply backdrop blur (frosted).
  ///
  /// When true, the background behind this shape will be blurred.
  /// When false, only color tinting and specular highlights are applied.
  ///
  /// If null, uses the default from [LiquidGlassSettings.frosted].
  final bool? frosted;

  /// The child widget that will be displayed inside the glass.
  final Widget child;

  /// Debug label for logging. When set, enables debug output for this instance.
  final String? debugLabel;

  @override
  Widget build(BuildContext context) {
    final settings = this.settings ?? LiquidGlassSettings.of(context);
    // Resolve frosted: use widget value if provided, otherwise use settings
    final resolvedFrosted = frosted ?? settings.frosted;

    // Check if we're inside an active transform (e.g., LiquidStretch drag)
    final isTransforming = LiquidStretchScale.isCurrentlyTransforming(context);

    // If we are in a layer, we accept that layer's backdrop key.
    // BUT: if transforms are active, don't use shared backdrop — it causes
    // coordinate space issues. Use own backdrop instead (always works with local coords).
    final backdropKey = this.settings == null && !isTransforming
        ? BackdropGroup.of(context)?.backdropKey
        : null;

    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: RawFakeGlass(
        shape: shape,
        settings: settings,
        backdropKey: backdropKey,
        frosted: resolvedFrosted,
        debugLabel: debugLabel,
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

@internal
class RawFakeGlass extends SingleChildRenderObjectWidget {
  const RawFakeGlass({
    required this.shape,
    required super.child,
    required this.frosted,
    this.backdropKey,
    this.settings = const LiquidGlassSettings(),
    this.debugLabel,
    super.key,
  });

  final LiquidShape shape;

  final LiquidGlassSettings settings;

  final BackdropKey? backdropKey;

  final bool frosted;

  final String? debugLabel;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderFakeGlass(
      shape: shape,
      settings: settings,
      backdropKey: backdropKey,
      frosted: frosted,
      debugLabel: debugLabel,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderObject renderObject) {
    if (renderObject is RenderFakeGlass) {
      renderObject
        ..shape = shape
        ..settings = settings
        ..backdropKey = backdropKey
        ..frosted = frosted
        ..debugLabel = debugLabel;
    }
  }
}

@internal
class RenderFakeGlass extends RenderProxyBox with FakeGlassEffectsMixin {
  RenderFakeGlass({
    required LiquidShape shape,
    required LiquidGlassSettings settings,
    required BackdropKey? backdropKey,
    required bool frosted,
    required String? debugLabel,
  })  : _shape = shape,
        _settings = settings,
        _backdropKey = backdropKey,
        _frosted = frosted,
        _debugLabel = debugLabel,
        _usesSharedBackdrop = backdropKey != null;

  LiquidShape _shape;
  LiquidShape get shape => _shape;
  set shape(LiquidShape value) {
    if (_shape == value) return;
    _shape = value;
    markNeedsPaint();
  }

  LiquidGlassSettings _settings;
  LiquidGlassSettings get settings => _settings;
  set settings(LiquidGlassSettings value) {
    if (_settings == value) return;
    _settings = value;
    invalidateFakeGlassCache();
    markNeedsPaint();
  }

  @override
  LiquidGlassSettings get fakeGlassSettings => _settings;

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

  BackdropKey? _backdropKey;
  BackdropKey? get backdropKey => _backdropKey;
  set backdropKey(BackdropKey? value) {
    if (_backdropKey == value) return;
    _backdropKey = value;
    _usesSharedBackdrop = value != null;
    markNeedsPaint();
  }

  /// Whether this FakeGlass uses a shared backdrop (via BackdropGroup).
  /// When true, filter coordinates are relative to the BackdropGroup.
  /// When false, filter coordinates are local to this widget.
  bool _usesSharedBackdrop;

  String? _debugLabel;
  set debugLabel(String? value) {
    _debugLabel = value;
  }

  bool _frosted;
  bool get frosted => _frosted;
  set frosted(bool value) {
    if (_frosted == value) return;
    _frosted = value;
    markNeedsPaint();
  }

  // Note: Filter caching was removed due to visual glitches.
  // The BackdropFilterLayer appears to need fresh filter instances
  // to properly apply effects when the backdrop changes.

  @override
  bool get alwaysNeedsCompositing =>
      _frosted || settings.fakeGlassRefraction > 0;

  @override
  BackdropFilterLayer? get layer => super.layer as BackdropFilterLayer?;

  @override
  void paint(PaintingContext context, Offset offset) {
    final path = shape.getOuterPath(offset & size);
    final bounds = offset & size;

    // Check if we need any backdrop filter at all
    final needsFilter = _frosted || settings.fakeGlassRefraction > 0;
    if (!needsFilter) {
      paintFakeGlassEffects(
        context.canvas,
        path,
        bounds,
        frosted: _frosted,
        visibility: settings.visibility,
      );
      super.paint(context, offset);
      return;
    }

    // Skip backdrop filter at low visibility to avoid layer destruction
    // flicker. BackdropFilterLayer removal causes a visual glitch in Impeller;
    // by releasing the layer before the widget is removed, we avoid this.
    if (settings.visibility < 0.05) {
      paintFakeGlassEffects(
        context.canvas,
        path,
        bounds,
        frosted: _frosted,
        visibility: settings.visibility,
      );
      super.paint(context, offset);
      return;
    }

    // Build the filter fresh each frame to avoid stale cache issues
    final combinedFilter = _buildCombinedFilter(bounds);

    if (combinedFilter == null) {
      paintFakeGlassEffects(
        context.canvas,
        path,
        bounds,
        frosted: _frosted,
        visibility: settings.visibility,
      );
      super.paint(context, offset);
      return;
    }

    final layer = (this.layer ??= BackdropFilterLayer())
      ..filter = combinedFilter
      ..blendMode = BlendMode.srcATop
      ..backdropKey = backdropKey;

    context.pushLayer(
      layer,
      (context, offset) {
        // Always disable raster cache when using refraction filter
        // to ensure the filter updates properly during transforms
        context.setWillChangeHint();
        paintFakeGlassEffects(
          context.canvas,
          path,
          offset & size,
          frosted: _frosted,
          visibility: settings.visibility,
        );
        super.paint(context, offset);
      },
      offset,
    );
  }

  /// Builds the combined filter based on current settings.
  /// Returns null if no filter is needed.
  ui.ImageFilter? _buildCombinedFilter(Rect bounds) {
    // Create magnification filter for fake refraction effect
    // Apply frosted multiplier when frosted for more pronounced effect
    final baseRefraction = settings.fakeGlassRefraction;
    final refraction = _frosted
        ? baseRefraction * settings.fakeGlassRefractionFrostedMultiplier
        : baseRefraction;

    // Coordinate space depends on backdrop mode:
    // - Shared backdrop (static): coordinates in BackdropGroup space
    // - Own backdrop (standalone or during transforms): local coordinates
    final center = _usesSharedBackdrop
        ? bounds.center
        : Offset(size.width / 2, size.height / 2);

    // Skip saturation and refraction filters during animation (visibility < 1.0)
    // to avoid Impeller trembling.
    //
    // See: docs/flutter_backdrop_filter_layer_flicker.md
    const isAnimating = false; //settings.visibility < 1.0;

    final refractionFilter = !isAnimating && refraction > 0
        ? createRefractionFilter(center, refraction, size)
        : null;

    // Boost saturation to match real glass shader appearance
    // Clamp to >= 0 to avoid negative values that would invert colors
    final boostedSaturation =
        (1.0 + (settings.effectiveSaturation - 1.0) * kFakeGlassSaturationMultiplier)
            .clamp(0.0, double.infinity);
    final saturationFilter = !isAnimating && boostedSaturation != 1.0
        ? ui.ColorFilter.matrix(
            _getSaturationMatrix(boostedSaturation),
          )
        : null;

    ui.ImageFilter? combinedFilter;

    if (_frosted) {
      final blurFilter = ui.ImageFilter.blur(
        sigmaX: settings.effectiveBlur,
        sigmaY: settings.effectiveBlur,
        tileMode: TileMode.mirror,
      );

      // Compose: refraction -> saturation -> blur
      combinedFilter = blurFilter;
      if (saturationFilter != null) {
        combinedFilter = ui.ImageFilter.compose(
          inner: saturationFilter,
          outer: combinedFilter,
        );
      }
      if (refractionFilter != null) {
        combinedFilter = ui.ImageFilter.compose(
          inner: refractionFilter,
          outer: combinedFilter,
        );
      }
    } else {
      // Non-frosted: only refraction (and optionally saturation)
      combinedFilter = refractionFilter;
      if (saturationFilter != null && combinedFilter != null) {
        combinedFilter = ui.ImageFilter.compose(
          inner: saturationFilter,
          outer: combinedFilter,
        );
      }
    }

    return combinedFilter;
  }
}
