enum PresetCategory {
  pads('Pads'),
  leads('Leads'),
  bass('Bass'),
  keys('Keys'),
  arps('Arps'),
  fx('FX'),
  synthwave('Synthwave'),
  piano('Piano'),
  organ('Organ'),
  guitar('Guitar'),
  strings('Strings'),
  brass('Brass'),
  choir('Choir'),
  percussion('Percussion'),
  custom('Custom'),
  drums('Drums'),
  acousticGuitar('Acoustic Guitar'),
  electricGuitar('Electric Guitar'),
  bassGuitar('Bass Guitar'),
  electricPiano('Electric Piano'),
  clavinet('Clavinet'),
  mallets('Mallets'),
  woodwinds('Woodwinds'),
  ethnic('Ethnic');

  const PresetCategory(this.displayName);

  final String displayName;
}
