import '../models/sample_preset.dart';

/// Bundled sample presets from VSCO 2 CE (CC0 license).
/// These map to SFZ files in assets/samples/VSCO-2-CE-1.1.0/
///
/// The paths are relative to the app's working directory at runtime.
/// On desktop, the app should resolve these relative to the executable.
/// On mobile, they're bundled as Flutter assets.
final List<SamplePreset> bundledSamplePresets = [
  // Piano
  SamplePreset(
    id: 'vsco_piano_upright',
    name: 'Upright Piano',
    category: SampleCategories.piano,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/UprightPiano.sfz',
    description: 'Intimate upright piano with natural resonance',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_piano_vsu',
    name: 'VS Upright',
    category: SampleCategories.piano,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/VSUpright1.sfz',
    description: 'Bright upright piano, alternative take',
    isBundled: true,
  ),

  // Organ
  SamplePreset(
    id: 'vsco_organ_loud',
    name: 'Pipe Organ Loud',
    category: SampleCategories.organ,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/OrganLoud.sfz',
    description: 'Full pipe organ with all stops pulled',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_organ_quiet',
    name: 'Pipe Organ Quiet',
    category: SampleCategories.organ,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/OrganQuiet.sfz',
    description: 'Softer pipe organ registration',
    isBundled: true,
  ),

  // Strings - Solo Violin
  SamplePreset(
    id: 'vsco_violin_solo_vib',
    name: 'Solo Violin Vibrato',
    category: SampleCategories.strings,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/SViolinVib.sfz',
    description: 'Expressive solo violin with vibrato',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_violin_solo_pizz',
    name: 'Solo Violin Pizzicato',
    category: SampleCategories.strings,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/SViolinPizz.sfz',
    description: 'Plucked solo violin',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_violin_solo_trem',
    name: 'Solo Violin Tremolo',
    category: SampleCategories.strings,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/SViolinTrem.sfz',
    description: 'Tremolo bowed solo violin',
    isBundled: true,
  ),

  // Strings - Ensemble
  SamplePreset(
    id: 'vsco_violin_ens_vib',
    name: 'Violin Ensemble',
    category: SampleCategories.strings,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/ViolinEnsSusVib.sfz',
    description: 'Section violins with vibrato',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_viola_ens_vib',
    name: 'Viola Ensemble',
    category: SampleCategories.strings,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/ViolaEnsSusVib.sfz',
    description: 'Section violas with vibrato',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_cello_ens_vib',
    name: 'Cello Ensemble',
    category: SampleCategories.strings,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/CelloEnsSusVib.sfz',
    description: 'Section cellos with vibrato',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_bass_ens_vib',
    name: 'Double Bass Ensemble',
    category: SampleCategories.strings,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/ContrabassSusVB.sfz',
    description: 'Section double basses with vibrato',
    isBundled: true,
  ),

  // Brass
  SamplePreset(
    id: 'vsco_trumpet_sus',
    name: 'Trumpet Sustain',
    category: SampleCategories.brass,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/TrumpetSus.sfz',
    description: 'Bright orchestral trumpet',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_trumpet_stac',
    name: 'Trumpet Staccato',
    category: SampleCategories.brass,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/TrumpetStac.sfz',
    description: 'Short detached trumpet notes',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_trombone_sus',
    name: 'Trombone Sustain',
    category: SampleCategories.brass,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/TromboneSus.sfz',
    description: 'Warm tenor trombone',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_horn_sus',
    name: 'French Horn Sustain',
    category: SampleCategories.brass,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/FHornSus.sfz',
    description: 'Mellow French horn',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_tuba_sus',
    name: 'Tuba Sustain',
    category: SampleCategories.brass,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/TubaSus.sfz',
    description: 'Deep resonant tuba',
    isBundled: true,
  ),

  // Woodwinds
  SamplePreset(
    id: 'vsco_flute_sus',
    name: 'Flute Sustain',
    category: SampleCategories.woodwind,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/FluteSusVib.sfz',
    description: 'Concert flute with vibrato',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_flute_stac',
    name: 'Flute Staccato',
    category: SampleCategories.woodwind,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/FluteStac.sfz',
    description: 'Short articulate flute',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_clarinet_sus',
    name: 'Clarinet Sustain',
    category: SampleCategories.woodwind,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/ClarinetSus.sfz',
    description: 'Warm Bb clarinet',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_oboe_sus',
    name: 'Oboe Sustain',
    category: SampleCategories.woodwind,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/OboeSusVib.sfz',
    description: 'Expressive oboe with vibrato',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_bassoon_sus',
    name: 'Bassoon Sustain',
    category: SampleCategories.woodwind,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/BassoonSus.sfz',
    description: 'Rich bassoon tone',
    isBundled: true,
  ),

  // Percussion
  SamplePreset(
    id: 'vsco_timpani',
    name: 'Timpani',
    category: SampleCategories.percussion,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/Timpani.sfz',
    description: 'Orchestral kettle drums',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_glockenspiel',
    name: 'Glockenspiel',
    category: SampleCategories.percussion,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/Glockenspiel.sfz',
    description: 'Bright metallic bells',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_marimba',
    name: 'Marimba',
    category: SampleCategories.percussion,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/Marimba.sfz',
    description: 'Warm wooden marimba',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_xylophone',
    name: 'Xylophone',
    category: SampleCategories.percussion,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/Xylophone.sfz',
    description: 'Bright percussive xylophone',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_tubular_bells',
    name: 'Tubular Bells',
    category: SampleCategories.percussion,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/TubularBells.sfz',
    description: 'Church bell chimes',
    isBundled: true,
  ),
  SamplePreset(
    id: 'vsco_harp',
    name: 'Harp',
    category: SampleCategories.percussion,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/Harp.sfz',
    description: 'Concert harp with pedal resonance',
    isBundled: true,
  ),

  // Full GM-style percussion kit
  SamplePreset(
    id: 'vsco_gm_perc',
    name: 'GM Percussion Kit',
    category: SampleCategories.percussion,
    sfzPath: 'assets/samples/VSCO-2-CE-1.1.0/GM-StylePerc.sfz',
    description: 'General MIDI compatible percussion',
    isBundled: true,
  ),

  // Salamander Grand Piano (CC0) — downloaded separately
  SamplePreset(
    id: 'salamander_grand',
    name: 'Salamander Grand Piano',
    category: SampleCategories.piano,
    sfzPath: 'assets/samples/SalamanderGrandPianoV3_48khz24bit/SalamanderGrandPianoV3.sfz',
    description: 'High-quality sampled Yamaha C5 grand piano (48kHz/24bit)',
    isBundled: true,
  ),
];
