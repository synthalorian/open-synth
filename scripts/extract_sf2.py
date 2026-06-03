#!/usr/bin/env python3
"""Extract individual instrument WAVs from a SoundFont2 file."""

import os
import struct
import wave
import sys


def read_sf2(sf2_path):
    """Parse SF2 file and return sample data + pdta records."""
    with open(sf2_path, 'rb') as f:
        data = f.read()

    pos = 0
    riff, file_size, sfbk = struct.unpack_from('<4sI4s', data, pos)
    pos += 12
    assert riff == b'RIFF' and sfbk == b'sfbk'

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


def parse_pdta_subchunks(pdta_chunk):
    """Parse pdta into subchunk dict."""
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


def main():
    sf2_path = sys.argv[1] if len(sys.argv) > 1 else '/tmp/sf2extract/usr/share/sounds/sf2/FluidR3_GM.sf2'
    output_base = sys.argv[2] if len(sys.argv) > 2 else '/home/synth/projects/open-synth/samples'

    print(f"Reading {sf2_path}...")
    sdta_chunk, pdta_chunk = read_sf2(sf2_path)

    # Get smpl data
    smpl_data = None
    pos = 0
    while pos < len(sdta_chunk):
        tag = sdta_chunk[pos:pos+4]
        size = struct.unpack_from('<I', sdta_chunk, pos+4)[0]
        if tag == b'smpl':
            smpl_data = sdta_chunk[pos+8:pos+8+size]
            break
        pos += 8 + size
        if size % 2 == 1:
            pos += 1

    if smpl_data is None:
        print("No sample data found!")
        return

    print(f"Sample data: {len(smpl_data)} bytes")

    pdta = parse_pdta_subchunks(pdta_chunk)

    # Parse structures
    phdr = pdta[b'phdr']
    pbag = pdta[b'pbag']
    pmod = pdta[b'pmod']
    pgen = pdta[b'pgen']
    inst = pdta[b'inst']
    ibag = pdta[b'ibag']
    imod = pdta[b'imod']
    igen = pdta[b'igen']
    shdr = pdta[b'shdr']

    num_presets = len(phdr) // 38
    num_pbags = len(pbag) // 4
    num_pgens = len(pgen) // 4
    num_insts = len(inst) // 22
    num_ibags = len(ibag) // 4
    num_igens = len(igen) // 4
    num_samples = len(shdr) // 46

    print(f"Presets: {num_presets}, PBags: {num_pbags}, PGens: {num_pgens}")
    print(f"Instruments: {num_insts}, IBags: {num_ibags}, IGens: {num_igens}")
    print(f"Samples: {num_samples}")

    # Parse preset headers
    presets = []
    for i in range(num_presets):
        off = i * 38
        name = phdr[off:off+20].decode('ascii', errors='ignore').rstrip('\x00')
        preset_num, bank = struct.unpack_from('<HH', phdr, off+20)
        bag_index = struct.unpack_from('<H', phdr, off+24)[0]
        presets.append({'name': name, 'preset': preset_num, 'bank': bank, 'bag_index': bag_index})

    # Parse bags (gen_index is start, next bag's gen_index is end)
    pbags = []
    for i in range(num_pbags):
        off = i * 4
        gen_idx, mod_idx = struct.unpack_from('<HH', pbag, off)
        pbags.append({'gen_index': gen_idx, 'mod_index': mod_idx})

    ibags = []
    for i in range(num_ibags):
        off = i * 4
        gen_idx, mod_idx = struct.unpack_from('<HH', ibag, off)
        ibags.append({'gen_index': gen_idx, 'mod_index': mod_idx})

    # Parse generators
    pgens = []
    for i in range(num_pgens):
        off = i * 4
        op, amount = struct.unpack_from('<Hh', pgen, off)
        pgens.append({'op': op, 'amount': amount})

    igens = []
    for i in range(num_igens):
        off = i * 4
        op, amount = struct.unpack_from('<Hh', igen, off)
        igens.append({'op': op, 'amount': amount})

    # Parse instruments
    instruments = []
    for i in range(num_insts):
        off = i * 22
        name = inst[off:off+20].decode('ascii', errors='ignore').rstrip('\x00')
        bag_index = struct.unpack_from('<H', inst, off+20)[0]
        instruments.append({'name': name, 'bag_index': bag_index})

    # Parse sample headers
    samples = []
    for i in range(num_samples):
        off = i * 46
        name = shdr[off:off+20].decode('ascii', errors='ignore').rstrip('\x00')
        start, end, start_loop, end_loop, sample_rate = struct.unpack_from('<IIIII', shdr, off+20)
        orig_pitch, pitch_corr = struct.unpack_from('<Bb', shdr, off+40)
        sample_link, sample_type = struct.unpack_from('<HH', shdr, off+42)
        samples.append({
            'name': name, 'start': start, 'end': end,
            'start_loop': start_loop, 'end_loop': end_loop,
            'sample_rate': sample_rate, 'orig_pitch': orig_pitch,
            'pitch_corr': pitch_corr, 'sample_type': sample_type,
        })

    # Category detection
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

    for cat in category_keywords:
        os.makedirs(os.path.join(output_base, cat), exist_ok=True)

    def extract_sample_wav(sample, output_path):
        start = sample['start'] * 2
        end = min(sample['end'] * 2, len(smpl_data))
        sample_bytes = smpl_data[start:end]
        if len(sample_bytes) < 4:
            return False
        with wave.open(output_path, 'wb') as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(sample['sample_rate'])
            wav.writeframes(sample_bytes)
        return True

    extracted = 0
    failed = 0

    for preset in presets:
        cat = detect_category(preset['name'])
        safe_name = sanitize(preset['name'])
        out_path = os.path.join(output_base, cat, f"{safe_name}.wav")

        # Get preset bag range
        pbag_idx = preset['bag_index']
        if pbag_idx >= len(pbags):
            failed += 1
            continue

        pbag_start = pbags[pbag_idx]['gen_index']
        pbag_end = pbags[pbag_idx + 1]['gen_index'] if pbag_idx + 1 < len(pbags) else len(pgens)

        # Find instrument generator in preset bag
        inst_idx = None
        for g in pgens[pbag_start:pbag_end]:
            if g['op'] == 41:  # instrument
                inst_idx = g['amount']
                break

        if inst_idx is None or inst_idx >= len(instruments):
            failed += 1
            continue

        inst = instruments[inst_idx]
        ibag_idx = inst['bag_index']
        if ibag_idx >= len(ibags):
            failed += 1
            continue

        ibag_start = ibags[ibag_idx]['gen_index']
        ibag_end = ibags[ibag_idx + 1]['gen_index'] if ibag_idx + 1 < len(ibags) else len(igens)

        # Find sample generator in instrument bag
        sample_idx = None
        for g in igens[ibag_start:ibag_end]:
            if g['op'] == 53:  # sampleID
                sample_idx = g['amount']
                break

        if sample_idx is None or sample_idx >= len(samples):
            failed += 1
            continue

        sample = samples[sample_idx]

        if extract_sample_wav(sample, out_path):
            extracted += 1
            if extracted % 20 == 0:
                print(f"  Extracted {extracted}...")
        else:
            failed += 1

    print(f"\nDone: {extracted} extracted, {failed} failed")


if __name__ == '__main__':
    main()
