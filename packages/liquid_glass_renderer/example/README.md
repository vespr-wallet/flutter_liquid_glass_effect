# liquid_glass_renderer Example

This example demonstrates how to use the `liquid_glass_renderer` package to create liquid glass effects in Flutter.

## Requirements

- **Impeller Required**: This package requires Flutter's Impeller rendering engine. Run with:
  ```bash
  flutter run --enable-impeller
  ```
- Supported platforms: iOS, macOS, Android

## Getting Started

### 1. Basic LiquidGlass with its own layer

The simplest way to add a glass effect to a widget:

```dart
LiquidGlass.withOwnLayer(
  shape: LiquidRoundedSuperellipse(borderRadius: 24),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text('Hello Glass!'),
  ),
)
```

### 2. Multiple shapes sharing a layer (recommended for performance)

When you have multiple glass elements, wrap them in a shared `LiquidGlassLayer`:

```dart
LiquidGlassLayer(
  settings: LiquidGlassSettings(
    thickness: 20,
    frostIntensity: 5,
  ),
  child: Column(
    children: [
      LiquidGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: 16),
        child: Text('Button 1'),
      ),
      LiquidGlass(
        shape: LiquidOval(),
        child: Text('Button 2'),
      ),
    ],
  ),
)
```

### 3. Using presets

The package includes several presets for common use cases:

```dart
// Minimal - no lighting effects
LiquidGlassSettings.minimal()

// Subtle - balanced for general UI
LiquidGlassSettings.subtle()

// Flat - no glass effect (useful for animations)
LiquidGlassSettings.flat()

// Figma-compatible - uses Figma percentage values
LiquidGlassSettings.figma(
  refraction: 50,
  depth: 30,
  dispersion: 10,
  frost: 20,
)
```

### 4. Adding interactive stretch

Wrap your glass with `LiquidStretch` for touch-responsive effects:

```dart
LiquidStretch(
  child: LiquidGlass.withOwnLayer(
    shape: LiquidRoundedSuperellipse(borderRadius: 24),
    child: YourContent(),
  ),
)
```

## Running the Example

```bash
cd packages/liquid_glass_renderer/example
flutter run --enable-impeller
```
