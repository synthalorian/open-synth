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
  wtBrass('Brass WT', Icons.airline_seat_recline_extra),
  wtStrings('Strings WT', Icons.queue_music),
  wtWoodwind('Woodwind WT', Icons.wind_power),
  wtOrgan('Organ WT', Icons.church),
  wtBell('Bell WT', Icons.notifications),
  wtSynthBass('Bass WT', Icons.electric_bolt),
  wtSynthLead('Lead WT', Icons.bolt),
  wtPad('Pad WT', Icons.cloud),
  wtEPiano('E.Piano WT', Icons.piano),
  pmKarplus('Plucked', Icons.music_note),
  pmKarplusBright('Bright Pluck', Icons.bolt),
  pmKarplusBass('Bass Pluck', Icons.electric_bolt),
  pmModalMallet('Mallet', Icons.sports_cricket),
  pmModalVibraphone('Vibraphone', Icons.waves),
  pmModalSteel('Steel Drum', Icons.circle),
  random('S&H', Icons.shuffle);

  const Waveform(this.displayName, this.icon);

  final String displayName;
  final IconData icon;
}
