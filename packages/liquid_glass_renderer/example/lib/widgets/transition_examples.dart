// Isolated transition examples demonstrating LiquidGlass animations
// These examples showcase flat-to-glass, settings, and shape transitions

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Provides fake mode setting to descendant widgets.
class _FakeModeScope extends InheritedWidget {
  const _FakeModeScope({
    required this.fake,
    required super.child,
  });

  final bool fake;

  static bool of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_FakeModeScope>()?.fake ??
        false;
  }

  @override
  bool updateShouldNotify(_FakeModeScope oldWidget) => fake != oldWidget.fake;
}

/// A page showcasing various glass transition examples.
///
/// Each example is isolated in its own widget for easy review.
class TransitionExamplesPage extends StatefulWidget {
  const TransitionExamplesPage({super.key});

  @override
  State<TransitionExamplesPage> createState() => _TransitionExamplesPageState();
}

class _TransitionExamplesPageState extends State<TransitionExamplesPage> {
  bool _fake = false;
  Key _pageKey = UniqueKey();

  void _refreshImages() {
    setState(() {
      _pageKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      key: _pageKey,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Transition Examples'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _refreshImages,
              child: const Icon(CupertinoIcons.refresh),
            ),
            CupertinoSwitch(
              value: _fake,
              onChanged: (v) => setState(() => _fake = v),
            ),
          ],
        ),
      ),
      child: _FakeModeScope(
        fake: _fake,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Text(
                    _fake ? 'FakeGlass mode' : 'LiquidGlass mode',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _fake
                          ? CupertinoColors.systemOrange.resolveFrom(context)
                          : CupertinoColors.systemGreen.resolveFrom(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _SectionHeader(title: 'Flat to Glass Transition'),
              const _SectionDescription(
                text:
                    'Transitions from a solid colored container to a glass '
                    'effect by animating visibility, blur, and thickness.',
              ),
              const FlatToGlassExample(),
              const SizedBox(height: 32),
              const _SectionHeader(title: 'Glass Intensity'),
              const _SectionDescription(
                text:
                    'Animates glass intensity from subtle to prominent by '
                    'changing blur, thickness, and saturation.',
              ),
              const GlassIntensityExample(),
              const SizedBox(height: 32),
              const _SectionHeader(title: 'Border Radius Animation'),
              const _SectionDescription(
                text:
                    'Animates the shape borderRadius from sharp (8) to '
                    'rounded (64) using LiquidShape.lerp.',
              ),
              const BorderRadiusAnimationExample(),
              const SizedBox(height: 32),
              const _SectionHeader(title: 'Combined Transition'),
              const _SectionDescription(
                text: 'Combines shape, settings, and size animations together.',
              ),
              const CombinedTransitionExample(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
  const FlatToGlassExample({super.key});

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
    glassColor: Color.fromARGB(60, 150, 150, 200), // Visible tint
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
    final fake = _FakeModeScope.of(context);
    return _ExampleContainer(
      onTap: _toggle,
      label: _isGlass
          ? 'Glass state - tap to flatten'
          : 'Flat state - tap for glass',
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final settings = LiquidGlassSettings.lerp(
            _flatSettings,
            _glassSettings,
            _animation.value,
          );
          return LiquidStretch(
            child: LiquidGlass.withOwnLayer(
              shape: const LiquidRoundedSuperellipse(borderRadius: 24),
              settings: settings,
              fake: fake,
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
  const GlassIntensityExample({super.key});

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
    final fake = _FakeModeScope.of(context);
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
              fake: fake,
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
  const BorderRadiusAnimationExample({super.key});

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
    final fake = _FakeModeScope.of(context);
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
              fake: fake,
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
  const CombinedTransitionExample({super.key});

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
    final fake = _FakeModeScope.of(context);
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
                  fake: fake,
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
// SHARED COMPONENTS
// =============================================================================

/// Container for examples with background and tap handling.
class _ExampleContainer extends StatefulWidget {
  const _ExampleContainer({
    required this.child,
    required this.label,
    this.onTap,
  });

  final Widget child;
  final String label;
  final VoidCallback? onTap;

  @override
  State<_ExampleContainer> createState() => _ExampleContainerState();
}

class _ExampleContainerState extends State<_ExampleContainer> {
  // Random image ID for picsum.photos
  late final int _imageId;

  @override
  void initState() {
    super.initState();
    // Generate a stable random ID based on hashCode
    _imageId = Random().nextInt(1000);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  Image.network(
                    'https://picsum.photos/2000/2000?random=$_imageId',
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
                  Center(child: widget.child),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.label,
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
