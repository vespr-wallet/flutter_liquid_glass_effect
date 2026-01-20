import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:liquid_glass_renderer_example/basic_app.dart';
export 'package:logging/logging.dart' show Level, Logger;

void main() {
  FlutterMemoryAllocations.instance.addListener(
    (ObjectEvent event) => LeakTracking.dispatchObjectEvent(event.toMap()),
  );
  LeakTracking.start();
  LeakTracking.phase = PhaseSettings(
    leakDiagnosticConfig: LeakDiagnosticConfig(collectStackTraceOnStart: true),
  );
  LgrLogs.initAllLogs(); // Disabled for benchmarking
  runApp(CupertinoApp(home: BasicApp()));
}

final settingsNotifier = ValueNotifier<LiquidGlassSettings>(
  LiquidGlassSettings(
    thickness: 20,
    lightAngle: 0.5 * pi,
    liquidGlassConfigs: LiquidGlassConfigs(chromaticAberration: 1),
  ),
);

final cornerRadiusNotifier = ValueNotifier<double>(100);

final glassColorNotifier = ValueNotifier<Color>(
  const Color.fromARGB(0, 255, 255, 255),
);
