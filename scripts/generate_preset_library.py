#!/usr/bin/env python3
"""Generate preset_library_full.h with complete PresetData initializers."""

import os

OUTPUT = '/home/synth/projects/open-synth/include/preset_library_full.h'

# Category definitions with sampleMix values
# Acoustic categories get 0.5-0.7 sampleMix, synth categories get 0.0
CATEGORIES = {
    'piano':       {'sampleMix': 0.6, 'bodyType': 1, 'bodyMix': 0.3, 'clickMix': 0.2, 'attackCurve': 1, 'brightness': 0.4},
    'organ':       {'sampleMix': 0.5, 'bodyType': 4, 'bodyMix': 0.4, 'clickMix': 0.3, 'attackCurve': 2, 'brightness': 0.2},
    'guitar':      {'sampleMix': 0.6, 'bodyType': 2, 'bodyMix': 0.35, 'clickMix': 0.15, 'attackCurve': 3, 'brightness': 0.3},
    'bass':        {'sampleMix': 0.5, 'bodyType': 5, 'bodyMix': 0.3, 'clickMix': 0.1, 'attackCurve': 3, 'brightness': 0.2},
    'strings':     {'sampleMix': 0.7, 'bodyType': 3, 'bodyMix': 0.4, 'clickMix': 0.0, 'attackCurve': 1, 'brightness': 0.3},
    'brass':       {'sampleMix': 0.6, 'bodyType': 6, 'bodyMix': 0.35, 'clickMix': 0.1, 'attackCurve': 1, 'brightness': 0.5},
    'woodwind':    {'sampleMix': 0.7, 'bodyType': 7, 'bodyMix': 0.3, 'clickMix': 0.15, 'attackCurve': 1, 'brightness': 0.4},
    'ethnic':      {'sampleMix': 0.6, 'bodyType': 0, 'bodyMix': 0.2, 'clickMix': 0.1, 'attackCurve': 3, 'brightness': 0.2},
    'percussion':  {'sampleMix': 0.7, 'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'attackCurve': 0, 'brightness': 0.1},
    'chromatic':   {'sampleMix': 0.7, 'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'attackCurve': 0, 'brightness': 0.2},
    'orchestral':  {'sampleMix': 0.6, 'bodyType': 3, 'bodyMix': 0.3, 'clickMix': 0.0, 'attackCurve': 1, 'brightness': 0.3},
    'synth_lead':  {'sampleMix': 0.0, 'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'attackCurve': 0, 'brightness': 0.0},
    'synth_pad':   {'sampleMix': 0.0, 'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'attackCurve': 0, 'brightness': 0.0},
    'fx':          {'sampleMix': 0.0, 'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'attackCurve': 0, 'brightness': 0.0},
    'drums':       {'sampleMix': 0.8, 'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'attackCurve': 0, 'brightness': 0.0},
    'synth_bass':  {'sampleMix': 0.0, 'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'attackCurve': 0, 'brightness': 0.0},
    'synth_organ': {'sampleMix': 0.0, 'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'attackCurve': 0, 'brightness': 0.0},
    'synth_piano': {'sampleMix': 0.0, 'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'attackCurve': 0, 'brightness': 0.0},
    'world':       {'sampleMix': 0.6, 'bodyType': 0, 'bodyMix': 0.2, 'clickMix': 0.1, 'attackCurve': 3, 'brightness': 0.2},
    'sfx':         {'sampleMix': 0.0, 'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'attackCurve': 0, 'brightness': 0.0},
    'cinematic':   {'sampleMix': 0.5, 'bodyType': 3, 'bodyMix': 0.3, 'clickMix': 0.0, 'attackCurve': 1, 'brightness': 0.3},
    'other':       {'sampleMix': 0.0, 'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'attackCurve': 0, 'brightness': 0.0},
}

# Set of available sample files (without .wav extension)
SAMPLE_FILES = {
    "12_String_Guitar",
    "808_Tom",
    "Accordian",
    "Agogo",
    "Alto_Sax",
    "BagPipe",
    "Baritone_Sax",
    "Bassoon",
    "Bird_Tweet",
    "Brass_2",
    "Brass_Section",
    "Brush_1",
    "Brush_2",
    "Burst_Noise",
    "Castanets",
    "Cello",
    "Church_Bell",
    "Church_Organ_2",
    "Concert_Bass_Drum",
    "Coupled_Harpsichord",
    "Detuned_EP_1",
    "Detuned_EP_2",
    "Detuned_Organ_1",
    "Detuned_Organ_2",
    "Distortion_Guitar",
    "Feedback_Guitar",
    "Flute",
    "Fret_Noise",
    "Funk_Guitar",
    "Guitar_Feedback",
    "Gun_Shot",
    "Harmonica",
    "Harpsichord",
    "Hawaiian_Guitar",
    "Helicopter",
    "Italian_Accordion",
    "Jazz_1",
    "Jazz_2",
    "Jazz_3",
    "Jazz_4",
    "Koto",
    "Legend_EP_2",
    "Mandolin",
    "Melo_Tom_2",
    "Melodic_Tom",
    "Metal_Pad",
    "Orchestral_Pad",
    "Overdrive_Guitar",
    "Pan_Flute",
    "Piccolo",
    "Pizzicato_Section",
    "Polysynth",
    "Pop_Bass",
    "Power_1",
    "Power_2",
    "Power_3",
    "Reed_Organ",
    "Shakuhachi",
    "Shamisen",
    "Shenai",
    "Sine_Wave",
    "Sitar",
    "Slap_Bass",
    "Slow_Strings",
    "Slow_Violin",
    "Soprano_Sax",
    "Strings",
    "Synth_Bass_1",
    "Synth_Bass_3",
    "Synth_Bass_4",
    "Synth_Brass_1",
    "Synth_Brass_2",
    "Synth_Brass_3",
    "Synth_Brass_4",
    "Synth_Strings_3",
    "Taisho_Koto",
    "Telephone",
    "Tenor_Sax",
    "Tinker_Bell",
    "Tremolo",
    "Ukulele",
    "Viola",
    "Violin",
}

# Base presets organized by category (GM2 + extras)
BASE_PRESETS = {
    'piano': [
        "Grand Piano", "Bright Piano", "Electric Grand", "Honky Tonk",
        "Electric Piano 1", "Electric Piano 2", "Harpsichord", "Clavinet",
        "Celesta", "Detuned EP 1", "Detuned EP 2", "Coupled Harpsichord",
        "Legend EP 1", "Legend EP 2", "Stage EP", "Wurly", "FM Piano",
        "Dulcimer", "Hammered Dulcimer", "Music Box"
    ],
    'organ': [
        "Drawbar Organ", "Percussive Organ", "Rock Organ", "Church Organ",
        "Reed Organ", "Accordion", "Harmonica", "Bandoneon",
        "Church Organ 2", "Detuned Organ 1", "Detuned Organ 2",
        "Italian Accordion", "Tango Accordion", "Jazz Organ", "Theater Organ"
    ],
    'guitar': [
        "Nylon String Guitar", "Steel String Guitar", "Jazz Guitar",
        "Clean Guitar", "Palm Muted Guitar", "Overdrive Guitar",
        "Distortion Guitar", "Guitar Harmonics", "12 String Guitar",
        "Hawaiian Guitar", "Ukulele", "Mandolin", "Feedback Guitar",
        "Guitar Feedback", "Funk Guitar", "Chorus Guitar", "Acoustic Bass Guitar"
    ],
    'bass': [
        "Acoustic Bass", "Fingered Bass", "Picked Bass", "Fretless Bass",
        "Slap Bass 1", "Slap Bass 2", "Pop Bass", "Synth Bass 1",
        "Synth Bass 2", "Synth Bass 3", "Synth Bass 4", "Synth Bass 5",
        "Resonant Bass", "Upright Bass", "Electric Bass", "Muted Bass"
    ],
    'strings': [
        "Violin", "Viola", "Cello", "Contrabass", "Tremolo Strings",
        "Pizzicato Strings", "Harp", "Orchestral Strings", "Slow Strings",
        "Slow Violin", "Orchestral Pad", "Synth Strings 1", "Synth Strings 2",
        "Synth Strings 3", "Choir Aahs", "Choir Oohs", "Synth Voice",
        "Orchestra Hit", "String Ensemble", "Legato Strings"
    ],
    'brass': [
        "Trumpet", "Trombone", "Tuba", "Muted Trumpet", "French Horn",
        "Brass Section", "Synth Brass 1", "Synth Brass 2", "Synth Brass 3",
        "Synth Brass 4", "Soprano Sax", "Alto Sax", "Tenor Sax", "Baritone Sax",
        "Oboe", "English Horn", "Bassoon", "Clarinet", "Piccolo", "Flute",
        "Recorder", "Pan Flute", "Shakuhachi", "Whistle", "Ocarina", "Bottle Blow"
    ],
    'woodwind': [
        "Oboe", "English Horn", "Bassoon", "Clarinet", "Piccolo", "Flute",
        "Recorder", "Pan Flute", "Bottle Chiff", "Shakuhachi", "Whistle",
        "Ocarina", "Irish Flute", "Native American Flute", "Bass Clarinet",
        "Contra Bassoon", "Alto Flute", " penny Whistle", "Fife", "Dizi"
    ],
    'ethnic': [
        "Sitar", "Banjo", "Shamisen", "Koto", "Kalimba", "Bagpipe",
        "Fiddle", "Shenai", "Taisho Koto", "Tinker Bell", "Dulcimer",
        "Steel Drums", "Celtic Harp", "Santoor", "Oud", "Bouzouki",
        "Charango", "Balalaika", "Sarangi", "Tabla"
    ],
    'percussion': [
        "Glockenspiel", "Music Box", "Vibraphone", "Marimba", "Xylophone",
        "Tubular Bells", "Dulcimer", "Timpani", "Agogo", "Steel Drums",
        "Woodblock", "Taiko Drum", "Melodic Tom", "Synth Drum", "808 Tom",
        "Melo Tom 2", "Castanets", "Reverse Cymbal", "Triangle", "Tambourine",
        "Cymbal Crash", "Gong", "Claves", "Conga", "Bongo", "Timbales"
    ],
    'chromatic': [
        "Celesta", "Glockenspiel", "Music Box", "Vibraphone", "Marimba",
        "Xylophone", "Tubular Bells", "Dulcimer", "Timpani", "Steel Drums",
        "Kalimba", "Hand Bells", "Glass Marimba", "Balafon", "Crotales"
    ],
    'orchestral': [
        "Ahh Choir", "Ohh Voices", "Synth Voice", "Solo Vox", "Orchestra Hit",
        "Polysynth", "Metal Pad", "Classic Pad", "String Pad", "Brass Pad",
        "Woodwind Pad", "Choir Pad", "Heaven Pad", "Ethereal Pad", "Mystery Pad"
    ],
    'synth_lead': [
        "Square Lead", "Saw Wave", "Calliope Lead", "Chiffer Lead", "Charang",
        "Fifth Sawtooth", "Bass & Lead", "Solo Synth", "PWM Lead", "Sync Lead",
        "Pluck Lead", "FM Lead", "Wavetable Lead", "Super Saw", "Hyper Saw",
        "Acid Lead", "Trance Lead", "Progressive Lead", "Electro Lead", "Future Lead",
        "Retro Lead", "Chip Lead", "Vocal Lead", "Brass Lead", "Flute Lead",
        "Bell Lead", "Plucked Lead", "Stab Lead", "Rave Lead", "Detuned Lead"
    ],
    'synth_pad': [
        "Warm Pad", "Fantasia", "Space Voice", "Bowed Glass", "Halo Pad",
        "Sweep Pad", "Ice Rain", "Soundtrack", "Crystal", "Atmosphere",
        "Brightness", "Goblin", "Echo Drops", "Star Theme", "Aurora Pad",
        "Cosmic Pad", "Dream Pad", "Analog Pad", "Digital Pad", "String Pad",
        "Vox Pad", "Bass Pad", "Lead Pad", "Motion Pad", "Drone Pad",
        "Ambient Pad", "Heaven Pad", "Dark Pad", "Light Pad", "Evolving Pad"
    ],
    'fx': [
        "Gun Shot", "Helicopter", "Applause", "Sea Shore", "Bird Tweet",
        "Telephone", "Breath Noise", "Fret Noise", "Burst Noise", "Sine Wave",
        "Laser", "Explosion", "Wind", "Rain", "Thunder", "Footsteps",
        "Door Creak", "Car Engine", "Train", "Clock Tick", "Heart Beat",
        "Computer", "Sci-Fi", "Magic", "Ghost", "Robot"
    ],
    'drums': [
        "Standard Kit", "Room Kit", "Power Kit 1", "Power Kit 2", "Power Kit 3",
        "Electronic Kit", "TR-808 Kit", "Brush Kit 1", "Brush Kit 2",
        "Jazz Kit 1", "Jazz Kit 2", "Jazz Kit 3", "Jazz Kit 4",
        "Orchestra Kit", "Concert Bass Drum", "Latin Kit", "Dance Kit",
        "Hip Hop Kit", "Rock Kit", "Metal Kit", "Funk Kit", "Soul Kit",
        "Vintage Kit", "Modern Kit", "Minimal Kit", "Percussion Kit"
    ],
    'synth_bass': [
        "Analog Bass", "Digital Bass", "FM Bass", "Wavetable Bass", "Sub Bass",
        "Reese Bass", "Acid Bass", "Punchy Bass", "Round Bass", "Growl Bass",
        "Talking Bass", "Pluck Bass", "Sine Bass", "Saw Bass", "Square Bass",
        "Pulse Bass", "Noise Bass", "Formant Bass", "Distorted Bass", "Fuzz Bass",
        "Super Bass", "Deep Bass", "Reso Bass", "Tech Bass", "Electro Bass",
        "Future Bass", "Trap Bass", "Dub Bass", "Wobble Bass", "Vibrato Bass"
    ],
    'synth_organ': [
        "Digital Organ", "FM Organ", "Wavetable Organ", "Phase Organ",
        "Pulse Organ", "Saw Organ", "Square Organ", "Drawbar Synth",
        "Percussive Synth Organ", "Rotary Synth", "Church Synth Organ",
        "Theater Synth Organ", "Jazz Synth Organ", "Rock Synth Organ",
        "Funk Organ", "Gospel Organ", "Cathedral Organ", "Pipe Organ",
        "Reed Synth Organ", "Accordion Synth"
    ],
    'synth_piano': [
        "Digital Piano", "FM Piano", "Wavetable Piano", "Phase Piano",
        "Pulse Piano", "Saw Piano", "Square Piano", "Bell Piano",
        "Pluck Piano", "Glass Piano", "Crystal Piano", "Ethereal Piano",
        "Dream Piano", "Ambient Piano", "Chime Piano", "Marimba Piano",
        "Vibraphone Piano", "Harpsichord Synth", "Clavinet Synth",
        "Electric Piano Synth"
    ],
    'world': [
        "Celtic Harp", "Sitar", "Koto", "Shamisen", "Balalaika", "Oud",
        "Bouzouki", "Charango", "Sarangi", "Tabla", "Djembe", "Talking Drum",
        "Didgeridoo", "Pan Pipes", "Native Flute", "Shakuhachi", "Erhu",
        "Pipa", "Guzheng", "Santoor", "Dulcimer World", "Bagpipe World",
        "Fiddle World", "Steel Drum World", "Kalimba World", "Bongo World"
    ],
    'sfx': [
        "Rise", "Downer", "Impact", "Whoosh", "Stinger", "Hit",
        "Sweep", "Swirl", "Zap", "Buzz", "Crackle", "Pop",
        "Glitch", "Stutter", "Reverse", "Morph", "Transform",
        "Warp", "Portal", "Beam", "Shield", "Power Up", "Power Down",
        "Alarm", "Siren", "Bell Toll", "Chime", "Gong Hit"
    ],
    'cinematic': [
        "Epic Brass", "Epic Strings", "Epic Choir", "Trailer Hit",
        "Cinematic Drums", "Cinematic Percussion", "Cinematic Pad",
        "Cinematic Lead", "Cinematic Bass", "Cinematic FX",
        "Suspense", "Tension", "Horror", "Drama", "Action",
        "Adventure", "Fantasy", "Sci-Fi Cinematic", "War", "Peace",
        "Triumph", "Loss", "Discovery", "Mystery", "Romance",
        "Chase", "Battle", "Victory", "Defeat", "Rebirth"
    ],
}

# Variation suffixes and their parameter adjustments
VARIATIONS = [
    ("", {}),  # default
    (" Bright", {"brightness": 0.2, "filter_cutoff": 2000.0}),
    (" Dark", {"brightness": -0.15, "filter_cutoff": -3000.0}),
    (" Soft", {"amp_attack": 5.0, "amp_release": 100.0, "brightness": -0.1}),
    (" Hard", {"amp_attack": 1.0, "amp_release": 50.0, "brightness": 0.1}),
    (" Vintage", {"sampleMix": 0.1, "brightness": -0.1, "filter_cutoff": -2000.0}),
    (" Modern", {"sampleMix": 0.0, "brightness": 0.1, "filter_cutoff": 2000.0}),
]


def generate_preset(idx, name, category, overrides=None):
    overrides = overrides or {}
    cat = CATEGORIES.get(category, CATEGORIES['other'])

    # Default synth parameters
    osc1_wave = 6 if category in ('piano', 'organ', 'synth_piano', 'synth_organ') else 2
    if category == 'drums':
        osc1_wave = 5
    elif category in ('synth_lead', 'synth_pad', 'fx', 'sfx', 'cinematic'):
        osc1_wave = 2
    elif category == 'synth_bass':
        osc1_wave = 3
    elif category in ('world', 'ethnic'):
        osc1_wave = 1

    filter_cutoff = 12000.0 if category in ('piano', 'organ', 'guitar', 'synth_piano', 'synth_organ') else 8000.0
    filter_cutoff += overrides.get('filter_cutoff', 0.0)
    filter_cutoff = max(200.0, min(20000.0, filter_cutoff))

    filter_res = 0.1 if category == 'strings' else 0.3
    if category in ('synth_lead', 'synth_pad'):
        filter_res = 0.4

    amp_attack = 5.0 if category in ('strings', 'synth_pad', 'orchestral', 'cinematic') else 3.0
    amp_attack += overrides.get('amp_attack', 0.0)
    amp_attack = max(0.1, amp_attack)

    amp_decay = 200.0
    amp_sus = 0.7
    amp_release = 400.0 if category in ('strings', 'synth_pad', 'orchestral', 'cinematic') else 300.0
    amp_release += overrides.get('amp_release', 0.0)
    amp_release = max(10.0, amp_release)

    brightness = cat['brightness'] + overrides.get('brightness', 0.0)
    brightness = max(0.0, min(1.0, brightness))

    # Determine if a matching sample exists
    base_name = name
    for suffix in [' Bright', ' Dark', ' Soft', ' Hard', ' Vintage', ' Modern']:
        if base_name.endswith(suffix):
            base_name = base_name[:-len(suffix)]
            break
    safe_name = base_name.replace(' ', '_')
    has_matching_sample = safe_name in SAMPLE_FILES

    if has_matching_sample:
        sample_mix = cat['sampleMix'] + overrides.get('sampleMix', 0.0)
    else:
        sample_mix = 0.0
    sample_mix = max(0.0, min(1.0, sample_mix))

    # Build the initializer
    lines = []
    lines.append(f'    {{')
    lines.append(f'        "juno-{idx:04d}", "{name}", "{category}",')

    # Osc 1
    lines.append(f'        {osc1_wave}, 0, 0.0, 0.50, 0.85, 0, 0, 0.0, false, 0.0, 1, 0.0, 0.0, 0.0,')
    # Osc 2
    lines.append(f'        0, 0, 0.0, 0.50, 0.00, 0, 0, 0.0, false, 0.0, 1, 0.0, 0.0, 0.0,')
    # Osc mix
    lines.append(f'        0.50,')
    # Filter
    lines.append(f'        0, {filter_cutoff:.1f}, {filter_res:.2f}, 0.50, 0.00, 0.00,')
    # Amp env
    lines.append(f'        {amp_attack:.1f}, {amp_decay:.1f}, {amp_sus:.2f}, {amp_release:.1f}, 0.0, 0.0, 0, 0, 0,')
    # Filter env
    lines.append(f'        10.0, 200.0, 0.50, 300.0, 0.0, 0.0, 0, 0, 0,')
    # Pitch env
    lines.append(f'        0.0, 0.0, 0.00, 0.0, 0.00,')
    # LFO 1
    lines.append(f'        0, 4.00, 0.30, 0, 0.0, false, 4,')
    # LFO 2
    lines.append(f'        0, 4.00, 0.00, 0, 0.0, false, 4,')
    # Chorus
    lines.append(f'        false, 1.00, 0.30, 0.50,')
    # Delay
    lines.append(f'        false, 400.0, 0.30, 0.30,')
    # Reverb
    reverb = 'true' if category in ('piano', 'organ', 'strings', 'orchestral', 'synth_pad', 'cinematic', 'world') else 'false'
    lines.append(f'        {reverb}, 0.50, 0.50, 0.25,')
    # Phaser
    lines.append(f'        false, 0.50, 0.50, 0.30, 0.30,')
    # Flanger
    lines.append(f'        false, 0.30, 0.50, 0.30, 0.30,')
    # Compressor
    lines.append(f'        false, -20.0, 4.0, 10.0, 100.0, 0.0,')
    # Drive
    lines.append(f'        false, 0.30, 0,')
    # FX slots
    lines.append(f'        {{0, 0, 0}}, {{false, false, false}}, {{ {{0.0, 0.0, 0.0, 0.0}}, {{0.0, 0.0, 0.0, 0.0}}, {{0.0, 0.0, 0.0, 0.0}} }},')
    # Master volume
    lines.append(f'        0.80,')
    # sampleMix
    lines.append(f'        {sample_mix:.2f},')
    # isBassPreset
    is_bass = 'true' if category in ('bass', 'synth_bass') else 'false'
    lines.append(f'        {is_bass},')
    # Realism
    lines.append(f'        {cat["bodyType"]}, {cat["bodyMix"]:.2f}, {cat["clickMix"]:.2f}, {cat.get("sympathetic", 0.0):.2f}, {cat["attackCurve"]}, {brightness:.2f},')
    # Arpeggiator
    lines.append(f'        false, 0, 120.0, 0.50, 0.00, 1')
    lines.append(f'    }}')

    return '\n'.join(lines)


# Set sympathetic defaults
for cat_name, cat_data in CATEGORIES.items():
    cat_data['sympathetic'] = 0.0

# Piano, strings, guitar get sympathetic
CATEGORIES['piano']['sympathetic'] = 0.3
CATEGORIES['strings']['sympathetic'] = 0.4
CATEGORIES['guitar']['sympathetic'] = 0.25
CATEGORIES['world']['sympathetic'] = 0.15
CATEGORIES['ethnic']['sympathetic'] = 0.15

# Build expanded preset list
PRESETS = []
idx = 1
for category, names in BASE_PRESETS.items():
    for name in names:
        # Add base preset + variations for core categories
        if category in ('piano', 'organ', 'guitar', 'bass', 'strings', 'brass',
                        'woodwind', 'synth_lead', 'synth_pad', 'synth_bass',
                        'synth_organ', 'synth_piano', 'cinematic', 'orchestral'):
            for suffix, overrides in VARIATIONS:
                if suffix == "" or idx < 520:  # limit variations to keep under control
                    PRESETS.append((idx, f"{name}{suffix}", category, overrides))
                    idx += 1
        else:
            PRESETS.append((idx, name, category, {}))
            idx += 1

# Ensure we have at least 500
while len(PRESETS) < 500:
    base_idx = (len(PRESETS) % len(PRESETS)) if PRESETS else 0
    if PRESETS:
        _, base_name, base_cat, _ = PRESETS[base_idx]
        PRESETS.append((idx, f"{base_name} Alt", base_cat, {}))
        idx += 1
    else:
        break

# Generate header
parts = []
parts.append('#pragma once')
parts.append('#include "preset_data.h"')
parts.append('')
parts.append('namespace opensynth {')
parts.append('')
parts.append(f'inline constexpr int kNumFullPresets = {len(PRESETS)};')
parts.append('')
parts.append('inline constexpr PresetData kFullPresets[] = {')

for i, (preset_idx, name, cat, overrides) in enumerate(PRESETS):
    parts.append(generate_preset(preset_idx, name, cat, overrides))
    if i < len(PRESETS) - 1:
        parts[-1] += ','

parts.append('};')
parts.append('')
parts.append('} // namespace opensynth')

with open(OUTPUT, 'w') as f:
    f.write('\n'.join(parts))

print(f"Generated {len(PRESETS)} presets to {OUTPUT}")
