import 'dart:convert';
import 'dart:io';

import '../utils/logger.dart';

import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../models/synth_preset.dart';
import '../ffi/audio_platform.dart';
import '../ffi/openamp_audio_stream.dart';
import '../providers/midi_provider.dart';
import '../providers/recent_presets_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/synth_providers.dart';
import '../theme/synth_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SETTINGS',
          style: GoogleFonts.orbitron(
            color: SynthTheme.cyan,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('PRESET LIBRARY'),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.download,
              label: 'Export All Presets',
              color: SynthTheme.cyan,
              onTap: () => _exportPresets(context, ref),
            ),
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.upload,
              label: 'Import Presets',
              color: SynthTheme.purple,
              onTap: () => _importPresets(context, ref),
            ),
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.restore,
              label: 'Reset to Factory Presets',
              color: SynthTheme.magenta,
              onTap: () => _confirmFactoryReset(context, ref),
            ),
            const SizedBox(height: 32),

            _SectionTitle('MIDI'),
            const SizedBox(height: 12),
            _MidiDeviceSelector(),
            const SizedBox(height: 32),

            _SectionTitle('AUDIO'),
            const SizedBox(height: 12),
            if (hasAudioDeviceEnumeration) ...[
              // Desktop: show full device selector + buffer size
              _AudioDeviceSelector(),
              const SizedBox(height: 10),
              _AudioBufferSelector(),
            ] else ...[
              // Mobile: single output device, show backend info
              _AudioBackendInfo(),
              const SizedBox(height: 10),
              _AudioBufferSelector(),
            ],
            const SizedBox(height: 32),

            _SectionTitle('RECENT PRESETS'),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.delete_outline,
              label: 'Clear Recent History',
              color: SynthTheme.magenta,
              onTap: () => _confirmClearRecents(context, ref),
            ),
            const SizedBox(height: 32),

            _SectionTitle('APPEARANCE'),
            const SizedBox(height: 12),
            _ThemeToggle(),
            const SizedBox(height: 32),

            _SectionTitle('SYSTEM'),
            const SizedBox(height: 12),
            _InfoRow('Version', '1.2.0'),
            _InfoRow('Engine', 'OpenAmp DSP'),
            _InfoRow('Audio Backend', audioBackendName),
            _AudioDiagnosticsSummary(),
            const SizedBox(height: 32),

            _SectionTitle('CREDITS'),
            const SizedBox(height: 12),
            Text(
              'Open Synth is a software synthesizer built with Flutter and the OpenAmp DSP engine.\n\nDesigned for the neon-soaked aesthetics of 1984. 🎹🦈',
              style: TextStyle(
                color: SynthTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Developed by synth (synthalorian)',
              style: TextStyle(
                color: SynthTheme.purple,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPresets(BuildContext context, WidgetRef ref) async {
    try {
      final presets = ref.read(presetListProvider);
      final jsonList = presets.map((p) => p.toJson()).toList();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);

      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/open_synth_presets.json';
      final file = File(path);
      await file.writeAsString(jsonString);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${presets.length} presets to $path'),
            backgroundColor: SynthTheme.card,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, st) {
      appLogger.severe('Export failed', e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _importPresets(BuildContext context, WidgetRef ref) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/open_synth_presets.json';
      final file = File(path);

      if (!await file.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No import file found at $path'),
              backgroundColor: SynthTheme.card,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final jsonString = await file.readAsString();
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final notifier = ref.read(presetListProvider.notifier);
      int imported = 0;

      final existingIds = ref.read(presetListProvider).map((p) => p.id).toSet();
      for (final item in jsonList) {
        try {
          final map = item as Map<String, dynamic>;
          final id = map['id'] as String?;
          if (id != null && !existingIds.contains(id)) {
            notifier.addPreset(SynthPreset.fromJson(map));
            existingIds.add(id);
            imported++;
          }
        } catch (_) {
          // Skip invalid entries.
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $imported presets'),
            backgroundColor: SynthTheme.card,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, st) {
      appLogger.severe('Import failed', e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmClearRecents(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SynthTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: SynthTheme.magenta.withValues(alpha: 0.3)),
        ),
        title: Text(
          'Clear Recent History?',
          style: TextStyle(color: SynthTheme.magenta, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will erase your recently-used preset history. Your favorites and presets will not be affected.',
          style: TextStyle(color: SynthTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(color: SynthTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(recentPresetsProvider.notifier).clear();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recent history cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'CLEAR',
              style: TextStyle(
                color: SynthTheme.magenta,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmFactoryReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SynthTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: SynthTheme.magenta.withValues(alpha: 0.3)),
        ),
        title: Text(
          'Reset to Factory?',
          style: TextStyle(color: SynthTheme.magenta, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will erase all your custom presets and restore the original factory bank. This cannot be undone.',
          style: TextStyle(color: SynthTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(color: SynthTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(presetListProvider.notifier).resetToFactory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Factory presets restored'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'RESET',
              style: TextStyle(
                color: SynthTheme.magenta,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: SynthTheme.cyan,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: SynthTheme.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color.withValues(alpha: 0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: SynthTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MidiDeviceSelector extends ConsumerWidget {
  const _MidiDeviceSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(midiDevicesProvider);
    final selected = ref.watch(selectedMidiDeviceProvider);

    return devicesAsync.when(
      data: (devices) {
        if (devices.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SynthTheme.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.usb_off, color: SynthTheme.textSecondary, size: 18),
                const SizedBox(width: 10),
                Text(
                  'No MIDI devices detected',
                  style: TextStyle(color: SynthTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: SynthTheme.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.2)),
          ),            child: DropdownButtonHideUnderline(
            child: DropdownButton<MidiDevice?>(
              isExpanded: true,
              value: selected != null && devices.any((d) => d.id == selected.id) ? selected : null,
              dropdownColor: SynthTheme.surface,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              icon: Icon(Icons.keyboard_arrow_down, color: SynthTheme.cyan, size: 18),
              hint: Text(
                'Select MIDI device…',
                style: TextStyle(color: SynthTheme.textSecondary.withValues(alpha: 0.6), fontSize: 13),
              ),
              items: [
                const DropdownMenuItem<MidiDevice?>(
                  value: null,
                  child: Text('None (disable MIDI input)'),
                ),
                ...devices.map((device) {
                  final isConnected = selected?.id == device.id;
                  return DropdownMenuItem<MidiDevice?>(
                    value: device,
                    child: Row(
                      children: [
                        Icon(
                          isConnected ? Icons.circle : Icons.circle_outlined,
                          color: isConnected ? SynthTheme.cyan : SynthTheme.textSecondary,
                          size: 8,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            device.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (device) {
                ref.read(selectedMidiDeviceProvider.notifier).state = device;
              },
            ),
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SynthTheme.card,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: SynthTheme.cyan,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Scanning MIDI devices…',
              style: TextStyle(color: SynthTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SynthTheme.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'MIDI scan failed: $err',
                style: TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioDeviceSelector extends ConsumerWidget {
  const _AudioDeviceSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedAudioDeviceProvider);
    final devicesAsync = ref.watch(audioDevicesProvider);

    final devices = devicesAsync ?? [];
    final selectedDevice = devices.where((d) => d.index == selectedIndex).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speaker, color: SynthTheme.cyan, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selectedDevice?.name ?? 'Default Device',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ),
              if (selectedDevice?.isDefault == true)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    '(default)',
                    style: TextStyle(
                      color: SynthTheme.cyan.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (devicesAsync == null)
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Audio device enumeration failed',
                  style: TextStyle(
                    color: Colors.redAccent.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            )
          else if (devices.isEmpty)
            Text(
              'No audio output devices found',
              style: TextStyle(
                color: SynthTheme.textSecondary.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            )
          else
            _buildDeviceList(devices, selectedIndex, ref),
          const SizedBox(height: 4),
          Text(
            'Changes take effect on next note.',
            style: TextStyle(
              color: SynthTheme.textSecondary.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(
      List<AudioDeviceInfo> devices, int selectedIndex, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Default device option
          _DeviceChip(
            label: 'System Default',
            isSelected: selectedIndex == -1,
            isDefault: false,
            onTap: () => ref.read(selectedAudioDeviceProvider.notifier).select(-1),
          ),
          const SizedBox(width: 6),
          ...devices.map((device) => _DeviceChip(
                label: device.name,
                isSelected: device.index == selectedIndex,
                isDefault: device.isDefault,
                onTap: () =>
                    ref.read(selectedAudioDeviceProvider.notifier).select(device.index),
              )),
        ],
      ),
    );
  }
}

/// Mobile-only: shows which audio backend is active (Oboe on Android,
/// AudioUnits on iOS).  There's nothing to configure — the OS picks the
/// output device — so we just display an informational card.
class _AudioBackendInfo extends ConsumerWidget {
  const _AudioBackendInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.speaker, color: SynthTheme.cyan, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio Backend',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  audioBackendName,
                  style: TextStyle(
                    color: SynthTheme.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: SynthTheme.cyan.withValues(alpha: 0.6), size: 16),
        ],
      ),
    );
  }
}

class _DeviceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDefault;
  final VoidCallback onTap;

  const _DeviceChip({
    required this.label,
    required this.isSelected,
    required this.isDefault,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? SynthTheme.cyan.withValues(alpha: 0.2)
              : SynthTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? SynthTheme.cyan.withValues(alpha: 0.5)
                : SynthTheme.purple.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? SynthTheme.cyan : Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _AudioDiagnosticsSummary extends ConsumerWidget {
  const _AudioDiagnosticsSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diag = ref.watch(audioStreamDiagnosticsProvider);
    final selectedIdx = ref.watch(selectedAudioDeviceProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          _InfoRow('Stream', diag.isRunning ? '▶ Running' : '■ Stopped'),
          _InfoRow('Device', selectedIdx == -1
              ? 'Default'
              : 'Index $selectedIdx'),
          _InfoRow('Callback Count', '${diag.callbackCount}'),
          if (diag.lastError.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.redAccent, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      diag.lastError,
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AudioBufferSelector extends ConsumerWidget {
  const _AudioBufferSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bufferSize = ref.watch(audioBufferSizeProvider);
    final notifier = ref.read(audioBufferSizeProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Buffer Size',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SynthTheme.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$bufferSize samples',
                  style: TextStyle(
                    color: SynthTheme.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: notifier.availableSizes.map((size) {
              final isSelected = size == bufferSize;
              return Expanded(
                child: GestureDetector(
                  onTap: () => notifier.set(size),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? SynthTheme.cyan.withValues(alpha: 0.2)
                          : SynthTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? SynthTheme.cyan.withValues(alpha: 0.5)
                            : SynthTheme.purple.withValues(alpha: 0.15),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$size',
                      style: TextStyle(
                        color: isSelected ? SynthTheme.cyan : SynthTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          Text(
            'Lower = lower latency, higher CPU. Higher = safer on slower systems.',
            style: TextStyle(
              color: SynthTheme.textSecondary.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return GestureDetector(
      onTap: () => ref.read(themeModeProvider.notifier).toggle(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SynthTheme.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: isDark ? SynthTheme.cyan : SynthTheme.orange,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDark ? 'Dark Mode' : 'Light Mode',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    isDark ? 'Neon-soaked 1984 aesthetics' : 'Clean studio daylight theme',
                    style: TextStyle(
                      color: SynthTheme.textSecondary.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: isDark ? SynthTheme.cyan.withValues(alpha: 0.3) : SynthTheme.orange.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? SynthTheme.cyan : SynthTheme.orange,
                    shape: BoxShape.circle,
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
