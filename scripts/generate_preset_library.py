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
    'other':       {'sampleMix': 0.0, 'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'attackCurve': 0, 'brightness': 0.0},
}

# Preset names from FluidR3 GM, organized by category
PRESETS = [
    # Piano
    ("Grand Piano", "piano"),
    ("Bright Piano", "piano"),
    ("Electric Grand", "piano"),
    ("Honky Tonk", "piano"),
    ("Electric Piano", "piano"),
    ("Legend EP 2", "piano"),
    ("Harpsichord", "piano"),
    ("Coupled Harpsichord", "piano"),
    ("Clavinet", "piano"),
    ("Detuned EP 1", "piano"),
    ("Detuned EP 2", "piano"),
    # Organ
    ("DrawbarOrgan", "organ"),
    ("Percussive Organ", "organ"),
    ("Rock Organ", "organ"),
    ("Church Organ", "organ"),
    ("Church Organ 2", "organ"),
    ("Reed Organ", "organ"),
    ("Accordian", "organ"),
    ("Italian Accordion", "organ"),
    ("Harmonica", "organ"),
    ("Bandoneon", "organ"),
    ("Detuned Organ 1", "organ"),
    ("Detuned Organ 2", "organ"),
    # Guitar
    ("Nylon String Guitar", "guitar"),
    ("Steel String Guitar", "guitar"),
    ("Jazz Guitar", "guitar"),
    ("Clean Guitar", "guitar"),
    ("Palm Muted Guitar", "guitar"),
    ("Overdrive Guitar", "guitar"),
    ("Distortion Guitar", "guitar"),
    ("Guitar Harmonics", "guitar"),
    ("12 String Guitar", "guitar"),
    ("Hawaiian Guitar", "guitar"),
    ("Ukulele", "guitar"),
    ("Mandolin", "guitar"),
    ("Feedback Guitar", "guitar"),
    ("Guitar Feedback", "guitar"),
    ("Funk Guitar", "guitar"),
    # Bass
    ("Acoustic Bass", "bass"),
    ("Fingered Bass", "bass"),
    ("Picked Bass", "bass"),
    ("Fretless Bass", "bass"),
    ("Slap Bass", "bass"),
    ("Pop Bass", "bass"),
    ("Synth Bass 1", "bass"),
    ("Synth Bass 2", "bass"),
    ("Synth Bass 3", "bass"),
    ("Synth Bass 4", "bass"),
    # Strings
    ("Violin", "strings"),
    ("Viola", "strings"),
    ("Cello", "strings"),
    ("Contrabass", "strings"),
    ("Tremolo", "strings"),
    ("Pizzicato Section", "strings"),
    ("Harp", "strings"),
    ("Strings", "strings"),
    ("Slow Strings", "strings"),
    ("Slow Violin", "strings"),
    ("Orchestral Pad", "strings"),
    ("Synth Strings 3", "strings"),
    # Brass
    ("Trumpet", "brass"),
    ("Trombone", "brass"),
    ("Tuba", "brass"),
    ("Muted Trumpet", "brass"),
    ("French Horns", "brass"),
    ("Brass Section", "brass"),
    ("Brass 2", "brass"),
    ("Synth Brass 1", "brass"),
    ("Synth Brass 2", "brass"),
    ("Synth Brass 3", "brass"),
    ("Synth Brass 4", "brass"),
    ("Soprano Sax", "brass"),
    ("Alto Sax", "brass"),
    ("Tenor Sax", "brass"),
    ("Baritone Sax", "brass"),
    # Woodwind
    ("Oboe", "woodwind"),
    ("English Horn", "woodwind"),
    ("Bassoon", "woodwind"),
    ("Clarinet", "woodwind"),
    ("Piccolo", "woodwind"),
    ("Flute", "woodwind"),
    ("Recorder", "woodwind"),
    ("Pan Flute", "woodwind"),
    ("Bottle Chiff", "woodwind"),
    ("Shakuhachi", "woodwind"),
    ("Whistle", "woodwind"),
    ("Ocarina", "woodwind"),
    # Ethnic
    ("Sitar", "ethnic"),
    ("Banjo", "ethnic"),
    ("Shamisen", "ethnic"),
    ("Koto", "ethnic"),
    ("Kalimba", "ethnic"),
    ("BagPipe", "ethnic"),
    ("Fiddle", "ethnic"),
    ("Shenai", "ethnic"),
    ("Taisho Koto", "ethnic"),
    ("Tinker Bell", "ethnic"),
    # Percussion / Chromatic
    ("Glockenspiel", "percussion"),
    ("Music Box", "percussion"),
    ("Vibraphone", "percussion"),
    ("Marimba", "percussion"),
    ("Xylophone", "percussion"),
    ("Tubular Bells", "percussion"),
    ("Dulcimer", "percussion"),
    ("Timpani", "percussion"),
    ("Agogo", "percussion"),
    ("Steel Drums", "percussion"),
    ("Woodblock", "percussion"),
    ("Taiko Drum", "percussion"),
    ("Melodic Tom", "percussion"),
    ("Synth Drum", "percussion"),
    ("808 Tom", "percussion"),
    ("Melo Tom 2", "percussion"),
    ("Castanets", "percussion"),
    ("Reverse Cymbal", "percussion"),
    # Orchestral / Choir
    ("Ahh Choir", "orchestral"),
    ("Ohh Voices", "orchestral"),
    ("Synth Voice", "orchestral"),
    ("Solo Vox", "orchestral"),
    ("Orchestra Hit", "orchestral"),
    ("Polysynth", "orchestral"),
    ("Metal Pad", "orchestral"),
    # Synth Lead
    ("Square Lead", "synth_lead"),
    ("Saw Wave", "synth_lead"),
    ("Calliope Lead", "synth_lead"),
    ("Chiffer Lead", "synth_lead"),
    ("Charang", "synth_lead"),
    ("Fifth Sawtooth Wave", "synth_lead"),
    ("Bass & Lead", "synth_lead"),
    # Synth Pad
    ("Warm Pad", "synth_pad"),
    ("Fantasia", "synth_pad"),
    ("Space Voice", "synth_pad"),
    ("Bowed Glass", "synth_pad"),
    ("Halo Pad", "synth_pad"),
    ("Sweep Pad", "synth_pad"),
    ("Ice Rain", "synth_pad"),
    ("Soundtrack", "synth_pad"),
    ("Crystal", "synth_pad"),
    ("Atmosphere", "synth_pad"),
    ("Brightness", "synth_pad"),
    ("Goblin", "synth_pad"),
    ("Echo Drops", "synth_pad"),
    ("Star Theme", "synth_pad"),
    # FX
    ("Gun Shot", "fx"),
    ("Helicopter", "fx"),
    ("Applause", "fx"),
    ("Sea Shore", "fx"),
    ("Bird Tweet", "fx"),
    ("Telephone", "fx"),
    ("Breath Noise", "fx"),
    ("Fret Noise", "fx"),
    ("Burst Noise", "fx"),
    ("Sine Wave", "fx"),
    # Drums
    ("Standard", "drums"),
    ("Room", "drums"),
    ("Power 1", "drums"),
    ("Power 2", "drums"),
    ("Power 3", "drums"),
    ("Electronic", "drums"),
    ("TR-808", "drums"),
    ("Brush 1", "drums"),
    ("Brush 2", "drums"),
    ("Jazz 1", "drums"),
    ("Jazz 2", "drums"),
    ("Jazz 3", "drums"),
    ("Jazz 4", "drums"),
    ("Orchestra Kit", "drums"),
    ("Concert Bass Drum", "drums"),
]


def generate_preset(idx, name, category):
    cat = CATEGORIES.get(category, CATEGORIES['other'])
    
    # Default synth parameters
    osc1_wave = 6 if category in ('piano', 'organ') else 2  # sub for piano/organ, saw for others
    if category == 'drums':
        osc1_wave = 5  # noise
    
    filter_cutoff = 12000.0 if category in ('piano', 'organ', 'guitar') else 8000.0
    filter_res = 0.1 if category == 'strings' else 0.3
    
    amp_attack = 5.0 if category in ('strings', 'pad', 'orchestral') else 3.0
    amp_decay = 200.0
    amp_sus = 0.7
    amp_release = 400.0 if category in ('strings', 'pad', 'orchestral') else 300.0
    
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
    reverb = 'true' if category in ('piano', 'organ', 'strings', 'orchestral', 'pad') else 'false'
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
    lines.append(f'        {cat["sampleMix"]:.2f},')
    # isBassPreset
    is_bass = 'true' if category == 'bass' else 'false'
    lines.append(f'        {is_bass},')
    # Realism
    lines.append(f'        {cat["bodyType"]}, {cat["bodyMix"]:.2f}, {cat["clickMix"]:.2f}, {cat["sympathetic"]:.2f}, {cat["attackCurve"]}, {cat["brightness"]:.2f},')
    # Arpeggiator
    lines.append(f'        false, 0, 120.0, 0.50, 0.00, 1')
    lines.append(f'    }}')
    
    return '\n'.join(lines)


# Wait, I need to fix sympathetic key
for cat_name, cat_data in CATEGORIES.items():
    cat_data['sympathetic'] = 0.0  # default

# Piano and strings get sympathetic
CATEGORIES['piano']['sympathetic'] = 0.3
CATEGORIES['strings']['sympathetic'] = 0.4
CATEGORIES['guitar']['sympathetic'] = 0.25

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

for i, (name, cat) in enumerate(PRESETS):
    parts.append(generate_preset(i + 1, name, cat))
    if i < len(PRESETS) - 1:
        parts[-1] += ','

parts.append('};')
parts.append('')
parts.append('} // namespace opensynth')

with open(OUTPUT, 'w') as f:
    f.write('\n'.join(parts))

print(f"Generated {len(PRESETS)} presets to {OUTPUT}")
