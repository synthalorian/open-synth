enum PresetCategory {
  pads('Pads'),
  leads('Leads'),
  bass('Bass'),
  keys('Keys'),
  arps('Arps'),
  fx('FX'),
  synthwave('Synthwave'),
  custom('Custom');

  const PresetCategory(this.displayName);

  final String displayName;
}
