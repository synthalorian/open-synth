import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/keyboard_split.dart';
import '../providers/keyboard_split_provider.dart';
import '../providers/synth_providers.dart';
import '../theme/synth_theme.dart';

/// Polls CPU load and active voices from the native engine.
final performanceMetricsProvider = StreamProvider.autoDispose<PerformanceMetrics>((ref) {
  final synth = ref.watch(synthEngineProvider);
  final pair = ref.watch(synthPairProvider);
  final split = ref.watch(keyboardSplitProvider);

  if (synth == null) {
    return Stream.value(PerformanceMetrics.zero());
  }

  final controller = StreamController<PerformanceMetrics>();
  Timer? timer;

  void tick(_) {
    final zoneAVoices = synth.activeVoices;
    final zoneBVoices = pair?.zoneBVoices ?? 0;
    final cpuLoad = synth.cpuLoad;

    controller.add(PerformanceMetrics(
      cpuLoad: cpuLoad,
      zoneAVoices: zoneAVoices,
      zoneBVoices: split.mode == SplitMode.normal ? 0 : zoneBVoices,
      totalVoices: zoneAVoices + (split.mode == SplitMode.normal ? 0 : zoneBVoices),
    ));
  }

  timer = Timer.periodic(const Duration(milliseconds: 200), tick);
  tick(null); // emit immediately

  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });

  return controller.stream;
});

class PerformanceMetrics {
  final double cpuLoad;
  final int zoneAVoices;
  final int zoneBVoices;
  final int totalVoices;

  const PerformanceMetrics({
    required this.cpuLoad,
    required this.zoneAVoices,
    required this.zoneBVoices,
    required this.totalVoices,
  });

  factory PerformanceMetrics.zero() => const PerformanceMetrics(
        cpuLoad: 0.0,
        zoneAVoices: 0,
        zoneBVoices: 0,
        totalVoices: 0,
      );
}

/// A compact retro-styled performance meter bar showing CPU usage and voice counts.
class PerformanceMeters extends ConsumerWidget {
  const PerformanceMeters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(performanceMetricsProvider);
    final split = ref.watch(keyboardSplitProvider);

    return metricsAsync.when(
      data: (m) => _buildContent(context, m, split),
      loading: () => _buildContent(context, PerformanceMetrics.zero(), split),
      error: (_, _) => _buildContent(context, PerformanceMetrics.zero(), split),
    );
  }

  Widget _buildContent(BuildContext context, PerformanceMetrics m, KeyboardSplit split) {
    final cpuPercent = (m.cpuLoad * 100).clamp(0.0, 100.0);
    final cpuColor = m.cpuLoad > 0.8
        ? SynthTheme.magenta
        : m.cpuLoad > 0.5
            ? SynthTheme.orange
            : SynthTheme.cyan;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: SynthTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SynthTheme.purple.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          // ── CPU Bar ──
          Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  'CPU',
                  style: TextStyle(
                    color: cpuColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        // Background track
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: SynthTheme.purple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // Fill bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 8,
                          width: constraints.maxWidth * m.cpuLoad.clamp(0.0, 1.0),
                          decoration: BoxDecoration(
                            color: cpuColor,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: cpuColor.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  '${cpuPercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: cpuColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Voice counts ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _VoicePill(
                label: 'A',
                color: SynthTheme.cyan,
                count: m.zoneAVoices,
              ),
              if (split.mode != SplitMode.normal) ...[
                const SizedBox(width: 8),
                _VoicePill(
                  label: 'B',
                  color: SynthTheme.magenta,
                  count: m.zoneBVoices,
                ),
              ],
              const SizedBox(width: 8),
              _VoicePill(
                label: 'TOT',
                color: SynthTheme.orange,
                count: m.totalVoices,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoicePill extends StatelessWidget {
  final String label;
  final Color color;
  final int count;

  const _VoicePill({
    required this.label,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final hasVoices = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: hasVoices ? color.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasVoices ? color.withValues(alpha: 0.4) : SynthTheme.purple.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasVoices ? color : SynthTheme.purple.withValues(alpha: 0.3),
              boxShadow: hasVoices
                  ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4)]
                  : null,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$label $count',
            style: TextStyle(
              color: hasVoices ? color : SynthTheme.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
