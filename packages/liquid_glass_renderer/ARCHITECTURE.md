# Liquid Glass Renderer Architecture

This document explains how the different components and widgets interact to create the liquid glass effect.

## Overview

The liquid glass effect is achieved through a multi-stage rendering pipeline that:
1. Captures the background behind glass shapes
2. Generates geometry textures for displacement calculation
3. Applies blur, refraction, and lighting effects via fragment shaders

## Component Diagram

```
                          ┌─────────────────────────────────────────────────────────────┐
                          │                     YOUR APP                                │
                          └─────────────────────────────────────────────────────────────┘
                                                     │
                                                     ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    LiquidGlassLayer                                             │
│  ┌───────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │  Provides:                                                                                │  │
│  │  • LiquidGlassRenderScope (settings + fake mode flag)                                     │  │
│  │  • InheritedGeometryRenderLink (connects shapes to layer)                                 │  │
│  │  • ShaderBuilder (loads liquid_glass_final_render.frag)                                   │  │
│  └───────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                              │                                                  │
│                                              ▼                                                  │
│  ┌───────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                           RenderLiquidGlassLayer                                          │  │
│  │  • Collects all registered shapes via GeometryRenderLink                                  │  │
│  │  • Builds combined geometry texture from all shapes                                       │  │
│  │  • Applies backdrop blur filter (BackdropFilterLayer)                                     │  │
│  │  • Applies final render shader (ImageFilter.shader)                                       │  │
│  │  • Clips effects to combined shape path                                                   │  │
│  └───────────────────────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                     │
                                                     │ child widgets
                                                     ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                      LiquidGlass                                                │
│  ┌───────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │  Widget responsibilities:                                                                 │  │
│  │  • Loads geometry shader (liquid_glass_geometry_blended.frag)                             │  │
│  │  • Clips child to shape                                                                   │  │
│  │  • Creates GlassGlowLayer for touch glow                                                  │  │
│  └───────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                              │                                                  │
│                                              ▼                                                  │
│  ┌───────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                        RenderLiquidGlassSingleShape                                       │  │
│  │  • Registers with GeometryRenderLink on attach                                            │  │
│  │  • Generates geometry matte (displacement texture) for this shape                         │  │
│  │  • Caches geometry - only rebuilds when shape/size changes                                │  │
│  │  • Provides shape path for clipping                                                       │  │
│  └───────────────────────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
```

## Widget Hierarchy

```
LiquidGlassLayer
├── LiquidGlassRenderScope (InheritedWidget - provides settings)
├── InheritedGeometryRenderLink (InheritedWidget - connects shapes)
└── ShaderBuilder (loads render shader)
    └── RenderLiquidGlassLayer (RenderObject - final composition)
        └── [Your child widgets]
            └── LiquidGlass
                └── ShaderBuilder (loads geometry shader)
                    └── ClipPath (clips to shape)
                        └── GlassGlowLayer (touch glow surface)
                            └── RenderLiquidGlassSingleShape
                                └── [Your content]
```

## Data Flow

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  LiquidGlass     │     │  GeometryRender  │     │  LiquidGlass     │
│  Shape A         │     │  Link            │     │  Layer           │
└────────┬─────────┘     └────────┬─────────┘     └────────┬─────────┘
         │                        │                        │
         │  1. Register           │                        │
         │ ────────────────────▶  │                        │
         │                        │                        │
         │  2. Build geometry     │                        │
         │     texture (cached)   │                        │
         │                        │                        │
         │                        │  3. Collect shapes     │
         │                        │ ◀────────────────────  │
         │                        │                        │
         │  4. Return geometry    │                        │
         │ ◀───────────────────── │                        │
         │                        │                        │
         │                        │  5. Compose all        │
         │                        │     geometries         │
         │                        │ ────────────────────▶  │
         │                        │                        │
         │                        │                        │  6. Apply shaders
         │                        │                        │     & render
         │                        │                        │
```

## Key Classes

### Widget Layer

| Class | File | Purpose |
|-------|------|---------|
| `LiquidGlassLayer` | `rendering/liquid_glass_layer.dart` | Container that manages rendering for all glass shapes within |
| `LiquidGlass` | `liquid_glass.dart` | Individual glass shape widget |
| `LiquidGlassSettings` | `liquid_glass_settings.dart` | Configuration (thickness, blur, color, lighting) |
| `GlassGlow` | `glass_glow.dart` | Touch-responsive glow effect |
| `GlassGlowLayer` | `glass_glow.dart` | Surface that paints the glow |
| `LiquidStretch` | `stretch.dart` | Optional squash/stretch on drag |
| `FakeGlass` | `fake_glass.dart` | Fallback for non-Impeller (uses BackdropFilter) |

### Render Layer

| Class | File | Purpose |
|-------|------|---------|
| `RenderLiquidGlassLayer` | `rendering/liquid_glass_layer.dart` | Composes geometry textures and applies final shader |
| `LiquidGlassRenderObject` | `rendering/liquid_glass_render_object.dart` | Base class for glass layer rendering |
| `RenderLiquidGlassSingleShape` | `liquid_glass.dart` | Generates geometry texture for one shape |
| `RenderLiquidGlassGeometry` | `internal/render_liquid_glass_geometry.dart` | Base class with geometry caching logic |
| `GeometryRenderLink` | `rendering/liquid_glass_render_object.dart` | Links shapes to their parent layer |
| `GeometryCache` | `internal/render_liquid_glass_geometry.dart` | Cached geometry matte (Picture or Image) |

### Shapes

| Class | File | Purpose |
|-------|------|---------|
| `LiquidRoundedSuperellipse` | `liquid_shape.dart` | Smooth continuous curvature (iOS-style) |
| `LiquidOval` | `liquid_shape.dart` | Circles and ellipses |
| `LiquidRoundedRectangle` | `liquid_shape.dart` | Standard rounded corners |

## Rendering Pipeline

### Stage 1: Geometry Generation (per shape)

Each `RenderLiquidGlassSingleShape` independently generates a **geometry matte** texture:

```
┌─────────────────────────────────────────────────────────────┐
│              Geometry Shader (per shape)                    │
│  liquid_glass_geometry_blended.frag                         │
├─────────────────────────────────────────────────────────────┤
│  Input:                                                     │
│  • Shape type (squircle, ellipse, rounded rect)             │
│  • Shape bounds (center, size)                              │
│  • Corner radius                                            │
│  • Thickness, refractive index                              │
│                                                             │
│  Output:                                                    │
│  • Displacement texture (R=dx, G=dy encoded)                │
│  • Used for refraction calculation                          │
└─────────────────────────────────────────────────────────────┘
```

**Caching**: Geometry is cached and only rebuilt when:
- Shape changes (type, size, corner radius)
- Settings change (thickness, refractive index)
- Device pixel ratio changes

### Stage 2: Final Composition (at layer)

The `RenderLiquidGlassLayer` combines all geometries and applies effects:

```
┌─────────────────────────────────────────────────────────────┐
│              Final Render Pipeline                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Collect geometry from all registered shapes             │
│     ▼                                                       │
│  2. Build combined geometry texture                         │
│     ▼                                                       │
│  3. Push ClipPath (combined shape outlines)                 │
│     ▼                                                       │
│  4. Apply BackdropFilterLayer (blur)                        │
│     ▼                                                       │
│  5. Paint "inside glass" content                            │
│     ▼                                                       │
│  6. Apply ImageFilter.shader (final render)                 │
│     - Reads backdrop (blurred background)                   │
│     - Reads geometry texture                                │
│     - Applies refraction, chromatic aberration              │
│     - Applies lighting (specular + ambient)                 │
│     - Applies color tint and saturation                     │
│     ▼                                                       │
│  7. Paint "on top of glass" content                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Shader Files

```
lib/assets/shaders/
├── liquid_glass_geometry_blended.frag   # Generates displacement texture
├── liquid_glass_final_render.frag       # Final composition shader
├── sdf.glsl                             # Signed distance functions
├── shared.glsl                          # Common utilities
├── displacement_encoding.glsl           # Displacement encode/decode
└── render.glsl                          # Rendering utilities
```

## Performance Considerations

### Per-Shape Independence
Each shape independently manages its geometry:
- Moving shape A does NOT force shape B to rebuild
- Geometry cache invalidation is per-shape
- Shader data upload: only 6 floats per shape change

### Caching Strategy
```
Shape Changes? ──▶ Rebuild geometry texture
        │
        ▼ No
Transform Only? ──▶ Reuse existing texture, update transform
        │
        ▼ No
Return cached geometry
```

### Memory Management
- Geometry textures are disposed when shapes are removed
- Picture → Image conversion happens lazily
- Combined geometry texture rebuilt only when needed

## Optional Features

### LiquidStretch (squash/stretch on drag)
```dart
LiquidStretch(
  stretch: 0.1,           // Amount of stretch
  interactionScale: 1.01, // Scale on interaction
  child: LiquidGlass(...),
)
```
To disable: don't wrap with `LiquidStretch`, or use `stretch: 0`.

### GlassGlow (touch glow)
Automatically included when using `LiquidGlass`. Touch the glass to see glow.

### FakeGlass (non-Impeller fallback)
Automatically used when:
- Impeller is not available
- `LiquidGlassLayer(fake: true)` is set

Uses standard `BackdropFilter` instead of custom shaders.

## Usage Example

```dart
// Minimal setup
LiquidGlassLayer(
  settings: LiquidGlassSettings(
    thickness: 20,
    blur: 10,
    glassColor: Colors.white.withOpacity(0.2),
  ),
  child: Center(
    child: LiquidGlass(
      shape: LiquidRoundedSuperellipse(borderRadius: 20),
      child: SizedBox.square(
        dimension: 100,
        child: Center(child: Text('Glass')),
      ),
    ),
  ),
)
```

## Debugging

Set `debugPaintLiquidGlassGeometry = true` to visualize geometry textures:

```dart
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

void main() {
  debugPaintLiquidGlassGeometry = true; // Only works in debug mode
  runApp(MyApp());
}
```
