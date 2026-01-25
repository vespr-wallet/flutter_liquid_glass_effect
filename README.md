# Liquid Glass Workspace

[![Powered by Mason](https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge)](https://github.com/felangel/mason)
[![melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg?style=flat-square)](https://github.com/invertase/melos)


Flutter Liquid Glass Workspace

## Package overview
| Package                                                                   | pub.dev                                                                                                                              | Description                                           |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------- |
| [liquid_glass_plus](./packages/liquid_glass_renderer)                 | [![Pub Version](https://img.shields.io/pub/v/liquid_glass_plus)](https://pub.dev/packages/liquid_glass_plus)                 | A Flutter package for rendering liquid glass effects. |

## Acknowledgments

This project started as a fork of [flutter_liquid_glass](https://github.com/whynotmake-it/flutter_liquid_glass) by [whynotmake.it](https://whynotmake.it).

**Why the fork?**

1. **Platform-agnostic focus**: This package aims to create beautiful glass widgets without replicating the entire iOS glass behaviour (such as cross-widget morphing/blending). We intentionally keep things more platform-agnostic. Replicating actual iOS widgets (like the bottom bar) may be done as a separate package building on top of this one.

2. **Production-ready simplifications**: Some features were simplified to make the package more production-ready, and implicit animations have been added (with more to come).

3. **Improved Skia compatibility**: The fake glass (Skia) implementation looks significantly closer to the Impeller (shader-based) implementation than the original. However, this comes at a slight performance cost when testing on Impeller.