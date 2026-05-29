import 'package:flutter/material.dart';

enum Waveform {
  sine('Sine', Icons.waves),
  saw('Saw', Icons.signal_cellular_alt),
  square('Square', Icons.crop_square),
  triangle('Triangle', Icons.change_history),
  noise('Noise', Icons.grain),
  wavetable('Wavetable', Icons.dashboard),
  wtPiano('Piano WT', Icons.keyboard),
  wtGuitar('Guitar WT', Icons.music_note),
  wtChoir('Choir WT', Icons.people),
  random('S&H', Icons.shuffle);

  const Waveform(this.displayName, this.icon);

  final String displayName;
  final IconData icon;
}
