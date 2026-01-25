import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_plus/liquid_glass_plus.dart';

void main() {
  group('LiquidGlassSettings', () {
    group('constructor', () {
      test('creates with default values', () {
        const settings = LiquidGlassSettings();

        expect(settings.thickness, 20);
        expect(settings.frostIntensity, 5);
        expect(settings.lightAngle, pi / 4);
        expect(settings.lightIntensity, 0.5);
        expect(settings.saturation, 1.5);
      });

      test('throws assertion error when thickness is negative', () {
        expect(
          () => LiquidGlassSettings(thickness: -1),
          throwsAssertionError,
        );
      });

      test('throws assertion error when frostIntensity is negative', () {
        expect(
          () => LiquidGlassSettings(frostIntensity: -1),
          throwsAssertionError,
        );
      });

      test('throws assertion error when saturation is zero or negative', () {
        expect(
          () => LiquidGlassSettings(saturation: 0),
          throwsAssertionError,
        );
        expect(
          () => LiquidGlassSettings(saturation: -1),
          throwsAssertionError,
        );
      });
    });

    group('presets', () {
      test('flat() creates settings with no effects', () {
        const settings = LiquidGlassSettings.flat();

        expect(settings.thickness, 0);
        expect(settings.frostIntensity, 0);
        expect(settings.lightIntensity, 0);
        expect(settings.saturation, 1);
        expect(settings.liquidGlassConfigs.chromaticAberration, 0);
        expect(settings.liquidGlassConfigs.refractiveIndex, 1);
        expect(settings.fakeGlassConfigs.refraction, 0);
      });

      test('minimal() creates settings without lighting', () {
        const settings = LiquidGlassSettings.minimal();

        expect(settings.thickness, 15);
        expect(settings.frostIntensity, 4);
        expect(settings.lightIntensity, 0);
        expect(settings.liquidGlassConfigs.chromaticAberration, 0);
      });

      test('subtle() creates balanced settings', () {
        const settings = LiquidGlassSettings.subtle();

        expect(settings.thickness, 12);
        expect(settings.frostIntensity, 3);
        expect(settings.lightIntensity, 0.3);
        expect(settings.lightAngle, pi / 4);
      });
    });

    group('isFrosted', () {
      test('returns true when frostIntensity > 0', () {
        const settings = LiquidGlassSettings(frostIntensity: 5);
        expect(settings.isFrosted, true);
      });

      test('returns false when frostIntensity is 0', () {
        const settings = LiquidGlassSettings(frostIntensity: 0);
        expect(settings.isFrosted, false);
      });
    });

    group('copyWith', () {
      test('creates copy with replaced values', () {
        const original = LiquidGlassSettings(
          thickness: 10,
          frostIntensity: 5,
        );

        final copy = original.copyWith(thickness: 20);

        expect(copy.thickness, 20);
        expect(copy.frostIntensity, 5); // unchanged
      });

      test('preserves all values when no arguments provided', () {
        const original = LiquidGlassSettings(
          thickness: 15,
          frostIntensity: 8,
          lightIntensity: 0.6,
        );

        final copy = original.copyWith();

        expect(copy.thickness, original.thickness);
        expect(copy.frostIntensity, original.frostIntensity);
        expect(copy.lightIntensity, original.lightIntensity);
      });
    });

    group('lerp', () {
      test('returns first settings at t=0', () {
        const a = LiquidGlassSettings(thickness: 10);
        const b = LiquidGlassSettings(thickness: 20);

        final result = LiquidGlassSettings.lerp(a, b, 0);

        expect(result.thickness, 10);
      });

      test('returns second settings at t=1', () {
        const a = LiquidGlassSettings(thickness: 10);
        const b = LiquidGlassSettings(thickness: 20);

        final result = LiquidGlassSettings.lerp(a, b, 1);

        expect(result.thickness, 20);
      });

      test('interpolates correctly at t=0.5', () {
        const a = LiquidGlassSettings(
          thickness: 10,
          frostIntensity: 0,
        );
        const b = LiquidGlassSettings(
          thickness: 20,
          frostIntensity: 10,
        );

        final result = LiquidGlassSettings.lerp(a, b, 0.5);

        expect(result.thickness, 15);
        expect(result.frostIntensity, 5);
      });

      test('uses destination animation settings', () {
        const a = LiquidGlassSettings(
          animationDuration: Duration(milliseconds: 100),
          animationCurve: Curves.linear,
        );
        const b = LiquidGlassSettings(
          animationDuration: Duration(milliseconds: 500),
          animationCurve: Curves.bounceIn,
        );

        final result = LiquidGlassSettings.lerp(a, b, 0.25);

        // Animation settings are NOT interpolated - destination values are used
        expect(result.animationDuration, b.animationDuration);
        expect(result.animationCurve, b.animationCurve);
      });
    });

    group('equality', () {
      test('equal settings are equal', () {
        const a = LiquidGlassSettings(thickness: 10);
        const b = LiquidGlassSettings(thickness: 10);

        expect(a, equals(b));
      });

      test('different settings are not equal', () {
        const a = LiquidGlassSettings(thickness: 10);
        const b = LiquidGlassSettings(thickness: 20);

        expect(a, isNot(equals(b)));
      });
    });
  });

  group('LiquidGlassConfigs', () {
    test('creates with default values', () {
      const configs = LiquidGlassConfigs();

      expect(configs.chromaticAberration, 0.01);
      expect(configs.refractiveIndex, 1.2);
    });

    test('throws assertion for negative chromaticAberration', () {
      expect(
        () => LiquidGlassConfigs(chromaticAberration: -1),
        throwsAssertionError,
      );
    });

    test('throws assertion for refractiveIndex less than 1', () {
      expect(
        () => LiquidGlassConfigs(refractiveIndex: 0.5),
        throwsAssertionError,
      );
    });

    test('lerp interpolates correctly', () {
      const a = LiquidGlassConfigs(
        chromaticAberration: 0,
        refractiveIndex: 1.0,
      );
      const b = LiquidGlassConfigs(
        chromaticAberration: 0.02,
        refractiveIndex: 1.4,
      );

      final result = LiquidGlassConfigs.lerp(a, b, 0.5);

      expect(result.chromaticAberration, 0.01);
      expect(result.refractiveIndex, 1.2);
    });
  });

  group('FakeGlassConfigs', () {
    test('creates with default values', () {
      const configs = FakeGlassConfigs();

      expect(configs.forceEnabled, false);
      expect(configs.refraction, 5.0);
    });

    test('lerp switches forceEnabled at t=0.5', () {
      const a = FakeGlassConfigs(forceEnabled: true);
      const b = FakeGlassConfigs(forceEnabled: false);

      expect(FakeGlassConfigs.lerp(a, b, 0.49).forceEnabled, true);
      expect(FakeGlassConfigs.lerp(a, b, 0.5).forceEnabled, false);
    });

    test('lerp interpolates refraction', () {
      const a = FakeGlassConfigs(refraction: 0);
      const b = FakeGlassConfigs(refraction: 10);

      final result = FakeGlassConfigs.lerp(a, b, 0.5);

      expect(result.refraction, 5.0);
    });
  });
}
