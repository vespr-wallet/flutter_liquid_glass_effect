import 'dart:math';
import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:liquid_glass_renderer/src/liquid_glass_render_scope.dart';

/// Represents the settings for a liquid glass effect.
class LiquidGlassSettings with EquatableMixin {
  /// Creates a new [LiquidGlassSettings] with the given settings.
  ///
  /// The [frostIntensity] value should typically be greater than 0.
  /// Use [frostByDefault] to control whether blur is applied, rather than
  /// setting frostIntensity to 0 (though 0 is allowed for animations).
  ///
  /// Note: If [frostIntensity] is <= 0, [frosted] will return false regardless
  /// of [frostByDefault].
  const LiquidGlassSettings({
    this.visibility = 1.0,
    this.glassColor = const Color.fromARGB(0, 255, 255, 255),
    this.thickness = 20,
    this.frostIntensity = 5,
    this.chromaticAberration = .01,
    this.lightAngle = pi / 4,
    this.lightIntensity = .5,
    this.ambientStrength = 0,
    this.refractiveIndex = 1.2,
    this.saturation = 1.5,
    this.frostByDefault = true,
    this.fakeGlassRefraction = 5.0,
    this.fakeGlassRefractionFrostedMultiplier = 1.5,
  });

  /// Creates a new [LiquidGlassSettings] with the given settings where each
  /// setting works like it does in Figma, where it is a percentage from
  /// 0 to 100.
  LiquidGlassSettings.figma({
    required double refraction,
    required double depth,
    required double dispersion,
    required double frost,
    double visibility = 1.0,
    double lightIntensity = 50,
    double lightAngle = pi / 4,
    Color glassColor = const Color.fromARGB(0, 255, 255, 255),
    bool frostByDefault = true,
    double fakeGlassRefraction = 5.0,
    double fakeGlassRefractionFrostedMultiplier = 2.0,
  }) : this(
          visibility: visibility,
          refractiveIndex: 1 + (refraction / 100) * 0.2,
          thickness: depth,
          chromaticAberration: 4 * (dispersion / 100),
          lightIntensity: lightIntensity / 100,
          frostIntensity: frost,
          lightAngle: lightAngle,
          ambientStrength: 0.1,
          saturation: 1.5,
          glassColor: glassColor,
          frostByDefault: frostByDefault,
          fakeGlassRefraction: fakeGlassRefraction,
          fakeGlassRefractionFrostedMultiplier:
              fakeGlassRefractionFrostedMultiplier,
        );

  /// A minimal glass effect with no lighting or chromatic aberration.
  ///
  /// Good for subtle, unobtrusive glass effects where you just want
  /// refraction and blur without decorative lighting.
  const LiquidGlassSettings.minimal({
    this.visibility = 1.0,
    this.glassColor = const Color.fromARGB(0, 255, 255, 255),
    this.thickness = 15,
    this.frostIntensity = 4,
    this.refractiveIndex = 1.15,
    this.saturation = 1.2,
    this.frostByDefault = true,
    this.fakeGlassRefraction = 5.0,
    this.fakeGlassRefractionFrostedMultiplier = 2.0,
  })  : chromaticAberration = 0,
        lightAngle = 0,
        lightIntensity = 0,
        ambientStrength = 0;

  /// A subtle glass effect suitable for general UI use.
  ///
  /// Balanced settings with moderate refraction, light blur, and
  /// subtle lighting. A good starting point for most applications.
  const LiquidGlassSettings.subtle({
    this.visibility = 1.0,
    this.glassColor = const Color.fromARGB(0, 255, 255, 255),
    this.thickness = 12,
    this.frostIntensity = 3,
    this.refractiveIndex = 1.1,
    this.saturation = 1.3,
    this.frostByDefault = true,
    this.fakeGlassRefraction = 5.0,
    this.fakeGlassRefractionFrostedMultiplier = 2.0,
  })  : chromaticAberration = 0.005,
        lightAngle = pi / 4,
        lightIntensity = 0.3,
        ambientStrength = 0;

  /// Retrieves the nearest [LiquidGlassSettings] from the widget tree.
  ///
  /// This will look for the nearest ancestor [LiquidGlassLayer] or
  /// [LiquidGlassRenderScope] widget in the widget tree.
  static LiquidGlassSettings of(BuildContext context) {
    return LiquidGlassRenderScope.of(context).settings;
  }

  /// A factor that can be used to scale all thickness-related properties.
  ///
  /// Defaults to 1.0.
  final double visibility;

  /// The color tint of the glass effect.
  ///
  /// Opacity defines the intensity of the tint.
  final Color glassColor;

  /// The effective glass color taking visibility into account.
  Color get effectiveGlassColor =>
      glassColor.withValues(alpha: glassColor.a * visibility);

  /// The thickness of the glass surface.
  ///
  /// Thicker surfaces refract the light more intensely.
  final double thickness;

  /// The effective thickness taking visibility into account.
  double get effectiveThickness => thickness * visibility;

  /// The blur intensity of the frosted glass effect.
  ///
  /// Higher values create a more frosted appearance.
  /// This value should be > 0. Use [frostByDefault] to disable blur instead.
  ///
  /// Defaults to 5.
  final double frostIntensity;

  /// The effective blur taking visibility into account.
  /// Returns 0 if [frostIntensity] is <= 0.
  double get effectiveBlur =>
      frostIntensity > 0 ? frostIntensity * visibility : 0;

  /// The chromatic aberration of the glass effect (WIP).
  ///
  /// This is a little ugly still.
  ///
  /// Higher values create more pronounced color fringes.
  final double chromaticAberration;

  /// The effective chromatic aberration taking visibility into account.
  double get effectiveChromaticAberration => chromaticAberration * visibility;

  /// The angle of the light source in radians.
  ///
  /// This determines where the highlights on shapes will come from.
  final double lightAngle;

  /// The intensity of the light source.
  ///
  /// Higher values create more pronounced highlights.
  final double lightIntensity;

  /// The effective light intensity taking visibility into account.
  double get effectiveLightIntensity => lightIntensity * visibility;

  /// The strength of the ambient light.
  ///
  /// Higher values create more pronounced ambient light.
  final double ambientStrength;

  /// The effective ambient strength taking visibility into account.
  double get effectiveAmbientStrength => ambientStrength * visibility;

  /// The strength of the refraction.
  ///
  /// Higher values create more pronounced refraction.
  /// Defaults to 1.51
  final double refractiveIndex;

  /// The saturation adjustment for pixels that shine through the glass.
  ///
  /// 1.0 means no change, values < 1.0 desaturate the background,
  /// values > 1.0 increase saturation.
  /// Defaults to 1.0
  final double saturation;

  /// The effective saturation taking visibility into account.
  double get effectiveSaturation => 1 + (saturation - 1) * visibility;

  /// Whether glass shapes should apply backdrop blur by default.
  ///
  /// When true, glass shapes will blur the background behind them (frosted).
  /// When false, glass shapes will only apply refraction without blur (clear).
  ///
  /// Individual [LiquidGlass] widgets can override this per-shape.
  /// Defaults to true.
  final bool frostByDefault;

  /// The effective frosted state, taking [frostIntensity] into account.
  ///
  /// Returns false if [frostIntensity] is <= 0, regardless of [frostByDefault].
  bool get frosted => frostByDefault && frostIntensity > 0;

  /// The fake refraction edge offset in pixels used by fake glass mode.
  ///
  /// This creates a non-uniform scale effect to simulate refraction when
  /// custom shaders are not available (non-Impeller devices).
  ///
  /// The value specifies how many pixels the edges should appear to shift
  /// inward. Each axis is scaled independently, so wide buttons and tall
  /// buttons will have consistent edge displacement.
  ///
  /// Set to 0 to disable. This has no effect on [LiquidGlass] which uses
  /// real shader-based refraction.
  ///
  /// Defaults to 5.0 pixels.
  final double fakeGlassRefraction;

  /// Multiplier applied to [fakeGlassRefraction] when the glass is frosted.
  ///
  /// Frosted glass typically has more pronounced refraction due to the
  /// diffusion of light. This multiplier increases the magnification effect
  /// when blur is applied.
  ///
  /// Defaults to 2.0 (double the refraction when frosted).
  final double fakeGlassRefractionFrostedMultiplier;

  /// Creates a new [LiquidGlassSettings] with the given settings.
  LiquidGlassSettings copyWith({
    double? visibility,
    Color? glassColor,
    double? thickness,
    double? frostIntensity,
    double? chromaticAberration,
    double? blend,
    double? lightAngle,
    double? lightIntensity,
    double? ambientStrength,
    double? refractiveIndex,
    double? saturation,
    bool? frostByDefault,
    double? fakeGlassRefraction,
    double? fakeGlassRefractionFrostedMultiplier,
  }) =>
      LiquidGlassSettings(
        visibility: visibility ?? this.visibility,
        glassColor: glassColor ?? this.glassColor,
        thickness: thickness ?? this.thickness,
        frostIntensity: frostIntensity ?? this.frostIntensity,
        chromaticAberration: chromaticAberration ?? this.chromaticAberration,
        lightAngle: lightAngle ?? this.lightAngle,
        lightIntensity: lightIntensity ?? this.lightIntensity,
        ambientStrength: ambientStrength ?? this.ambientStrength,
        refractiveIndex: refractiveIndex ?? this.refractiveIndex,
        saturation: saturation ?? this.saturation,
        frostByDefault: frostByDefault ?? this.frostByDefault,
        fakeGlassRefraction: fakeGlassRefraction ?? this.fakeGlassRefraction,
        fakeGlassRefractionFrostedMultiplier:
            fakeGlassRefractionFrostedMultiplier ??
                this.fakeGlassRefractionFrostedMultiplier,
      );

  /// Linearly interpolates between two [LiquidGlassSettings].
  ///
  /// The [t] parameter represents the interpolation progress from 0.0 to 1.0,
  /// where 0.0 returns [a] and 1.0 returns [b].
  ///
  /// Boolean properties ([frostByDefault]) switch at t >= 0.5.
  ///
  /// Example:
  /// ```dart
  /// final settings = LiquidGlassSettings.lerp(
  ///   LiquidGlassSettings(visibility: 0, frostIntensity: 1),
  ///   LiquidGlassSettings(visibility: 1, frostIntensity: 10),
  ///   0.5,
  /// ); // visibility: 0.5, frostIntensity: 5.5
  /// ```
  static LiquidGlassSettings lerp(
    LiquidGlassSettings a,
    LiquidGlassSettings b,
    double t,
  ) {
    return LiquidGlassSettings(
      visibility: ui.lerpDouble(a.visibility, b.visibility, t)!,
      glassColor: Color.lerp(a.glassColor, b.glassColor, t)!,
      thickness: ui.lerpDouble(a.thickness, b.thickness, t)!,
      frostIntensity: switch (t) {
        <= 0 => a.frostIntensity,
        >= 1 => b.frostIntensity,
        _ => () {
            if (a.frostByDefault && !b.frostByDefault) {
              // transition from frosted to non-frosted
              return ui.lerpDouble(a.frostIntensity, 0.0, t)!;
            } else if (!a.frostByDefault && b.frostByDefault) {
              // transition from non-frosted to frosted
              return ui.lerpDouble(0.0, b.frostIntensity, t)!;
            }
            // transition between frosted and non-frosted
            final start = a.frostIntensity;
            final end = b.frostIntensity;
            return ui.lerpDouble(start, end, t)!;
          }(),
      },
      chromaticAberration:
          ui.lerpDouble(a.chromaticAberration, b.chromaticAberration, t)!,
      lightAngle: ui.lerpDouble(a.lightAngle, b.lightAngle, t)!,
      lightIntensity: ui.lerpDouble(a.lightIntensity, b.lightIntensity, t)!,
      ambientStrength: ui.lerpDouble(a.ambientStrength, b.ambientStrength, t)!,
      refractiveIndex: ui.lerpDouble(a.refractiveIndex, b.refractiveIndex, t)!,
      saturation: ui.lerpDouble(a.saturation, b.saturation, t)!,
      frostByDefault: t < 0.5 ? a.frostByDefault : b.frostByDefault,
      fakeGlassRefraction:
          ui.lerpDouble(a.fakeGlassRefraction, b.fakeGlassRefraction, t)!,
      fakeGlassRefractionFrostedMultiplier: ui.lerpDouble(
        a.fakeGlassRefractionFrostedMultiplier,
        b.fakeGlassRefractionFrostedMultiplier,
        t,
      )!,
    );
  }

  @override
  List<Object?> get props => [
        visibility,
        glassColor,
        thickness,
        frostIntensity,
        chromaticAberration,
        lightAngle,
        lightIntensity,
        ambientStrength,
        refractiveIndex,
        saturation,
        frostByDefault,
        fakeGlassRefraction,
        fakeGlassRefractionFrostedMultiplier,
      ];
}
