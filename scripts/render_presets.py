#!/usr/bin/env python3
"""Render each SF2 preset to a short WAV using fluidsynth."""

import os
import struct
import subprocess
import sys
import tempfile

import mido
from mido import Message, MidiFile, MidiTrack

sf2_path = sys.argv[1] if len(sys.argv) > 1 else '/tmp/sf2extract/usr/share/sounds/sf2/FluidR3_GM.sf2'
output_base = sys.argv[2] if len(sys.argv) > 2 else '/home/synth/projects/open-synth/samples'


def read_sf2(sf2_path):
    with open(sf2_path, 'rb') as f:
        data = f.read()
    pos = 0
    riff, file_size, sfbk = struct.unpack_from('<4sI4s', data, pos)
    pos += 12
    sdta_chunk = None
    pdta_chunk = None
    while pos < 8 + file_size:
        tag = data[pos:pos+4]
        chunk_size = struct.unpack_from('<I', data, pos+4)[0]
        chunk_data = data[pos+8:pos+8+chunk_size]
        if tag == b'LIST':
            list_type = chunk_data[:4]
            if list_type == b'sdta':
                sdta_chunk = chunk_data[4:]
            elif list_type == b'pdta':
                pdta_chunk = chunk_data[4:]
        pos += 8 + chunk_size
        if chunk_size % 2 == 1:
            pos += 1
    return sdta_chunk, pdta_chunk


def parse_pdta(pdta_chunk):
    pos = 0
    records = {}
    while pos < len(pdta_chunk):
        tag = pdta_chunk[pos:pos+4]
        size = struct.unpack_from('<I', pdta_chunk, pos+4)[0]
        records[tag] = pdta_chunk[pos+8:pos+8+size]
        pos += 8 + size
        if size % 2 == 1:
            pos += 1
    return records


def get_presets(sf2_path):
    _, pdta_chunk = read_sf2(sf2_path)
    pdta = parse_pdta(pdta_chunk)
    phdr = pdta[b'phdr']
    presets = []
    count = len(phdr) // 38
    for i in range(count):
        off = i * 38
        name = phdr[off:off+20].decode('ascii', errors='ignore').rstrip('\x00')
        preset_num, bank = struct.unpack_from('<HH', phdr, off+20)
        presets.append({'name': name, 'preset': preset_num, 'bank': bank})
    return presets


category_keywords = {
    'piano': ['piano', 'grand', 'electric grand', 'honky', 'rhodes', 'clavinet', 'harpsichord', 'celesta', 'music box', 'eop', 'ep ', 'legend ep', 'detuned ep'],
    'organ': ['organ', 'accordion', 'accordian', 'harmonica', 'bandoneon', 'reed', 'church bell'],
    'guitar': ['guitar', 'nylon', 'steel', 'jazz', 'clean', 'muted', 'overdrive', 'distortion', 'harmonics', 'palm', 'ukulele', 'mandolin', 'banjo', 'shamisen', 'koto', 'sitar'],
    'bass': ['bass', 'slap', 'pop', 'picked', 'fingered', 'fretless'],
    'strings': ['violin', 'viola', 'cello', 'contrabass', 'tremolo', 'pizzicato', 'harp', 'strings', 'orchestral pad', 'slow violin'],
    'brass': ['trumpet', 'trombone', 'tuba', 'french horn', 'brass', 'sax'],
    'woodwind': ['flute', 'piccolo', 'recorder', 'pan flute', 'bottle', 'shakuhachi', 'whistle', 'ocarina', 'oboe', 'english horn', 'bassoon', 'clarinet'],
    'ethnic': ['sitar', 'banjo', 'shamisen', 'koto', 'kalimba', 'bagpipe', 'fiddle', 'shanai', 'shenai', 'taisho', 'tinker bell'],
    'percussion': ['tinkle', 'agogo', 'steel drums', 'woodblock', 'taiko', 'tom', 'synth drum', 'cymbal', 'drum', 'timpani', 'glockenspiel', 'marimba', 'xylophone', 'vibraphone', 'tubular', 'dulcimer', 'castanets'],
    'chromatic': ['marimba', 'xylophone', 'vibraphone', 'glockenspiel', 'tubular bells', 'dulcimer', 'timpani', 'music box'],
    'orchestral': ['choir', 'voice', 'aah', 'ooh', 'orchestra hit', 'orchestra', 'fantasia', 'atmosphere', 'brightness', 'goblin', 'echo drops', 'star theme', 'soundtrack', 'ice rain', 'sweep pad', 'halo pad', 'warm pad', 'metal pad', 'space voice', 'bowed glass', 'polysynth', 'crystal', 'solo vox'],
    'synth_lead': ['lead', 'saw', 'square', 'calliope', 'chiffer', 'charang', 'fifth', 'bass & lead'],
    'synth_pad': ['pad', 'fantasia', 'warm', 'polysynth', 'space', 'bowed', 'metal', 'halo', 'sweep', 'ice rain', 'soundtrack', 'crystal', 'atmosphere', 'brightness', 'goblin', 'echo drops', 'star theme'],
    'fx': ['gun shot', 'helicopter', 'applause', 'sea shore', 'bird tweet', 'telephone', 'breath noise', 'fret noise', 'burst noise', 'sine wave'],
    'drums': ['standard', 'room', 'power', 'electronic', 'tr-808', 'tr-808', 'brush', 'jazz', 'drumset', 'kit'],
}


def detect_category(name):
    name_lower = name.lower()
    for cat, keywords in category_keywords.items():
        for kw in keywords:
            if kw in name_lower:
                return cat
    return 'other'


def sanitize(name):
    return name.replace(' ', '_').replace('/', '-').replace('\\', '-')


# Create directories
for cat in category_keywords:
    os.makedirs(os.path.join(output_base, cat), exist_ok=True)

presets = get_presets(sf2_path)
print(f"Found {len(presets)} presets")

extracted = 0
failed = 0

for p in presets:
    cat = detect_category(p['name'])
    safe_name = sanitize(p['name'])
    out_path = os.path.join(output_base, cat, f"{safe_name}.wav")

    if os.path.exists(out_path):
        extracted += 1
        continue

    # Create MIDI with bank select + program change + note
    mid = MidiFile()
    track = MidiTrack()
    mid.tracks.append(track)

    # Bank select MSB (CC 0) + LSB (CC 32) then program change
    if p['bank'] > 0:
        track.append(Message('control_change', control=0, value=p['bank'] >> 7, channel=0, time=0))
        track.append(Message('control_change', control=32, value=p['bank'] & 0x7F, channel=0, time=0))
    track.append(Message('program_change', program=p['preset'], channel=0, time=0))
    track.append(Message('note_on', note=60, velocity=100, channel=0, time=0))
    track.append(Message('note_off', note=60, velocity=100, channel=0, time=960))

    with tempfile.NamedTemporaryFile(suffix='.mid', delete=False) as tmp:
        mid.save(tmp.name)
        tmp_path = tmp.name

    cmd = [
        'fluidsynth', '-a', 'file',
        '-o', f'audio.file.name={out_path}',
        '-o', 'audio.file.type=wav',
        '-ni', sf2_path, tmp_path
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, timeout=10)
        if os.path.exists(out_path) and os.path.getsize(out_path) > 1024:
            extracted += 1
            if extracted % 20 == 0:
                print(f"  Rendered {extracted}...")
        else:
            failed += 1
            print(f"  Failed {p['name']}: no output")
    except Exception as e:
        failed += 1
        print(f"  Failed {p['name']}: {e}")
    finally:
        os.unlink(tmp_path)

print(f"\nDone: {extracted} rendered, {failed} failed")
