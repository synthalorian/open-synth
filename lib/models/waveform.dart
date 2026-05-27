import 'package:flutter/material.dart';

enum Waveform {
  sine('Sine', Icons.waves),
  saw('Saw', Icons.signal_cellular_alt),
  square('Square', Icons.crop_square),
  triangle('Triangle', Icons.change_history),
  noise('Noise', Icons.grain),
  wavetable('Wavetable', Icons.dashboard),
  wt_piano('Piano WT', Icons.keyboard),
  wt_guitar('Guitar WT', Icons.music_note),
  wt_choir('Choir WT', Icons.people),
  random('S&H', Icons.shuffle);

  const Waveform(this.displayName, this.icon);

  final String displayName;
  final IconData icon;
}
