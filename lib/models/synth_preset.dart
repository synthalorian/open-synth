import 'package:uuid/uuid.dart';

import 'envelope.dart';
import 'filter_config.dart';
import 'fx_config.dart';
import 'lfo_config.dart';
import 'oscillator.dart';
import 'preset_category.dart';

class SynthPreset {
  final String id;
  final String name;
  final PresetCategory category;
  final Oscillator osc1;
  final Oscillator osc2;
  final FilterConfig filter;
  final Envelope ampEnvelope;
  final Envelope filterEnvelope;
  final LfoConfig lfo1;
  final LfoConfig lfo2;
  final ChorusConfig chorus;
  final DelayConfig delay;
  final ReverbConfig reverb;
  final PhaserConfig phaser;
  final FlangerConfig flanger;
  final CompressorConfig compressor;
  final DriveConfig drive;
  // ── New multi-slot FX (slots 1-3) ──
  final List<FxSlotConfig> fxSlots;
  final EqConfig eq;
  final LimiterConfig limiter;
  final RotaryConfig rotary;
  final TremoloConfig tremolo;
  final double masterVolume;
  final List<String> tags;
  final String author;
  final bool isBassPreset;

  SynthPreset({
    String? id,
    required this.name,
    required this.category,
    Oscillator? osc1,
    Oscillator? osc2,
    FilterConfig? filter,
    Envelope? ampEnvelope,
    Envelope? filterEnvelope,
    LfoConfig? lfo1,
    LfoConfig? lfo2,
    ChorusConfig? chorus,
    DelayConfig? delay,
    ReverbConfig? reverb,
    PhaserConfig? phaser,
    FlangerConfig? flanger,
    CompressorConfig? compressor,
    DriveConfig? drive,
    List<FxSlotConfig>? fxSlots,
    EqConfig? eq,
    LimiterConfig? limiter,
    RotaryConfig? rotary,
    TremoloConfig? tremolo,
    this.masterVolume = 0.8,
    this.tags = const [],
    this.author = 'Open Synth',
    this.isBassPreset = false,
  })  : id = id ?? const Uuid().v4(),
        osc1 = osc1 ?? const Oscillator(),
        osc2 = osc2 ?? const Oscillator(enabled: false),
        filter = filter ?? const FilterConfig(),
        ampEnvelope = ampEnvelope ?? const Envelope(),
        filterEnvelope = filterEnvelope ?? const Envelope(),
        lfo1 = lfo1 ?? const LfoConfig(),
        lfo2 = lfo2 ?? const LfoConfig(),
        chorus = chorus ?? const ChorusConfig(),
        delay = delay ?? const DelayConfig(),
        reverb = reverb ?? const ReverbConfig(),
        phaser = phaser ?? const PhaserConfig(),
        flanger = flanger ?? const FlangerConfig(),
        compressor = compressor ?? const CompressorConfig(),
        drive = drive ?? const DriveConfig(),
        fxSlots = fxSlots ?? const [],
        eq = eq ?? const EqConfig(),
        limiter = limiter ?? const LimiterConfig(),
        rotary = rotary ?? const RotaryConfig(),
        tremolo = tremolo ?? const TremoloConfig();

  SynthPreset copyWith({
    String? id,
    String? name,
    PresetCategory? category,
    Oscillator? osc1,
    Oscillator? osc2,
    FilterConfig? filter,
    Envelope? ampEnvelope,
    Envelope? filterEnvelope,
    LfoConfig? lfo1,
    LfoConfig? lfo2,
    ChorusConfig? chorus,
    DelayConfig? delay,
    ReverbConfig? reverb,
    PhaserConfig? phaser,
    FlangerConfig? flanger,
    CompressorConfig? compressor,
    DriveConfig? drive,
    List<FxSlotConfig>? fxSlots,
    EqConfig? eq,
    LimiterConfig? limiter,
    RotaryConfig? rotary,
    TremoloConfig? tremolo,
    double? masterVolume,
    List<String>? tags,
    String? author,
    bool? isBassPreset,
  }) {
    return SynthPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      osc1: osc1 ?? this.osc1,
      osc2: osc2 ?? this.osc2,
      filter: filter ?? this.filter,
      ampEnvelope: ampEnvelope ?? this.ampEnvelope,
      filterEnvelope: filterEnvelope ?? this.filterEnvelope,
      lfo1: lfo1 ?? this.lfo1,
      lfo2: lfo2 ?? this.lfo2,
      chorus: chorus ?? this.chorus,
      delay: delay ?? this.delay,
      reverb: reverb ?? this.reverb,
      phaser: phaser ?? this.phaser,
      flanger: flanger ?? this.flanger,
      compressor: compressor ?? this.compressor,
      drive: drive ?? this.drive,
      fxSlots: fxSlots ?? this.fxSlots,
      eq: eq ?? this.eq,
      limiter: limiter ?? this.limiter,
      rotary: rotary ?? this.rotary,
      tremolo: tremolo ?? this.tremolo,
      masterVolume: masterVolume ?? this.masterVolume,
      tags: tags ?? this.tags,
      author: author ?? this.author,
      isBassPreset: isBassPreset ?? this.isBassPreset,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.index,
        'osc1': osc1.toJson(),
        'osc2': osc2.toJson(),
        'filter': filter.toJson(),
        'ampEnvelope': ampEnvelope.toJson(),
        'filterEnvelope': filterEnvelope.toJson(),
        'lfo1': lfo1.toJson(),
        'lfo2': lfo2.toJson(),
        'chorus': chorus.toJson(),
        'delay': delay.toJson(),
        'reverb': reverb.toJson(),
        'phaser': phaser.toJson(),
        'flanger': flanger.toJson(),
        'compressor': compressor.toJson(),
        'drive': drive.toJson(),
        'fxSlots': fxSlots.map((s) => s.toJson()).toList(),
        'eq': eq.toJson(),
        'limiter': limiter.toJson(),
        'rotary': rotary.toJson(),
        'tremolo': tremolo.toJson(),
        'masterVolume': masterVolume,
        'tags': tags,
        'author': author,
        'isBassPreset': isBassPreset,
      };

  factory SynthPreset.fromJson(Map<String, dynamic> json) => SynthPreset(
        id: json['id'] as String,
        name: json['name'] as String,
        category: PresetCategory.values[json['category'] as int],
        osc1: Oscillator.fromJson(json['osc1'] as Map<String, dynamic>),
        osc2: Oscillator.fromJson(json['osc2'] as Map<String, dynamic>),
        filter:
            FilterConfig.fromJson(json['filter'] as Map<String, dynamic>),
        ampEnvelope:
            Envelope.fromJson(json['ampEnvelope'] as Map<String, dynamic>),
        filterEnvelope:
            Envelope.fromJson(json['filterEnvelope'] as Map<String, dynamic>),
        lfo1: LfoConfig.fromJson(json['lfo1'] as Map<String, dynamic>),
        lfo2: LfoConfig.fromJson(json['lfo2'] as Map<String, dynamic>),
        chorus: json.containsKey('chorus') 
            ? ChorusConfig.fromJson(json['chorus'] as Map<String, dynamic>)
            : const ChorusConfig(),
        delay: json.containsKey('delay')
            ? DelayConfig.fromJson(json['delay'] as Map<String, dynamic>)
            : const DelayConfig(),
        reverb: json.containsKey('reverb')
            ? ReverbConfig.fromJson(json['reverb'] as Map<String, dynamic>)
            : const ReverbConfig(),
        phaser: json.containsKey('phaser')
            ? PhaserConfig.fromJson(json['phaser'] as Map<String, dynamic>)
            : const PhaserConfig(),
        flanger: json.containsKey('flanger')
            ? FlangerConfig.fromJson(json['flanger'] as Map<String, dynamic>)
            : const FlangerConfig(),
        compressor: json.containsKey('compressor')
            ? CompressorConfig.fromJson(json['compressor'] as Map<String, dynamic>)
            : const CompressorConfig(),
        drive: json.containsKey('drive')
            ? DriveConfig.fromJson(json['drive'] as Map<String, dynamic>)
            : const DriveConfig(),
        fxSlots: json.containsKey('fxSlots')
            ? (json['fxSlots'] as List).map((e) => FxSlotConfig.fromJson(e as Map<String, dynamic>)).toList()
            : const [],
        eq: json.containsKey('eq')
            ? EqConfig.fromJson(json['eq'] as Map<String, dynamic>)
            : const EqConfig(),
        limiter: json.containsKey('limiter')
            ? LimiterConfig.fromJson(json['limiter'] as Map<String, dynamic>)
            : const LimiterConfig(),
        rotary: json.containsKey('rotary')
            ? RotaryConfig.fromJson(json['rotary'] as Map<String, dynamic>)
            : const RotaryConfig(),
        tremolo: json.containsKey('tremolo')
            ? TremoloConfig.fromJson(json['tremolo'] as Map<String, dynamic>)
            : const TremoloConfig(),
        masterVolume: (json['masterVolume'] as num).toDouble(),
        tags: (json['tags'] as List).cast<String>(),
        author: json['author'] as String,
        isBassPreset: json['isBassPreset'] as bool,
      );
}
