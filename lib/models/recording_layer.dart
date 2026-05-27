import 'midi_event.dart';
import 'preset_category.dart';
import 'synth_preset.dart';

/// One recorded layer in the multi-track arranger.
/// Each layer is a separate recording pass with its own preset and events.
class RecordingLayer {
  final String id;
  final String name;
  final DateTime createdAt;
  final SynthPreset preset;
  final List<MidiEventRecord> events;
  final int durationMs;

  RecordingLayer({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.preset,
    required this.events,
    required this.durationMs,
  });

  RecordingLayer.empty({this.name = 'Layer 1'})
      : id = 'layer_${DateTime.now().millisecondsSinceEpoch}',
        createdAt = DateTime.now(),
        preset = SynthPreset(name: name, category: PresetCategory.custom),
        events = [],
        durationMs = 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'preset': preset.toJson(),
        'events': events.map((e) => e.toJson()).toList(),
        'durationMs': durationMs,
      };

  factory RecordingLayer.fromJson(Map<String, dynamic> json) => RecordingLayer(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        preset: SynthPreset.fromJson(
            json['preset'] as Map<String, dynamic>),
        events: (json['events'] as List)
            .map((e) => MidiEventRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        durationMs: json['durationMs'] as int? ?? 0,
      );

  RecordingLayer copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    SynthPreset? preset,
    List<MidiEventRecord>? events,
    int? durationMs,
  }) {
    return RecordingLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      preset: preset ?? this.preset,
      events: events ?? List.from(this.events),
      durationMs: durationMs ?? this.durationMs,
    );
  }
}
