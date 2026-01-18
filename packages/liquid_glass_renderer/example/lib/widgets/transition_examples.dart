// Isolated transition examples demonstrating LiquidGlass animations
// These examples showcase flat-to-glass, settings, and shape transitions

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// A page showcasing various glass transition examples.
///
/// Each example is isolated in its own widget for easy review.
class TransitionExamplesPage extends StatelessWidget {
  const TransitionExamplesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Transition Examples'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            _Section(
              title: 'Bouncing Glass',
              description:
                  'Glass element bouncing around like a DVD screensaver, '
                  'showcasing refraction and reflection during movement.',
              realChild: BouncingGlassExample(fake: false),
              fakeChild: BouncingGlassExample(fake: true),
            ),
            SizedBox(height: 32),
            _Section(
              title: 'Flat to Glass Transition',
              description:
                  'Transitions from a solid colored container to a glass '
                  'effect by animating visibility, blur, and thickness.',
              realChild: FlatToGlassExample(fake: false),
              fakeChild: FlatToGlassExample(fake: true),
            ),
            SizedBox(height: 32),
            _Section(
              title: 'Glass Intensity',
              description:
                  'Animates glass intensity from subtle to prominent by '
                  'changing blur, thickness, and saturation.',
              realChild: GlassIntensityExample(fake: false),
              fakeChild: GlassIntensityExample(fake: true),
            ),
            SizedBox(height: 32),
            _Section(
              title: 'Border Radius Animation',
              description:
                  'Animates the shape borderRadius from sharp (8) to '
                  'rounded (64) using LiquidShape.lerp.',
              realChild: BorderRadiusAnimationExample(fake: false),
              fakeChild: BorderRadiusAnimationExample(fake: true),
            ),
            SizedBox(height: 32),
            _Section(
              title: 'Combined Transition',
              description:
                  'Combines shape, settings, and size animations together.',
              realChild: CombinedTransitionExample(fake: false),
              fakeChild: CombinedTransitionExample(fake: true),
            ),
          ],
        ),
      ),
    );
  }
}

/// A complete section with header, description, and example row.
class _Section extends StatefulWidget {
  const _Section({
    required this.title,
    required this.description,
    required this.realChild,
    required this.fakeChild,
  });

  final String title;
  final String description;
  final Widget realChild;
  final Widget fakeChild;

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  int _imageId = Random().nextInt(1000);

  void _refreshImage() {
    setState(() {
      _imageId = Random().nextInt(10000);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: widget.title, onRefresh: _refreshImage),
        _SectionDescription(text: widget.description),
        _ExampleRow(
          imageId: _imageId,
          realChild: widget.realChild,
          fakeChild: widget.fakeChild,
        ),
      ],
    );
  }
}

/// Provides a shared image ID to descendant widgets.
class _SharedImageId extends InheritedWidget {
  const _SharedImageId({
    required this.imageId,
    required super.child,
  });

  final int imageId;

  static int of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_SharedImageId>()!.imageId;
  }

  @override
  bool updateShouldNotify(_SharedImageId oldWidget) =>
      imageId != oldWidget.imageId;
}

/// A row showing real and fake glass examples side by side.
class _ExampleRow extends StatelessWidget {
  const _ExampleRow({
    required this.imageId,
    required this.realChild,
    required this.fakeChild,
  });

  final int imageId;
  final Widget realChild;
  final Widget fakeChild;

  @override
  Widget build(BuildContext context) {
    return _SharedImageId(
      imageId: imageId,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ColumnLabel(text: 'Real Glass'),
                realChild,
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ColumnLabel(text: 'Fake Glass'),
                fakeChild,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnLabel extends StatelessWidget {
  const _ColumnLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: CupertinoColors.systemGrey.resolveFrom(context),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onRefresh});

  final String title;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          if (onRefresh != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(24, 24),
              onPressed: onRefresh,
              child: const Icon(CupertinoIcons.refresh, size: 18),
            ),
        ],
      ),
    );
  }
}

class _SectionDescription extends StatelessWidget {
  const _SectionDescription({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: CupertinoColors.systemGrey.resolveFrom(context),
        ),
      ),
    );
  }
}

// =============================================================================
// EXAMPLE 1: Flat to Glass Transition
// =============================================================================

/// Demonstrates transitioning from a flat colored container to a glass effect.
///
/// The "flat" state shows a semi-transparent colored container.
/// The "glass" state shows the full glass effect with blur and lighting.
class FlatToGlassExample extends StatefulWidget {
  const FlatToGlassExample({super.key, required this.fake});

  final bool fake;

  @override
  State<FlatToGlassExample> createState() => _FlatToGlassExampleState();
}

class _FlatToGlassExampleState extends State<FlatToGlassExample>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  bool _isGlass = true; // Start as glass

  // Flat state: visible container but no glass effects
  static const _flatSettings = LiquidGlassSettings(
    visibility: 1, // Keep visible!
    thickness: 0, // No glass depth
    blur: 0, // No blur
    lightIntensity: 0, // No specular
    saturation: 1.0, // Normal saturation
    fakeGlassRefraction: 0, // No refraction for FakeGlass
    glassColor: Color.fromARGB(0, 0, 0, 0), // Fully transparent
  );

  // Glass state: full glass effect
  static const _glassSettings = LiquidGlassSettings(
    visibility: 1,
    thickness: 20,
    blur: 8,
    lightIntensity: 0.7,
    saturation: 1.5,
    glassColor: Color.fromARGB(25, 255, 255, 255),
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
      value: 1.0, // Start as glass
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isGlass = !_isGlass;
      if (_isGlass) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ExampleContainer(
      onTap: _toggle,
      label: _isGlass
          ? 'Glass state - tap to flatten'
          : 'Flat state - tap for glass',
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final t = _animation.value;
          final settings = LiquidGlassSettings.lerp(
            _flatSettings,
            _glassSettings,
            t,
          );
          // Disable stretch when flat (t=0), enable when glass (t=1)
          return LiquidStretch(
            stretch: t * 0.5, // 0 when flat, 0.5 when glass
            interactionScale: 1.05, // Always scale on press
            child: LiquidGlass.withOwnLayer(
              shape: const LiquidRoundedSuperellipse(borderRadius: 24),
              settings: settings,
              fake: widget.fake,
              child: GlassGlow(child: child!),
            ),
          );
        },
        child: const _ExampleContent(text: 'Flat \u2194 Glass'),
      ),
    );
  }
}

// =============================================================================
// EXAMPLE 2: Glass Intensity
// =============================================================================

/// Demonstrates animating glass intensity from subtle to prominent.
class GlassIntensityExample extends StatefulWidget {
  const GlassIntensityExample({super.key, required this.fake});

  final bool fake;

  @override
  State<GlassIntensityExample> createState() => _GlassIntensityExampleState();
}

class _GlassIntensityExampleState extends State<GlassIntensityExample>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  bool _intense = false;

  // Subtle glass
  static const _subtleSettings = LiquidGlassSettings(
    visibility: 1,
    thickness: 8,
    blur: 3,
    lightIntensity: 0.3,
    saturation: 1.2,
    glassColor: Color.fromARGB(15, 200, 220, 255),
  );

  // Intense glass
  static const _intenseSettings = LiquidGlassSettings(
    visibility: 1,
    thickness: 35,
    blur: 15,
    lightIntensity: 1.0,
    saturation: 1.8,
    glassColor: Color.fromARGB(50, 255, 200, 150),
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _intense = !_intense;
      if (_intense) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ExampleContainer(
      onTap: _toggle,
      label: _intense ? 'Intense - tap for subtle' : 'Subtle - tap for intense',
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final settings = LiquidGlassSettings.lerp(
            _subtleSettings,
            _intenseSettings,
            _animation.value,
          );
          return LiquidStretch(
            child: LiquidGlass.withOwnLayer(
              shape: const LiquidRoundedSuperellipse(borderRadius: 24),
              settings: settings,
              fake: widget.fake,
              child: GlassGlow(child: child!),
            ),
          );
        },
        child: const _ExampleContent(text: 'Intensity'),
      ),
    );
  }
}

// =============================================================================
// EXAMPLE 3: Border Radius Animation
// =============================================================================

/// Demonstrates animating the shape's border radius.
///
/// Uses [LiquidShape.lerp] for same-type interpolation of border radius.
class BorderRadiusAnimationExample extends StatefulWidget {
  const BorderRadiusAnimationExample({super.key, required this.fake});

  final bool fake;

  @override
  State<BorderRadiusAnimationExample> createState() =>
      _BorderRadiusAnimationExampleState();
}

class _BorderRadiusAnimationExampleState
    extends State<BorderRadiusAnimationExample>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  bool _isRounded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isRounded = !_isRounded;
      if (_isRounded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const shapeA = LiquidRoundedSuperellipse(borderRadius: 8);
    const shapeB = LiquidRoundedSuperellipse(borderRadius: 64);

    return _ExampleContainer(
      onTap: _toggle,
      label: _isRounded
          ? 'Rounded (64) - tap to sharpen'
          : 'Sharp (8) - tap to round',
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final shape = LiquidShape.lerp(shapeA, shapeB, _animation.value)!;
          return LiquidStretch(
            child: LiquidGlass.withOwnLayer(
              shape: shape,
              settings: const LiquidGlassSettings(
                visibility: 1,
                thickness: 20,
                blur: 8,
                lightIntensity: 0.6,
                glassColor: Color.fromARGB(20, 255, 255, 255),
              ),
              fake: widget.fake,
              child: GlassGlow(child: child!),
            ),
          );
        },
        child: const _ExampleContent(text: 'Border Radius'),
      ),
    );
  }
}

// =============================================================================
// EXAMPLE 4: Combined Transition
// =============================================================================

/// Demonstrates combining shape and settings transitions.
///
/// This example animates both the shape (borderRadius) and settings
/// (visibility, blur, etc.) simultaneously for a complete transformation.
class CombinedTransitionExample extends StatefulWidget {
  const CombinedTransitionExample({super.key, required this.fake});

  final bool fake;

  @override
  State<CombinedTransitionExample> createState() =>
      _CombinedTransitionExampleState();
}

class _CombinedTransitionExampleState extends State<CombinedTransitionExample>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  bool _expanded = false;

  // State A: Small, sharp corners, subtle glass
  static const _shapeA = LiquidRoundedSuperellipse(borderRadius: 12);
  static const _settingsA = LiquidGlassSettings(
    visibility: 1,
    thickness: 10,
    blur: 4,
    lightIntensity: 0.3,
    glassColor: Color.fromARGB(15, 200, 200, 255),
  );

  // State B: Large, rounded corners, prominent glass
  static const _shapeB = LiquidRoundedSuperellipse(borderRadius: 48);
  static const _settingsB = LiquidGlassSettings(
    visibility: 1,
    thickness: 30,
    blur: 12,
    lightIntensity: 0.9,
    saturation: 1.6,
    glassColor: Color.fromARGB(40, 255, 220, 150),
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ExampleContainer(
      onTap: _toggle,
      label: _expanded
          ? 'Expanded - tap to collapse'
          : 'Collapsed - tap to expand',
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final t = _animation.value;
          final shape = LiquidShape.lerp(_shapeA, _shapeB, t)!;
          final settings = LiquidGlassSettings.lerp(_settingsA, _settingsB, t);

          // Also animate the size
          final size = Size.lerp(const Size(120, 80), const Size(200, 140), t)!;

          return Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: LiquidStretch(
                child: LiquidGlass.withOwnLayer(
                  shape: shape,
                  settings: settings,
                  fake: widget.fake,
                  child: GlassGlow(child: child!),
                ),
              ),
            ),
          );
        },
        child: const Center(
          child: Text(
            'Combined',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// EXAMPLE 5: Bouncing Glass (DVD Screensaver)
// =============================================================================

/// Demonstrates a glass element bouncing around like a DVD screensaver.
///
/// This showcases how refraction and reflection look during continuous movement.
class BouncingGlassExample extends StatefulWidget {
  const BouncingGlassExample({super.key, required this.fake});

  final bool fake;

  @override
  State<BouncingGlassExample> createState() => _BouncingGlassExampleState();
}

class _BouncingGlassExampleState extends State<BouncingGlassExample>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Position and velocity
  double _x = 20;
  double _y = 20;
  double _vx = 1.5; // velocity in x direction
  double _vy = 1.0; // velocity in y direction

  // Glass dimensions
  static const double _glassWidth = 80;
  static const double _glassHeight = 50;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _controller.addListener(_updatePosition);
  }

  @override
  void dispose() {
    _controller.removeListener(_updatePosition);
    _controller.dispose();
    super.dispose();
  }

  void _updatePosition() {
    setState(() {
      // Get container bounds from context if available
      final containerWidth = 180.0 - _glassWidth; // approximate
      final containerHeight = 180.0 - _glassHeight;

      // Update position
      _x += _vx;
      _y += _vy;

      // Bounce off walls
      if (_x <= 0 || _x >= containerWidth) {
        _vx = -_vx;
        _x = _x.clamp(0, containerWidth);
      }
      if (_y <= 0 || _y >= containerHeight) {
        _vy = -_vy;
        _y = _y.clamp(0, containerHeight);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _BouncingContainer(
      glassX: _x,
      glassY: _y,
      glassWidth: _glassWidth,
      glassHeight: _glassHeight,
      fake: widget.fake,
    );
  }
}

/// Container for the bouncing glass example that fills the available space.
class _BouncingContainer extends StatelessWidget {
  const _BouncingContainer({
    required this.glassX,
    required this.glassY,
    required this.glassWidth,
    required this.glassHeight,
    required this.fake,
  });

  final double glassX;
  final double glassY;
  final double glassWidth;
  final double glassHeight;
  final bool fake;

  @override
  Widget build(BuildContext context) {
    final imageId = _SharedImageId.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.network(
              'https://picsum.photos/2000/2000?random=$imageId',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      CupertinoColors.systemPurple.withValues(alpha: 0.5),
                      CupertinoColors.systemBlue.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ),
            // Bouncing glass element
            Positioned(
              left: glassX,
              top: glassY,
              child: LiquidGlass.withOwnLayer(
                shape: const LiquidRoundedSuperellipse(borderRadius: 16),
                settings: const LiquidGlassSettings(
                  visibility: 1,
                  thickness: 15,
                  blur: 6,
                  lightIntensity: 0.5,
                  glassColor: Color.fromARGB(20, 255, 255, 255),
                ),
                fake: fake,
                child: SizedBox(
                  width: glassWidth,
                  height: glassHeight,
                  child: const Center(
                    child: Text(
                      'DVD',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SHARED COMPONENTS
// =============================================================================

/// Container for examples with background and tap handling.
class _ExampleContainer extends StatelessWidget {
  const _ExampleContainer({
    required this.child,
    required this.label,
    this.onTap,
  });

  final Widget child;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Get shared image ID from parent _Section
    final imageId = _SharedImageId.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  Image.network(
                    'https://picsum.photos/2000/2000?random=$imageId',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            CupertinoColors.systemPurple.withValues(alpha: 0.5),
                            CupertinoColors.systemBlue.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // The glass widget
                  Center(child: child),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.systemGrey.resolveFrom(context),
          ),
        ),
      ],
    );
  }
}

/// Default content for glass examples.
class _ExampleContent extends StatelessWidget {
  const _ExampleContent({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 100,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
