import 'package:flutter/material.dart';

enum Waveform {
  sine('Sine', Icons.waves),
  saw('Saw', Icons.signal_cellular_alt),
  square('Square', Icons.crop_square),
  triangle('Triangle', Icons.change_history),
  noise('Noise', Icons.grain);

  const Waveform(this.displayName, this.icon);

  final String displayName;
  final IconData icon;
}
