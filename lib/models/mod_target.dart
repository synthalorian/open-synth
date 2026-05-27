enum ModTarget {
  pitch('Pitch'),
  filterCutoff('Filter Cutoff'),
  amplitude('Amplitude'),
  pan('Pan'),
  osc2Detune('OSC2 Detune');

  const ModTarget(this.displayName);

  final String displayName;
}

enum LfoTarget {
  pitch('Pitch'),
  filter('Filter'),
  amplitude('Amplitude'),
  pan('Pan');

  const LfoTarget(this.displayName);

  final String displayName;
}

enum FilterType {
  lowpass('Low Pass'),
  highpass('High Pass'),
  bandpass('Band Pass'),
  notch('Notch'),
  lowShelf('Low Shelf'),
  highShelf('High Shelf'),
  peakingEQ('Peaking EQ');

  const FilterType(this.displayName);

  final String displayName;
}
