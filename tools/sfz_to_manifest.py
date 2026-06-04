#!/usr/bin/env python3
"""Convert SFZ files to OpenSynth JSON manifests."""
import sys, re, json, os
from pathlib import Path

def note_name_to_midi(name):
    notes = {'c':0,'c#':1,'db':1,'d':2,'d#':3,'eb':3,'e':4,'f':5,
             'f#':6,'gb':6,'g':7,'g#':8,'ab':8,'a':9,'a#':10,'bb':10,'b':11}
    m = re.match(r'([a-g][#b]?)(-?\d+)', name.lower())
    if m:
        return int(m.group(2)) * 12 + notes[m.group(1)] + 12
    try:
        return int(name)
    except ValueError:
        return 60

def expand_macros(text, macros):
    for key, val in macros.items():
        text = text.replace(f'${key}', val)
    return text

def read_include(path, base_dir, macros):
    """Read an include file, expanding macros in its content."""
    full = os.path.join(base_dir, expand_macros(path, macros))
    if not os.path.exists(full):
        return ''
    with open(full) as f:
        return expand_macros(f.read(), macros)

def parse_opcodes(line, zone):
    """Parse opcodes from a line into a zone dict."""
    for match in re.finditer(r'(\w+)=([^\s]+)', line):
        key, val = match.group(1), match.group(2)
        if key == 'sample':
            zone['file'] = val
        elif key == 'lokey':
            zone['minNote'] = note_name_to_midi(val)
        elif key == 'hikey':
            zone['maxNote'] = note_name_to_midi(val)
        elif key == 'pitch_keycenter':
            zone['rootNote'] = note_name_to_midi(val)
        elif key == 'lovel':
            zone['minVelocity'] = int(val) / 127.0
        elif key == 'hivel':
            zone['maxVelocity'] = int(val) / 127.0
        elif key == 'loop_start':
            zone['loopStart'] = int(val)
        elif key == 'loop_end':
            zone['loopEnd'] = int(val)
        elif key == 'loop_mode':
            zone['loopEnabled'] = (val == 'loop_continuous')

def parse_sfz(path):
    with open(path) as f:
        raw = f.read()
    
    base_dir = os.path.dirname(path)
    
    # Extract global macros
    global_macros = {}
    for m in re.finditer(r'#define\s+\\\$(\w+)\s+(\S+)', raw):
        global_macros[m.group(1)] = m.group(2)
    
    # Extract default_path
    default_path = ''
    m = re.search(r'default_path=([^\s]+)', raw)
    if m:
        default_path = m.group(1)
    
    zones = []
    current_zone = {}
    group_defaults = {}
    group_macros = dict(global_macros)
    in_group_header = False
    
    lines = raw.split('\n')
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        i += 1
        
        if not line or line.startswith('//'):
            continue
        
        if line.startswith('<group>'):
            group_defaults = {}
            group_macros = dict(global_macros)
            in_group_header = True
            # Parse opcodes on the <group> line itself
            parse_opcodes(line, group_defaults)
        
        elif line.startswith('<region>'):
            in_group_header = False
            if current_zone and 'file' in current_zone:
                zones.append(current_zone)
            current_zone = dict(group_defaults)
            parse_opcodes(line, current_zone)
        
        elif line.startswith('#include'):
            in_group_header = False
            m_inc = re.match(r'#include\s+"([^"]+)"', line)
            if m_inc:
                inc_path = m_inc.group(1).replace('$DIR/', 'Data/')
                inc_content = read_include(inc_path, base_dir, group_macros)
                for rline in inc_content.split('\n'):
                    rline = rline.strip()
                    if rline.startswith('<region>'):
                        if current_zone and 'file' in current_zone:
                            zones.append(current_zone)
                        current_zone = dict(group_defaults)
                    parse_opcodes(rline, current_zone)
        
        elif in_group_header:
            # Still in group header — parse opcodes and macros
            parse_opcodes(line, group_defaults)
            for match in re.finditer(r'#define\s+\\\$(\w+)\s+(\S+)', line):
                group_macros[match.group(1)] = match.group(2)
        
        else:
            # Regular line (could be opcodes after <region>)
            parse_opcodes(line, current_zone)
    
    if current_zone and 'file' in current_zone:
        zones.append(current_zone)
    
    # Resolve paths
    for z in zones:
        if 'file' in z:
            f = z['file']
            if f.startswith('/'):
                f = f[1:]
            if default_path and not f.startswith('/'):
                f = os.path.join(default_path, f)
            z['file'] = os.path.normpath(os.path.join(base_dir, f))
        if 'rootNote' not in z:
            z['rootNote'] = 60
        if 'minNote' not in z:
            z['minNote'] = 0
        if 'maxNote' not in z:
            z['maxNote'] = 127
        if 'minVelocity' not in z:
            z['minVelocity'] = 0.0
        if 'maxVelocity' not in z:
            z['maxVelocity'] = 1.0
    
    return zones

def main():
    sfz_path = sys.argv[1]
    out_path = sys.argv[2] if len(sys.argv) > 2 else sfz_path.replace('.sfz', '.json')
    
    zones = parse_sfz(sfz_path)
    
    manifest = {
        'name': Path(sfz_path).stem,
        'zones': zones
    }
    
    with open(out_path, 'w') as f:
        json.dump(manifest, f, indent=2)
    
    print(f"Wrote {len(zones)} zones to {out_path}")

if __name__ == '__main__':
    main()
