// ignore_for_file: require_trailing_commas

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
// ignore: implementation_imports
import 'package:liquid_glass_renderer/src/stretch.dart' show LiquidStretchScale;
import 'package:meta/meta.dart';

/// Debug toggle for FakeGlass depth gradient effect.
/// Set to false to disable and compare the visual difference.
const _kEnableDepthGradient = true;

// =============================================================================
// TUNING CONSTANTS - Hot reload friendly! Adjust and save to see changes.
// =============================================================================

// -- Inner Edge Shadow --
/// Divisor for shadow width (higher = thinner). shadowWidth = thickness / this
const _kShadowWidthDivisor = 5.0;

/// Min/max shadow width in pixels
const _kShadowWidthMin = 1.0;
const _kShadowWidthMax = 4.0;

/// Divisor for shadow alpha (higher = more transparent). alpha = thickness / this
const _kShadowAlphaDivisor = 200.0;

/// Min/max shadow alpha (0.0 - 1.0)
const _kShadowAlphaMin = 0.02;
const _kShadowAlphaMax = 0.08;

// -- Specular Highlights --
/// Min/max stroke width for sharp specular line
const _kSpecularStrokeMin = 2.0;
const _kSpecularStrokeMax = 2.7;

/// Alpha multiplier for sharp specular (0.0 - 1.0)
const _kSpecularAlpha = 0.7;

/// Divisor for overlay blur sigma (higher = less blur)
const _kSpecularBlurDivisor = 5.0;

/// Divisor for overlay stroke width (higher = thinner)
const _kSpecularOverlayWidthDivisor = 1.9;

/// Multiplier for overlay width divisor when frosted (higher = thinner)
const _kSpecularOverlayFrostedMultiplier = 1.5;

/// Alpha multiplier for blurred overlay (0.0 - 1.0)
const _kSpecularOverlayAlpha = 1.0;

// -- Depth Gradient --
/// Multiplier for gradient alpha based on light intensity
const _kDepthGradientAlphaMultiplier = .1;

/// Min/max gradient alpha (0.0 - 1.0)
const _kDepthGradientAlphaMin = 0.2;
const _kDepthGradientAlphaMax = 0.9;

/// Ratio for dark side alpha relative to light side (0.0 - 1.0)
const _kDepthGradientDarkRatio = 0.7;

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
    super.key,
  });

  /// Creates a new [FakeGlass] widget that takes settings from the nearest
  /// ancestor [LiquidGlassLayer].
  const FakeGlass.inLayer({
    required this.shape,
    required this.child,
    this.frosted,
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

  @override
  Widget build(BuildContext context) {
    final settings = this.settings ?? LiquidGlassSettings.of(context);
    // Resolve frosted: use widget value if provided, otherwise use settings
    final resolvedFrosted = frosted ?? settings.frosted;

    // Use local coordinates if inside a LiquidStretch (even when not actively
    // transforming) to ensure correct refraction center calculation.
    final isTransforming = LiquidStretchScale.isInsideStretch(context);

    // If we are in a layer, we accept that layer's backdrop key.
    final backdropKey =
        this.settings == null ? BackdropGroup.of(context)?.backdropKey : null;
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: RawFakeGlass(
        shape: shape,
        settings: settings,
        backdropKey: backdropKey,
        frosted: resolvedFrosted,
        isTransforming: isTransforming,
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
    required this.isTransforming,
    this.backdropKey,
    this.settings = const LiquidGlassSettings(),
    super.key,
  });

  final LiquidShape shape;

  final LiquidGlassSettings settings;

  final BackdropKey? backdropKey;

  final bool frosted;

  final bool isTransforming;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderFakeGlass(
      shape: shape,
      settings: settings,
      backdropKey: backdropKey,
      frosted: frosted,
      isTransforming: isTransforming,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderObject renderObject) {
    if (renderObject is _RenderFakeGlass) {
      renderObject
        ..shape = shape
        ..settings = settings
        ..backdropKey = backdropKey
        ..frosted = frosted
        ..isTransforming = isTransforming;
    }
  }
}

class _RenderFakeGlass extends RenderProxyBox {
  _RenderFakeGlass({
    required LiquidShape shape,
    required LiquidGlassSettings settings,
    required BackdropKey? backdropKey,
    required bool frosted,
    required bool isTransforming,
  })  : _shape = shape,
        _settings = settings,
        _backdropKey = backdropKey,
        _frosted = frosted,
        _isTransforming = isTransforming;

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
    _cachedLuminance = null; // Invalidate cache
    markNeedsPaint();
  }

  // Cache for expensive computeLuminance() call
  double? _cachedLuminance;
  double get _glassColorLuminance {
    return _cachedLuminance ??= settings.effectiveGlassColor.computeLuminance();
  }

  // Cache for saturation matrix
  double? _cachedSaturationValue;
  List<double>? _cachedSaturationMatrix;
  List<double> _getSaturationMatrix(double saturation) {
    if (_cachedSaturationMatrix != null &&
        _cachedSaturationValue == saturation) {
      return _cachedSaturationMatrix!;
    }
    _cachedSaturationValue = saturation;
    _cachedSaturationMatrix = _createSaturationMatrix(saturation);
    return _cachedSaturationMatrix!;
  }

  BackdropKey? _backdropKey;
  BackdropKey? get backdropKey => _backdropKey;
  set backdropKey(BackdropKey? value) {
    if (_backdropKey == value) return;
    _backdropKey = value;
    markNeedsPaint();
  }

  bool _frosted;
  bool get frosted => _frosted;
  set frosted(bool value) {
    if (_frosted == value) return;
    _frosted = value;
    markNeedsPaint();
  }

  bool _isTransforming;
  bool get isTransforming => _isTransforming;
  set isTransforming(bool value) {
    if (_isTransforming == value) return;
    _isTransforming = value;
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
      _paintGlassEffects(context.canvas, path, bounds);
      super.paint(context, offset);
      return;
    }

    // Skip backdrop filter at low visibility to avoid layer destruction
    // flicker. BackdropFilterLayer removal causes a visual glitch in Impeller;
    // by releasing the layer before the widget is removed, we avoid this.
    if (settings.visibility < 0.05) {
      _paintGlassEffects(context.canvas, path, bounds);
      super.paint(context, offset);
      return;
    }

    // Build the filter fresh each frame to avoid stale cache issues
    final combinedFilter = _buildCombinedFilter(bounds);

    if (combinedFilter == null) {
      _paintGlassEffects(context.canvas, path, bounds);
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
        _paintGlassEffects(context.canvas, path, offset & size);
        super.paint(context, offset);
      },
      offset,
    );
  }

  /// Paints all glass visual effects (color, depth, shadow, specular).
  ///
  /// Effects are scaled by visibility to fade out smoothly with the content.
  void _paintGlassEffects(Canvas canvas, Path path, Rect bounds) {
    final visibility = settings.visibility;
    // Skip painting effects at very low visibility to prevent flicker
    if (visibility < 0.05) return;

    // Apply visibility as opacity to all effects
    if (visibility < 1.0) {
      canvas.saveLayer(
          bounds,
          Paint()
            ..color = Color.fromARGB(
              (255 * visibility).round(),
              255,
              255,
              255,
            ));
    }

    _paintColor(canvas, path);
    _paintDepthGradient(canvas, path, bounds);
    _paintInnerEdgeShadow(canvas, path, bounds);
    _paintSpecular(canvas, path, bounds);

    if (visibility < 1.0) {
      canvas.restore();
    }
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
    // Compensate for LiquidStretch transform.
    // - When not transforming (static): bounds.center works
    // - When transforming (scale or stretch active): localCenter works
    final localCenter = Offset(size.width / 2, size.height / 2);
    final center = _isTransforming ? localCenter : bounds.center;

    // Skip saturation and refraction filters during animation (visibility < 1.0)
    // to avoid Impeller trembling.
    //
    // See: docs/flutter_backdrop_filter_layer_flicker.md
    const isAnimating = false; //settings.visibility < 1.0;

    final refractionFilter = !isAnimating && refraction > 0
        ? _createRefractionFilter(center, refraction, size)
        : null;
    final saturationFilter = !isAnimating && settings.effectiveSaturation != 1.0
        ? ui.ColorFilter.matrix(
            _getSaturationMatrix(settings.effectiveSaturation),
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

  /// Creates a non-uniform scale filter to simulate refraction.
  ///
  /// The [refractionPixels] value specifies the target edge offset in pixels.
  /// Each axis is scaled independently to achieve consistent edge displacement
  /// regardless of widget aspect ratio.
  ui.ImageFilter _createRefractionFilter(
    Offset center,
    double refractionPixels,
    Size size,
  ) {
    // Calculate per-axis scale to achieve target pixel offset at edges.
    // For a widget of width W, to shift edges by P pixels:
    // scaleX = 1 - P / (W / 2) = 1 - 2P / W
    final scaleX =
        size.width > 0 ? 1.0 - (2 * refractionPixels / size.width) : 1.0;
    final scaleY =
        size.height > 0 ? 1.0 - (2 * refractionPixels / size.height) : 1.0;

    final matrix = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(scaleX, scaleY, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);

    return ui.ImageFilter.matrix(matrix.storage);
  }

  /// Creates a saturation adjustment matrix.
  /// saturation = 0 -> grayscale (using Rec. 709 luma coefficients)
  /// saturation = 1 -> original color (no change)
  /// saturation > 1 -> over-saturated
  List<double> _createSaturationMatrix(double saturation) {
    // Rec. 709 luma coefficients for RGB to grayscale conversion
    const lumR = 0.299;
    const lumG = 0.587;
    const lumB = 0.114;

    // Saturation matrix that interpolates between grayscale and original color
    // Based on: result = luminance + (color - luminance) * saturation
    final s = saturation;
    final invSat = 1.0 - s;

    return [
      lumR * invSat + s, lumG * invSat, lumB * invSat, 0, 0, // R
      lumR * invSat, lumG * invSat + s, lumB * invSat, 0, 0, // G
      lumR * invSat, lumG * invSat, lumB * invSat + s, 0, 0, // B
      0, 0, 0, 1, 0, // A
    ];
  }

  /// Creates a brighter version of the given color for specular highlights.
  ///
  /// Uses HSL color space to increase lightness while preserving hue.
  /// Only considers RGB values (ignores alpha which controls tint intensity).
  /// Falls back to white if the color has very low saturation.
  Color _brightenColor(Color color) {
    // Use RGB only - make opaque for HSL conversion
    final opaqueColor = color.withValues(alpha: 1);
    final hsl = HSLColor.fromColor(opaqueColor);

    // Lerp lightness 75% - 90% towards white - very bright but keeps hue
    // Use 90% for nearly grayscale colors, 75% for more colorful colors.
    final lerpFactor = hsl.saturation < 0.05 ? 0.9 : 0.75;

    final brighterLightness = ui.lerpDouble(hsl.lightness, 1.0, lerpFactor)!;
    return hsl.withLightness(brighterLightness.clamp(0.0, 1.0)).toColor();
  }

  void _paintColor(Canvas canvas, Path path) {
    final color = settings.effectiveGlassColor;

    // Multiply for dark tints (absorption), screen for light (transmission)
    final blendMode =
        _glassColorLuminance < 0.5 ? BlendMode.multiply : BlendMode.screen;

    final paint = Paint()
      ..color = color
      ..blendMode = blendMode
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    paint
      ..blendMode = BlendMode.overlay
      ..color = color.withValues(alpha: color.a * .2);
    canvas.drawPath(path, paint);
  }

  /// Paints an approximation for specular highlights by using a linear
  /// gradient that is aligned with the light angle and painting a strokw with
  /// that gradient.
  void _paintSpecular(Canvas canvas, Path path, Rect bounds) {
    // Expand bounds to a square to make sure the gradient angle will match the
    // light angle correctly. A squashed gradient would change the angle.
    final squareBounds = Rect.fromCircle(
      center: bounds.center,
      radius: bounds.size.longestSide / 2,
    );

    final lightIntensity = settings.effectiveLightIntensity.clamp(0.0, 1.0);
    final ambientStrength = settings.effectiveAmbientStrength.clamp(0.0, 1.0);

    final thicknessFactor = (settings.effectiveThickness / 5).clamp(0.0, 1.0);
    final alpha = Curves.easeOut.transform(lightIntensity);

    // Create specular color from glass tint - brighter version of glass color
    final glassColor = settings.effectiveGlassColor;
    final baseSpecularColor = _brightenColor(glassColor);
    final color = baseSpecularColor.withValues(
      alpha: alpha * thicknessFactor,
    );
    final rad = settings.lightAngle;

    final x = math.cos(rad);
    final y = math.sin(rad);

    // How far the light covers the glass, used to adjust the gradient stops
    final lightCoverage = ui.lerpDouble(.3, .5, lightIntensity)!;

    // How perpendicular we are to the shortest side of the box, 1 means the
    // light is hitting the shortest side directly, 0 means it's hitting the
    // longest side directly.
    final alignmentWithShortestSide = (size.aspectRatio < 1 ? y : x).abs();

    // How far we are from a square aspect ratio, used to adjust the gradient
    final aspectAdjustment = 1 - 1 / size.aspectRatio;

    // We scale the gradient when we are at a non-square aspect ratio, and the
    // light is aligned with the longest side.
    final gradientScale = aspectAdjustment * (1 - alignmentWithShortestSide);

    // How far the outer stops are inset
    final inset = ui.lerpDouble(0, .5, gradientScale.clamp(0, 1))!;

    // How far the second stops are inset
    final secondInset =
        ui.lerpDouble(lightCoverage, .5, gradientScale.clamp(0, 1))!;

    final shader = LinearGradient(
      colors: [
        color,
        color.withValues(alpha: ambientStrength),
        color.withValues(alpha: ambientStrength),
        color,
      ],
      stops: [
        inset,
        secondInset,
        1 - secondInset,
        1 - inset,
      ],
      begin: Alignment(x, y),
      end: Alignment(-x, -y),
    ).createShader(squareBounds);

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = ui.lerpDouble(
          _kSpecularStrokeMin, _kSpecularStrokeMax, lightIntensity)!
      ..color = color.withValues(alpha: color.a * _kSpecularAlpha)
      ..blendMode = BlendMode.hardLight;
    canvas.drawPath(path, paint);

    final overlay = Paint()
      ..shader = shader
      ..color = color.withValues(alpha: color.a * _kSpecularOverlayAlpha)
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(
          BlurStyle.normal, settings.effectiveThickness / _kSpecularBlurDivisor)
      ..strokeWidth = settings.effectiveThickness /
          (_frosted
              ? _kSpecularOverlayWidthDivisor *
                  _kSpecularOverlayFrostedMultiplier
              : _kSpecularOverlayWidthDivisor)
      ..blendMode = BlendMode.overlay;
    canvas.drawPath(path, overlay);
  }

  /// Paints an inner shadow along the edges to give the glass depth.
  ///
  /// This creates the illusion of thickness by darkening the inner edges.
  void _paintInnerEdgeShadow(Canvas canvas, Path path, Rect bounds) {
    final thickness = settings.effectiveThickness;
    if (thickness <= 0) return;

    // Inner shadow - subtle darkening at edges
    final shadowWidth = (thickness / _kShadowWidthDivisor)
        .clamp(_kShadowWidthMin, _kShadowWidthMax);
    final shadowAlpha = (thickness / _kShadowAlphaDivisor)
        .clamp(_kShadowAlphaMin, _kShadowAlphaMax);

    final innerShadow = Paint()
      ..color = Colors.black.withValues(alpha: shadowAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = shadowWidth
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowWidth / 2);

    canvas.drawPath(path, innerShadow);
  }

  /// Paints a subtle depth gradient to enhance the 3D appearance.
  ///
  /// Creates a gradient from top-left (lighter) to bottom-right (darker)
  /// based on the light angle to simulate light passing through glass.
  void _paintDepthGradient(Canvas canvas, Path path, Rect bounds) {
    if (!_kEnableDepthGradient) return;

    final thickness = settings.effectiveThickness;
    if (thickness <= 0) return;

    final lightIntensity = settings.effectiveLightIntensity.clamp(0.0, 1.0);
    final gradientAlpha = (lightIntensity * _kDepthGradientAlphaMultiplier)
        .clamp(_kDepthGradientAlphaMin, _kDepthGradientAlphaMax);

    if (gradientAlpha <= 0) return;

    final rad = settings.lightAngle;
    final x = math.cos(rad);
    final y = math.sin(rad);

    // Create a gradient that follows the light direction
    final gradient = LinearGradient(
      colors: [
        Colors.white.withValues(alpha: gradientAlpha),
        Colors.transparent,
        Colors.black.withValues(
          alpha: gradientAlpha * _kDepthGradientDarkRatio,
        ),
      ],
      stops: const [0.0, 0.5, 1.0],
      begin: Alignment(x, y),
      end: Alignment(-x, -y),
    ).createShader(bounds);

    final paint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.softLight;

    canvas
      ..save()
      ..clipPath(path)
      ..drawRect(bounds, paint)
      ..restore();
  }
}
