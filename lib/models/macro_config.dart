import 'package:flutter/foundation.dart';

@immutable
class MacroConfig {
  final String name;
  final int ccNumber;
  final double minValue;
  final double maxValue;
  final double value;

  const MacroConfig({
    this.name = 'Macro',
    this.ccNumber = 1,
    this.minValue = 0.0,
    this.maxValue = 1.0,
    this.value = 0.0,
  });

  MacroConfig copyWith({
    String? name,
    int? ccNumber,
    double? minValue,
    double? maxValue,
    double? value,
  }) {
    return MacroConfig(
      name: name ?? this.name,
      ccNumber: ccNumber ?? this.ccNumber,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'ccNumber': ccNumber,
        'minValue': minValue,
        'maxValue': maxValue,
        'value': value,
      };

  factory MacroConfig.fromJson(Map<String, dynamic> json) => MacroConfig(
        name: json['name'] as String,
        ccNumber: json['ccNumber'] as int,
        minValue: (json['minValue'] as num).toDouble(),
        maxValue: (json['maxValue'] as num).toDouble(),
        value: (json['value'] as num).toDouble(),
      );
}

class MacroBank {
  final List<MacroConfig> macros;

  const MacroBank({
    this.macros = const [
      MacroConfig(name: 'Cutoff', ccNumber: 74, minValue: 20, maxValue: 20000, value: 0.5),
      MacroConfig(name: 'Resonance', ccNumber: 71, minValue: 0, maxValue: 1, value: 0.3),
      MacroConfig(name: 'LFO Depth', ccNumber: 1, minValue: 0, maxValue: 1, value: 0.0),
      MacroConfig(name: 'Drive', ccNumber: 94, minValue: 0, maxValue: 1, value: 0.0),
    ],
  });

  MacroConfig getMacro(int index) =>
      index < macros.length ? macros[index] : const MacroConfig();

  MacroBank copyWithMacro(int index, MacroConfig macro) {
    final newMacros = List<MacroConfig>.from(macros);
    if (index < newMacros.length) {
      newMacros[index] = macro;
    } else {
      while (newMacros.length <= index) {
        newMacros.add(const MacroConfig());
      }
      newMacros[index] = macro;
    }
    return MacroBank(macros: newMacros);
  }

  Map<String, dynamic> toJson() => {
        'macros': macros.map((m) => m.toJson()).toList(),
      };

  factory MacroBank.fromJson(Map<String, dynamic> json) => MacroBank(
        macros: (json['macros'] as List)
            .map((e) => MacroConfig.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
