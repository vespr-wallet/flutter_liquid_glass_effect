# Flutter BackdropFilterLayer Destruction Flicker

## Issue Summary

When a widget using `BackdropFilterLayer` is removed from the widget tree (or stops painting), a visual flicker/glitch occurs on the frame of removal. This appears to be an Impeller-specific rendering issue.

## Environment

- Flutter with Impeller rendering engine
- Observed on macOS, likely affects iOS/Android with Impeller

## What Causes It

The flicker occurs when:

1. A `RenderObject` uses `BackdropFilterLayer` via `context.pushLayer()`
2. The widget is removed from the tree (e.g., via conditional `if (condition) Widget()`)
3. The layer is destroyed/removed from the compositing tree

The issue does NOT occur when:
- The widget stays in the tree but is moved off-screen (e.g., `Transform.translate`)
- The widget stays in the tree and keeps painting

## Visual Symptom

A brief visual artifact/flash appears on the final frame before the widget disappears. The backdrop filter appears to render incorrectly for one frame during the layer cleanup.

## Reproduction Steps

1. Create a `RenderProxyBox` subclass that uses `BackdropFilterLayer`
2. Apply any `ImageFilter` (blur, matrix transform, etc.)
3. Wrap in a widget that can be conditionally shown/hidden
4. Animate the widget's visibility (e.g., fade out then remove)
5. Observe the flicker on the frame when the widget is removed

## Key Code Pattern That Triggers It

```dart
class _RenderWithBackdropFilter extends RenderProxyBox {
  @override
  bool get alwaysNeedsCompositing => true;

  @override
  BackdropFilterLayer? get layer => super.layer as BackdropFilterLayer?;

  @override
  void paint(PaintingContext context, Offset offset) {
    final filter = ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10);

    final layer = (this.layer ??= BackdropFilterLayer())
      ..filter = filter
      ..blendMode = BlendMode.srcATop;

    context.pushLayer(
      layer,
      (context, offset) {
        // Paint content
        super.paint(context, offset);
      },
      offset,
    );
  }
}
```

## Workarounds

### Workaround 1: Release layer before widget removal

If the widget has a visibility/opacity parameter, skip using the `BackdropFilterLayer` when visibility is below a threshold (e.g., < 0.05). This releases the layer gracefully before the widget is removed.

```dart
@override
void paint(PaintingContext context, Offset offset) {
  // Skip backdrop filter at low visibility to avoid destruction flicker
  if (visibility < 0.05) {
    super.paint(context, offset);
    return;
  }

  // Normal backdrop filter code...
}
```

### Workaround 2: Keep widget painting off-screen

Instead of removing the widget from the tree, keep it in the tree but translate it off-screen:

```dart
Transform.translate(
  offset: isHidden ? const Offset(0, 9999) : Offset.zero,
  child: widgetWithBackdropFilter,
)
```

This keeps the layer alive and painting, avoiding the destruction flicker.

## Notes

- The issue was NOT caused by the specific `BlendMode` (tested with `srcATop` and `srcOver`)
- The issue IS specifically tied to `BackdropFilterLayer` removal
- Widgets that don't use `BackdropFilterLayer` (e.g., `Offstage`, `Opacity`) don't exhibit this issue on their own
- The flicker occurs on the "settle" (disappearance), not on appearance

---

# Matrix Filter Animation Trembling

## Issue Summary

When using `ImageFilter.matrix` or `ColorFilter.matrix` inside a `BackdropFilterLayer` during animations, visual trembling/flickering occurs. This is separate from the destruction flicker above.

## What Causes It

Matrix-based filters cause visual instability when the widget is animating (e.g., during visibility transitions, size changes, or transforms). The issue manifests as a "trembling" or rapid flickering of the filtered content.

Affected filters:
- `ui.ImageFilter.matrix()` - used for refraction/magnification effects
- `ui.ColorFilter.matrix()` - used for saturation adjustments

Unaffected filters:
- `ui.ImageFilter.blur()` - works smoothly during animations

## Workaround

Disable matrix-based filters entirely, or only apply them when the widget is static (not animating). In FakeGlass, we chose to disable refraction and saturation filters to ensure smooth animations:

```dart
ui.ImageFilter? _buildCombinedFilter(Rect bounds) {
  // Note: Refraction and saturation filters are disabled because
  // ImageFilter.matrix and ColorFilter.matrix cause visual trembling
  // in Impeller during animations.

  if (!_frosted) {
    return null;
  }

  // Only blur - no matrix filters
  return ui.ImageFilter.blur(
    sigmaX: settings.effectiveBlur,
    sigmaY: settings.effectiveBlur,
    tileMode: TileMode.mirror,
  );
}
```

---

## Potential Flutter Issue

These issues may warrant Flutter issue reports for the Impeller rendering backend:
1. Layer destruction should not cause visible artifacts
2. Matrix-based filters should not cause trembling during animations
