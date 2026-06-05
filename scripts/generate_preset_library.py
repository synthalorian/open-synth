#!/usr/bin/env python3
"""Generate preset_library_full.h with diverse synthesis configurations.

Architecture:
- 20+ categories with distinct synthesis profiles
- Each preset gets unique oscillator/filter/FX/envelope settings
- Acoustic categories use samples + synthesis layering
- Synth categories use full synthesis with category-appropriate waveforms
- Variations (Bright/Dark/Soft/Hard/etc.) modify the base profile
"""

import os
import random

OUTPUT = '/home/synth/projects/open-synth/include/preset_library_full.h'

random.seed(42)

# ── Waveform constants ───────────────────────────────────────────────────────
SINE = 0
TRIANGLE = 1
SAW = 2
SQUARE = 3
PULSE = 4
NOISE = 5
SUB = 6
FM = 7
WAVETABLE = 8
PM_KARPLUS = 9
PM_KARPLUS_BRIGHT = 10
PM_KARPLUS_BASS = 11
PM_MODAL_MALLET = 12
PM_MODAL_VIBRAPHONE = 13
PM_MODAL_STEEL = 14

# ── Category synthesis profiles ──────────────────────────────────────────────
# Each category defines a complete sonic signature.
# This is the fix for "everything sounds the same" — every category is distinct.

CATEGORY_PROFILES = {
    'piano': {
        'osc1Wave': WAVETABLE, 'osc1Vol': 0.7, 'osc1Uni': 1, 'osc1Det': 0.0, 'osc1Stereo': 0.0, 'osc1Mix': 0.0,
        'osc2Wave': SINE, 'osc2Vol': 0.0, 'osc2Uni': 1, 'osc2Det': 0.0, 'osc2Stereo': 0.0, 'osc2Mix': 0.0,
        'oscMix': 0.5,
        'filterType': 0, 'filterCutoff': 12000.0, 'filterRes': 0.15, 'filterEnv': 0.3, 'filterKeyTrack': 0.2, 'filterDrive': 0.0,
        'ampAttack': 3.0, 'ampDecay': 200.0, 'ampSustain': 0.65, 'ampRelease': 280.0,
        'filterAttack': 5.0, 'filterDecay': 150.0, 'filterSustain': 0.4, 'filterRelease': 200.0,
        'reverb': True, 'delay': False, 'chorus': False,
        'sampleMix': 0.65, 'manifest': 'splendid-grand-piano',
        'bodyType': 1, 'bodyMix': 0.35, 'clickMix': 0.2, 'sympathetic': 0.3, 'attackCurve': 1, 'brightness': 0.4,
    },
    'organ': {
        'osc1Wave': WAVETABLE, 'osc1Vol': 0.8, 'osc1Uni': 3, 'osc1Det': 6.0, 'osc1Stereo': 0.4, 'osc1Mix': 0.3,
        'osc2Wave': SQUARE, 'osc2Vol': 0.5, 'osc2Uni': 2, 'osc2Det': 4.0, 'osc2Stereo': 0.3, 'osc2Mix': 0.2,
        'oscMix': 0.4,
        'filterType': 0, 'filterCutoff': 8000.0, 'filterRes': 0.2, 'filterEnv': 0.2, 'filterKeyTrack': 0.0, 'filterDrive': 0.05,
        'ampAttack': 8.0, 'ampDecay': 100.0, 'ampSustain': 0.85, 'ampRelease': 150.0,
        'filterAttack': 10.0, 'filterDecay': 80.0, 'filterSustain': 0.6, 'filterRelease': 120.0,
        'reverb': True, 'delay': False, 'chorus': True,
        'sampleMix': 0.0, 'manifest': '',
        'bodyType': 4, 'bodyMix': 0.4, 'clickMix': 0.3, 'sympathetic': 0.0, 'attackCurve': 2, 'brightness': 0.2,
    },
    'guitar': {
        'osc1Wave': PM_KARPLUS, 'osc1Vol': 0.75, 'osc1Uni': 1, 'osc1Det': 0.0, 'osc1Stereo': 0.0, 'osc1Mix': 0.0,
        'osc2Wave': SINE, 'osc2Vol': 0.0, 'osc2Uni': 1, 'osc2Det': 0.0, 'osc2Stereo': 0.0, 'osc2Mix': 0.0,
        'oscMix': 0.5,
        'filterType': 0, 'filterCutoff': 6000.0, 'filterRes': 0.25, 'filterEnv': 0.4, 'filterKeyTrack': 0.15, 'filterDrive': 0.0,
        'ampAttack': 2.0, 'ampDecay': 180.0, 'ampSustain': 0.6, 'ampRelease': 220.0,
        'filterAttack': 3.0, 'filterDecay': 120.0, 'filterSustain': 0.35, 'filterRelease': 180.0,
        'reverb': True, 'delay': False, 'chorus': False,
        'sampleMix': 0.55, 'manifest': 'spanishclassicalguitar-20190618',
        'bodyType': 2, 'bodyMix': 0.35, 'clickMix': 0.15, 'sympathetic': 0.25, 'attackCurve': 3, 'brightness': 0.3,
    },
    'bass': {
        'osc1Wave': SAW, 'osc1Vol': 0.85, 'osc1Uni': 2, 'osc1Det': 8.0, 'osc1Stereo': 0.2, 'osc1Mix': 0.25,
        'osc2Wave': SQUARE, 'osc2Vol': 0.4, 'osc2Uni': 1, 'osc2Det': 0.0, 'osc2Stereo': 0.0, 'osc2Mix': 0.0,
        'oscMix': 0.35,
        'filterType': 0, 'filterCutoff': 2500.0, 'filterRes': 0.35, 'filterEnv': 0.6, 'filterKeyTrack': 0.3, 'filterDrive': 0.1,
        'ampAttack': 2.0, 'ampDecay': 150.0, 'ampSustain': 0.7, 'ampRelease': 180.0,
        'filterAttack': 2.0, 'filterDecay': 100.0, 'filterSustain': 0.5, 'filterRelease': 150.0,
        'reverb': False, 'delay': False, 'chorus': False,
        'sampleMix': 0.5, 'manifest': 'fingerbassyr-20190930',
        'bodyType': 5, 'bodyMix': 0.3, 'clickMix': 0.1, 'sympathetic': 0.0, 'attackCurve': 3, 'brightness': 0.2,
    },
    'strings': {
        'osc1Wave': SAW, 'osc1Vol': 0.7, 'osc1Uni': 5, 'osc1Det': 16.0, 'osc1Stereo': 0.8, 'osc1Mix': 0.6,
        'osc2Wave': SQUARE, 'osc2Vol': 0.35, 'osc2Uni': 3, 'osc2Det': 10.0, 'osc2Stereo': 0.5, 'osc2Mix': 0.3,
        'oscMix': 0.45,
        'filterType': 0, 'filterCutoff': 5000.0, 'filterRes': 0.2, 'filterEnv': 0.35, 'filterKeyTrack': 0.25, 'filterDrive': 0.0,
        'ampAttack': 15.0, 'ampDecay': 250.0, 'ampSustain': 0.75, 'ampRelease': 600.0,
        'filterAttack': 20.0, 'filterDecay': 200.0, 'filterSustain': 0.5, 'filterRelease': 400.0,
        'reverb': True, 'delay': True, 'chorus': True,
        'sampleMix': 0.7, 'manifest': '',
        'bodyType': 3, 'bodyMix': 0.4, 'clickMix': 0.0, 'sympathetic': 0.4, 'attackCurve': 1, 'brightness': 0.3,
    },
    'brass': {
        'osc1Wave': SAW, 'osc1Vol': 0.8, 'osc1Uni': 3, 'osc1Det': 10.0, 'osc1Stereo': 0.5, 'osc1Mix': 0.4,
        'osc2Wave': SQUARE, 'osc2Vol': 0.45, 'osc2Uni': 2, 'osc2Det': 6.0, 'osc2Stereo': 0.3, 'osc2Mix': 0.2,
        'oscMix': 0.5,
        'filterType': 0, 'filterCutoff': 4500.0, 'filterRes': 0.4, 'filterEnv': 0.55, 'filterKeyTrack': 0.2, 'filterDrive': 0.05,
        'ampAttack': 8.0, 'ampDecay': 180.0, 'ampSustain': 0.8, 'ampRelease': 350.0,
        'filterAttack': 10.0, 'filterDecay': 150.0, 'filterSustain': 0.6, 'filterRelease': 280.0,
        'reverb': True, 'delay': False, 'chorus': False,
        'sampleMix': 0.6, 'manifest': '',
        'bodyType': 6, 'bodyMix': 0.35, 'clickMix': 0.1, 'sympathetic': 0.0, 'attackCurve': 1, 'brightness': 0.5,
    },
    'woodwind': {
        'osc1Wave': TRIANGLE, 'osc1Vol': 0.75, 'osc1Uni': 2, 'osc1Det': 5.0, 'osc1Stereo': 0.3, 'osc1Mix': 0.2,
        'osc2Wave': SINE, 'osc2Vol': 0.3, 'osc2Uni': 1, 'osc2Det': 0.0, 'osc2Stereo': 0.0, 'osc2Mix': 0.0,
        'oscMix': 0.55,
        'filterType': 0, 'filterCutoff': 5500.0, 'filterRes': 0.25, 'filterEnv': 0.3, 'filterKeyTrack': 0.3, 'filterDrive': 0.0,
        'ampAttack': 12.0, 'ampDecay': 200.0, 'ampSustain': 0.72, 'ampRelease': 400.0,
        'filterAttack': 15.0, 'filterDecay': 160.0, 'filterSustain': 0.45, 'filterRelease': 300.0,
        'reverb': True, 'delay': False, 'chorus': False,
        'sampleMix': 0.7, 'manifest': '',
        'bodyType': 7, 'bodyMix': 0.3, 'clickMix': 0.15, 'sympathetic': 0.0, 'attackCurve': 1, 'brightness': 0.4,
    },
    'ethnic': {
        'osc1Wave': TRIANGLE, 'osc1Vol': 0.7, 'osc1Uni': 2, 'osc1Det': 8.0, 'osc1Stereo': 0.4, 'osc1Mix': 0.3,
        'osc2Wave': SINE, 'osc2Vol': 0.25, 'osc2Uni': 1, 'osc2Det': 0.0, 'osc2Stereo': 0.0, 'osc2Mix': 0.0,
        'oscMix': 0.5,
        'filterType': 0, 'filterCutoff': 7000.0, 'filterRes': 0.2, 'filterEnv': 0.25, 'filterKeyTrack': 0.1, 'filterDrive': 0.0,
        'ampAttack': 5.0, 'ampDecay': 180.0, 'ampSustain': 0.65, 'ampRelease': 300.0,
        'filterAttack': 8.0, 'filterDecay': 140.0, 'filterSustain': 0.4, 'filterRelease': 220.0,
        'reverb': True, 'delay': False, 'chorus': False,
        'sampleMix': 0.6, 'manifest': '',
        'bodyType': 0, 'bodyMix': 0.2, 'clickMix': 0.1, 'sympathetic': 0.15, 'attackCurve': 3, 'brightness': 0.2,
    },
    'percussion': {
        'osc1Wave': SINE, 'osc1Vol': 0.9, 'osc1Uni': 1, 'osc1Det': 0.0, 'osc1Stereo': 0.0, 'osc1Mix': 0.0,
        'osc2Wave': NOISE, 'osc2Vol': 0.3, 'osc2Uni': 1, 'osc2Det': 0.0, 'osc2Stereo': 0.0, 'osc2Mix': 0.0,
        'oscMix': 0.3,
        'filterType': 0, 'filterCutoff': 8000.0, 'filterRes': 0.15, 'filterEnv': 0.5, 'filterKeyTrack': 0.0, 'filterDrive': 0.0,
        'ampAttack': 1.0, 'ampDecay': 120.0, 'ampSustain': 0.1, 'ampRelease': 150.0,
        'filterAttack': 2.0, 'filterDecay': 80.0, 'filterSustain': 0.2, 'filterRelease': 100.0,
        'reverb': False, 'delay': False, 'chorus': False,
        'sampleMix': 0.7, 'manifest': '',
        'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'sympathetic': 0.0, 'attackCurve': 0, 'brightness': 0.1,
    },
    'chromatic': {
        'osc1Wave': SINE, 'osc1Vol': 0.8, 'osc1Uni': 1, 'osc1Det': 0.0, 'osc1Stereo': 0.0, 'osc1Mix': 0.0,
        'osc2Wave': FM, 'osc2Vol': 0.2, 'osc2Uni': 1, 'osc2Det': 0.0, 'osc2Stereo': 0.0, 'osc2Mix': 0.0,
        'oscMix': 0.4,
        'filterType': 0, 'filterCutoff': 9000.0, 'filterRes': 0.15, 'filterEnv': 0.3, 'filterKeyTrack': 0.1, 'filterDrive': 0.0,
        'ampAttack': 2.0, 'ampDecay': 200.0, 'ampSustain': 0.6, 'ampRelease': 250.0,
        'filterAttack': 3.0, 'filterDecay': 150.0, 'filterSustain': 0.35, 'filterRelease': 200.0,
        'reverb': True, 'delay': False, 'chorus': False,
        'sampleMix': 0.7, 'manifest': '',
        'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'sympathetic': 0.0, 'attackCurve': 0, 'brightness': 0.2,
    },
    'orchestral': {
        'osc1Wave': SAW, 'osc1Vol': 0.72, 'osc1Uni': 5, 'osc1Det': 14.0, 'osc1Stereo': 0.75, 'osc1Mix': 0.55,
        'osc2Wave': SQUARE, 'osc2Vol': 0.35, 'osc2Uni': 3, 'osc2Det': 8.0, 'osc2Stereo': 0.4, 'osc2Mix': 0.25,
        'oscMix': 0.45,
        'filterType': 0, 'filterCutoff': 4800.0, 'filterRes': 0.18, 'filterEnv': 0.3, 'filterKeyTrack': 0.2, 'filterDrive': 0.0,
        'ampAttack': 18.0, 'ampDecay': 280.0, 'ampSustain': 0.78, 'ampRelease': 700.0,
        'filterAttack': 25.0, 'filterDecay': 220.0, 'filterSustain': 0.55, 'filterRelease': 500.0,
        'reverb': True, 'delay': True, 'chorus': True,
        'sampleMix': 0.6, 'manifest': '',
        'bodyType': 3, 'bodyMix': 0.3, 'clickMix': 0.0, 'sympathetic': 0.3, 'attackCurve': 1, 'brightness': 0.3,
    },
    'synth_lead': {
        'osc1Wave': SAW, 'osc1Vol': 0.82, 'osc1Uni': 5, 'osc1Det': 18.0, 'osc1Stereo': 0.8, 'osc1Mix': 0.65,
        'osc2Wave': SQUARE, 'osc2Vol': 0.5, 'osc2Uni': 3, 'osc2Det': 12.0, 'osc2Stereo': 0.5, 'osc2Mix': 0.35,
        'oscMix': 0.5,
        'filterType': 0, 'filterCutoff': 9000.0, 'filterRes': 0.45, 'filterEnv': 0.6, 'filterKeyTrack': 0.25, 'filterDrive': 0.05,
        'ampAttack': 3.0, 'ampDecay': 180.0, 'ampSustain': 0.7, 'ampRelease': 280.0,
        'filterAttack': 3.0, 'filterDecay': 140.0, 'filterSustain': 0.5, 'filterRelease': 220.0,
        'reverb': True, 'delay': True, 'chorus': False,
        'sampleMix': 0.0, 'manifest': '',
        'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'sympathetic': 0.0, 'attackCurve': 0, 'brightness': 0.0,
    },
    'synth_pad': {
        'osc1Wave': SAW, 'osc1Vol': 0.7, 'osc1Uni': 7, 'osc1Det': 22.0, 'osc1Stereo': 0.9, 'osc1Mix': 0.75,
        'osc2Wave': TRIANGLE, 'osc2Vol': 0.4, 'osc2Uni': 4, 'osc2Det': 14.0, 'osc2Stereo': 0.6, 'osc2Mix': 0.4,
        'oscMix': 0.45,
        'filterType': 0, 'filterCutoff': 4000.0, 'filterRes': 0.3, 'filterEnv': 0.4, 'filterKeyTrack': 0.2, 'filterDrive': 0.0,
        'ampAttack': 25.0, 'ampDecay': 300.0, 'ampSustain': 0.8, 'ampRelease': 800.0,
        'filterAttack': 30.0, 'filterDecay': 250.0, 'filterSustain': 0.6, 'filterRelease': 600.0,
        'reverb': True, 'delay': True, 'chorus': True,
        'sampleMix': 0.0, 'manifest': '',
        'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'sympathetic': 0.0, 'attackCurve': 0, 'brightness': 0.0,
    },
    'fx': {
        'osc1Wave': NOISE, 'osc1Vol': 0.85, 'osc1Uni': 1, 'osc1Det': 0.0, 'osc1Stereo': 0.0, 'osc1Mix': 0.0,
        'osc2Wave': SAW, 'osc2Vol': 0.3, 'osc2Uni': 1, 'osc2Det': 0.0, 'osc2Stereo': 0.0, 'osc2Mix': 0.0,
        'oscMix': 0.3,
        'filterType': 0, 'filterCutoff': 10000.0, 'filterRes': 0.5, 'filterEnv': 0.7, 'filterKeyTrack': 0.0, 'filterDrive': 0.15,
        'ampAttack': 2.0, 'ampDecay': 400.0, 'ampSustain': 0.5, 'ampRelease': 600.0,
        'filterAttack': 5.0, 'filterDecay': 300.0, 'filterSustain': 0.4, 'filterRelease': 400.0,
        'reverb': True, 'delay': True, 'chorus': True,
        'sampleMix': 0.0, 'manifest': '',
        'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'sympathetic': 0.0, 'attackCurve': 0, 'brightness': 0.0,
    },
    'drums': {
        'osc1Wave': NOISE, 'osc1Vol': 0.9, 'osc1Uni': 1, 'osc1Det': 0.0, 'osc1Stereo': 0.0, 'osc1Mix': 0.0,
        'osc2Wave': SINE, 'osc2Vol': 0.4, 'osc2Uni': 1, 'osc2Det': 0.0, 'osc2Stereo': 0.0, 'osc2Mix': 0.0,
        'oscMix': 0.2,
        'filterType': 0, 'filterCutoff': 12000.0, 'filterRes': 0.1, 'filterEnv': 0.4, 'filterKeyTrack': 0.0, 'filterDrive': 0.0,
        'ampAttack': 1.0, 'ampDecay': 100.0, 'ampSustain': 0.05, 'ampRelease': 120.0,
        'filterAttack': 2.0, 'filterDecay': 60.0, 'filterSustain': 0.1, 'filterRelease': 80.0,
        'reverb': False, 'delay': False, 'chorus': False,
        'sampleMix': 0.85, 'manifest': 'muldjordkit-20201018',
        'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'sympathetic': 0.0, 'attackCurve': 0, 'brightness': 0.0,
    },
    'synth_bass': {
        'osc1Wave': SAW, 'osc1Vol': 0.88, 'osc1Uni': 3, 'osc1Det': 14.0, 'osc1Stereo': 0.4, 'osc1Mix': 0.4,
        'osc2Wave': SQUARE, 'osc2Vol': 0.45, 'osc2Uni': 2, 'osc2Det': 8.0, 'osc2Stereo': 0.25, 'osc2Mix': 0.2,
        'oscMix': 0.4,
        'filterType': 0, 'filterCutoff': 2800.0, 'filterRes': 0.4, 'filterEnv': 0.65, 'filterKeyTrack': 0.35, 'filterDrive': 0.1,
        'ampAttack': 2.0, 'ampDecay': 140.0, 'ampSustain': 0.72, 'ampRelease': 180.0,
        'filterAttack': 2.0, 'filterDecay': 90.0, 'filterSustain': 0.55, 'filterRelease': 140.0,
        'reverb': False, 'delay': False, 'chorus': False,
        'sampleMix': 0.0, 'manifest': '',
        'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'sympathetic': 0.0, 'attackCurve': 0, 'brightness': 0.0,
    },
    'synth_organ': {
        'osc1Wave': SQUARE, 'osc1Vol': 0.78, 'osc1Uni': 4, 'osc1Det': 8.0, 'osc1Stereo': 0.5, 'osc1Mix': 0.35,
        'osc2Wave': SAW, 'osc2Vol': 0.5, 'osc2Uni': 3, 'osc2Det': 6.0, 'osc2Stereo': 0.35, 'osc2Mix': 0.25,
        'oscMix': 0.4,
        'filterType': 0, 'filterCutoff': 7000.0, 'filterRes': 0.25, 'filterEnv': 0.2, 'filterKeyTrack': 0.0, 'filterDrive': 0.05,
        'ampAttack': 8.0, 'ampDecay': 120.0, 'ampSustain': 0.82, 'ampRelease': 160.0,
        'filterAttack': 10.0, 'filterDecay': 100.0, 'filterSustain': 0.6, 'filterRelease': 120.0,
        'reverb': True, 'delay': False, 'chorus': True,
        'sampleMix': 0.0, 'manifest': '',
        'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'sympathetic': 0.0, 'attackCurve': 0, 'brightness': 0.0,
    },
    'synth_piano': {
        'osc1Wave': FM, 'osc1Vol': 0.75, 'osc1Uni': 2, 'osc1Det': 4.0, 'osc1Stereo': 0.3, 'osc1Mix': 0.2,
        'osc2Wave': SINE, 'osc2Vol': 0.35, 'osc2Uni': 1, 'osc2Det': 0.0, 'osc2Stereo': 0.0, 'osc2Mix': 0.0,
        'oscMix': 0.5,
        'filterType': 0, 'filterCutoff': 10000.0, 'filterRes': 0.15, 'filterEnv': 0.25, 'filterKeyTrack': 0.15, 'filterDrive': 0.0,
        'ampAttack': 3.0, 'ampDecay': 180.0, 'ampSustain': 0.68, 'ampRelease': 260.0,
        'filterAttack': 5.0, 'filterDecay': 140.0, 'filterSustain': 0.4, 'filterRelease': 200.0,
        'reverb': True, 'delay': False, 'chorus': False,
        'sampleMix': 0.0, 'manifest': '',
        'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'sympathetic': 0.0, 'attackCurve': 0, 'brightness': 0.0,
    },
    'world': {
        'osc1Wave': TRIANGLE, 'osc1Vol': 0.7, 'osc1Uni': 2, 'osc1Det': 8.0, 'osc1Stereo': 0.4, 'osc1Mix': 0.3,
        'osc2Wave': SINE, 'osc2Vol': 0.3, 'osc2Uni': 1, 'osc2Det': 0.0, 'osc2Stereo': 0.0, 'osc2Mix': 0.0,
        'oscMix': 0.5,
        'filterType': 0, 'filterCutoff': 7500.0, 'filterRes': 0.2, 'filterEnv': 0.25, 'filterKeyTrack': 0.1, 'filterDrive': 0.0,
        'ampAttack': 5.0, 'ampDecay': 200.0, 'ampSustain': 0.65, 'ampRelease': 350.0,
        'filterAttack': 8.0, 'filterDecay': 160.0, 'filterSustain': 0.4, 'filterRelease': 250.0,
        'reverb': True, 'delay': False, 'chorus': False,
        'sampleMix': 0.6, 'manifest': '',
        'bodyType': 0, 'bodyMix': 0.2, 'clickMix': 0.1, 'sympathetic': 0.15, 'attackCurve': 3, 'brightness': 0.2,
    },
    'sfx': {
        'osc1Wave': NOISE, 'osc1Vol': 0.85, 'osc1Uni': 1, 'osc1Det': 0.0, 'osc1Stereo': 0.0, 'osc1Mix': 0.0,
        'osc2Wave': SAW, 'osc2Vol': 0.3, 'osc2Uni': 1, 'osc2Det': 0.0, 'osc2Stereo': 0.0, 'osc2Mix': 0.0,
        'oscMix': 0.3,
        'filterType': 0, 'filterCutoff': 10000.0, 'filterRes': 0.5, 'filterEnv': 0.7, 'filterKeyTrack': 0.0, 'filterDrive': 0.15,
        'ampAttack': 2.0, 'ampDecay': 400.0, 'ampSustain': 0.5, 'ampRelease': 600.0,
        'filterAttack': 5.0, 'filterDecay': 300.0, 'filterSustain': 0.4, 'filterRelease': 400.0,
        'reverb': True, 'delay': True, 'chorus': True,
        'sampleMix': 0.0, 'manifest': '',
        'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'sympathetic': 0.0, 'attackCurve': 0, 'brightness': 0.0,
    },
    'cinematic': {
        'osc1Wave': SAW, 'osc1Vol': 0.75, 'osc1Uni': 6, 'osc1Det': 18.0, 'osc1Stereo': 0.85, 'osc1Mix': 0.7,
        'osc2Wave': SQUARE, 'osc2Vol': 0.4, 'osc2Uni': 4, 'osc2Det': 12.0, 'osc2Stereo': 0.55, 'osc2Mix': 0.35,
        'oscMix': 0.45,
        'filterType': 0, 'filterCutoff': 5000.0, 'filterRes': 0.35, 'filterEnv': 0.5, 'filterKeyTrack': 0.2, 'filterDrive': 0.05,
        'ampAttack': 20.0, 'ampDecay': 300.0, 'ampSustain': 0.78, 'ampRelease': 900.0,
        'filterAttack': 25.0, 'filterDecay': 250.0, 'filterSustain': 0.6, 'filterRelease': 700.0,
        'reverb': True, 'delay': True, 'chorus': True,
        'sampleMix': 0.5, 'manifest': '',
        'bodyType': 3, 'bodyMix': 0.3, 'clickMix': 0.0, 'sympathetic': 0.2, 'attackCurve': 1, 'brightness': 0.3,
    },
    'other': {
        'osc1Wave': SAW, 'osc1Vol': 0.75, 'osc1Uni': 3, 'osc1Det': 10.0, 'osc1Stereo': 0.4, 'osc1Mix': 0.3,
        'osc2Wave': SQUARE, 'osc2Vol': 0.35, 'osc2Uni': 2, 'osc2Det': 6.0, 'osc2Stereo': 0.25, 'osc2Mix': 0.15,
        'oscMix': 0.5,
        'filterType': 0, 'filterCutoff': 8000.0, 'filterRes': 0.3, 'filterEnv': 0.4, 'filterKeyTrack': 0.15, 'filterDrive': 0.0,
        'ampAttack': 5.0, 'ampDecay': 200.0, 'ampSustain': 0.7, 'ampRelease': 300.0,
        'filterAttack': 8.0, 'filterDecay': 160.0, 'filterSustain': 0.45, 'filterRelease': 220.0,
        'reverb': True, 'delay': False, 'chorus': False,
        'sampleMix': 0.0, 'manifest': '',
        'bodyType': 0, 'bodyMix': 0.0, 'clickMix': 0.0, 'sympathetic': 0.0, 'attackCurve': 0, 'brightness': 0.0,
    },
}

# ── Variation modifiers ──────────────────────────────────────────────────────
# Each suffix applies deltas to the base profile.
VARIATIONS = [
    ("", {}),
    (" Bright", {'filterCutoff': 3000.0, 'brightness': 0.15, 'ampAttack': -1.0}),
    (" Dark", {'filterCutoff': -3000.0, 'brightness': -0.1, 'ampAttack': 2.0}),
    (" Soft", {'ampAttack': 4.0, 'ampRelease': 80.0, 'filterRes': -0.1, 'brightness': -0.08}),
    (" Hard", {'ampAttack': -1.5, 'ampRelease': -50.0, 'filterRes': 0.1, 'filterDrive': 0.05, 'brightness': 0.08}),
    (" Vintage", {'sampleMix': 0.1, 'filterCutoff': -2000.0, 'brightness': -0.08, 'filterRes': -0.05}),
    (" Modern", {'sampleMix': -0.1, 'filterCutoff': 2000.0, 'brightness': 0.08, 'filterRes': 0.05}),
    (" Layered", {'osc2Vol': 0.15, 'filterCutoff': 1000.0, 'brightness': 0.03}),
    (" Solo", {'ampAttack': 5.0, 'ampRelease': 100.0, 'brightness': 0.1, 'osc1Uni': -2, 'osc1Stereo': -0.3}),
]

# ── Base preset names by category ────────────────────────────────────────────
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
        "Contra Bassoon", "Alto Flute", "Penny Whistle", "Fife", "Dizi"
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

# ── Per-preset synthesis tweaks ──────────────────────────────────────────────
# Some specific presets within a category need unique treatment.
PRESET_OVERRIDES = {
    # Drums — each kit piece gets different synthesis
    ('drums', 'Standard Kit'): {'osc1Wave': NOISE, 'osc2Wave': SINE, 'filterCutoff': 10000.0},
    ('drums', 'TR-808 Kit'): {'osc1Wave': SINE, 'osc2Wave': NOISE, 'filterCutoff': 6000.0, 'ampDecay': 80.0},
    ('drums', 'Electronic Kit'): {'osc1Wave': SQUARE, 'osc2Wave': NOISE, 'filterCutoff': 8000.0},
    ('drums', 'Brush Kit 1'): {'osc1Wave': NOISE, 'filterCutoff': 12000.0, 'filterRes': 0.05},
    ('drums', 'Brush Kit 2'): {'osc1Wave': NOISE, 'filterCutoff': 10000.0, 'filterRes': 0.05},
    ('drums', 'Jazz Kit 1'): {'osc1Wave': NOISE, 'osc2Wave': SINE, 'filterCutoff': 9000.0},
    ('drums', 'Jazz Kit 2'): {'osc1Wave': NOISE, 'osc2Wave': SINE, 'filterCutoff': 8500.0},
    ('drums', 'Jazz Kit 3'): {'osc1Wave': NOISE, 'osc2Wave': SINE, 'filterCutoff': 8000.0},
    ('drums', 'Jazz Kit 4'): {'osc1Wave': NOISE, 'osc2Wave': SINE, 'filterCutoff': 7500.0},
    ('drums', 'Orchestra Kit'): {'osc1Wave': NOISE, 'osc2Wave': SINE, 'filterCutoff': 7000.0, 'reverb': True},
    ('drums', 'Concert Bass Drum'): {'osc1Wave': SINE, 'osc2Wave': NOISE, 'filterCutoff': 4000.0, 'ampDecay': 300.0},
    ('drums', 'Latin Kit'): {'osc1Wave': NOISE, 'osc2Wave': SINE, 'filterCutoff': 9000.0},
    ('drums', 'Dance Kit'): {'osc1Wave': SQUARE, 'osc2Wave': NOISE, 'filterCutoff': 10000.0},
    ('drums', 'Hip Hop Kit'): {'osc1Wave': SINE, 'osc2Wave': NOISE, 'filterCutoff': 7000.0},
    ('drums', 'Rock Kit'): {'osc1Wave': NOISE, 'osc2Wave': SINE, 'filterCutoff': 11000.0, 'filterDrive': 0.05},
    ('drums', 'Metal Kit'): {'osc1Wave': NOISE, 'osc2Wave': SINE, 'filterCutoff': 12000.0, 'filterDrive': 0.1},
    ('drums', 'Funk Kit'): {'osc1Wave': NOISE, 'osc2Wave': SINE, 'filterCutoff': 9500.0},
    ('drums', 'Soul Kit'): {'osc1Wave': NOISE, 'osc2Wave': SINE, 'filterCutoff': 8500.0},
    ('drums', 'Vintage Kit'): {'osc1Wave': NOISE, 'filterCutoff': 6000.0, 'sampleMix': 0.9},
    ('drums', 'Modern Kit'): {'osc1Wave': NOISE, 'osc2Wave': SQUARE, 'filterCutoff': 11000.0},
    ('drums', 'Minimal Kit'): {'osc1Wave': SINE, 'osc2Wave': NOISE, 'filterCutoff': 8000.0, 'ampDecay': 60.0},
    ('drums', 'Percussion Kit'): {'osc1Wave': NOISE, 'osc2Wave': SINE, 'filterCutoff': 10000.0},
    ('drums', 'Room Kit'): {'osc1Wave': NOISE, 'osc2Wave': SINE, 'filterCutoff': 8500.0, 'reverb': True},
    ('drums', 'Power Kit 1'): {'osc1Wave': NOISE, 'osc2Wave': SINE, 'filterCutoff': 11000.0, 'filterDrive': 0.08},
    ('drums', 'Power Kit 2'): {'osc1Wave': NOISE, 'osc2Wave': SINE, 'filterCutoff': 10500.0, 'filterDrive': 0.06},
    ('drums', 'Power Kit 3'): {'osc1Wave': NOISE, 'osc2Wave': SINE, 'filterCutoff': 10000.0, 'filterDrive': 0.05},

    # Bass — different characters
    ('bass', 'Slap Bass 1'): {'osc1Wave': SAW, 'filterCutoff': 3500.0, 'filterEnv': 0.7, 'ampAttack': 1.0},
    ('bass', 'Slap Bass 2'): {'osc1Wave': SAW, 'filterCutoff': 4000.0, 'filterEnv': 0.75, 'ampAttack': 1.5},
    ('bass', 'Synth Bass 1'): {'osc1Wave': SAW, 'osc2Wave': SQUARE, 'filterCutoff': 2500.0, 'sampleMix': 0.0},
    ('bass', 'Synth Bass 2'): {'osc1Wave': SQUARE, 'osc2Wave': SAW, 'filterCutoff': 2200.0, 'sampleMix': 0.0},
    ('bass', 'Synth Bass 3'): {'osc1Wave': PULSE, 'osc2Wave': SAW, 'filterCutoff': 3000.0, 'sampleMix': 0.0},
    ('bass', 'Synth Bass 4'): {'osc1Wave': FM, 'osc2Wave': SINE, 'filterCutoff': 3500.0, 'sampleMix': 0.0},
    ('bass', 'Synth Bass 5'): {'osc1Wave': SAW, 'osc2Wave': NOISE, 'filterCutoff': 2800.0, 'sampleMix': 0.0},
    ('bass', 'Acoustic Bass'): {'osc1Wave': PM_KARPLUS_BASS, 'osc1Vol': 0.7, 'sampleMix': 0.6},
    ('bass', 'Upright Bass'): {'osc1Wave': PM_KARPLUS_BASS, 'osc1Vol': 0.65, 'sampleMix': 0.65},
    ('bass', 'Fretless Bass'): {'osc1Wave': SAW, 'filterCutoff': 3200.0, 'filterRes': 0.3, 'ampAttack': 4.0},
    ('bass', 'Fingered Bass'): {'osc1Wave': SAW, 'filterCutoff': 2800.0, 'filterEnv': 0.55},
    ('bass', 'Picked Bass'): {'osc1Wave': SAW, 'filterCutoff': 3000.0, 'filterEnv': 0.6, 'ampAttack': 1.5},

    # Guitar — physical model vs samples
    ('guitar', 'Nylon String Guitar'): {'osc1Wave': PM_KARPLUS, 'sampleMix': 0.6},
    ('guitar', 'Steel String Guitar'): {'osc1Wave': PM_KARPLUS_BRIGHT, 'sampleMix': 0.55},
    ('guitar', '12 String Guitar'): {'osc1Wave': PM_KARPLUS_BRIGHT, 'osc1Uni': 2, 'osc1Det': 12.0, 'sampleMix': 0.5},
    ('guitar', 'Overdrive Guitar'): {'osc1Wave': SAW, 'osc2Wave': SQUARE, 'filterCutoff': 4500.0, 'filterDrive': 0.2, 'sampleMix': 0.3},
    ('guitar', 'Distortion Guitar'): {'osc1Wave': SAW, 'osc2Wave': SAW, 'filterCutoff': 5000.0, 'filterDrive': 0.35, 'sampleMix': 0.2},
    ('guitar', 'Ukulele'): {'osc1Wave': PM_KARPLUS, 'osc1Vol': 0.65, 'filterCutoff': 7000.0, 'sampleMix': 0.5},
    ('guitar', 'Mandolin'): {'osc1Wave': PM_KARPLUS_BRIGHT, 'osc1Vol': 0.7, 'filterCutoff': 6500.0, 'sampleMix': 0.45},

    # Piano — different characters
    ('piano', 'Grand Piano'): {'osc1Wave': WAVETABLE, 'sampleMix': 0.65},
    ('piano', 'Bright Piano'): {'osc1Wave': WAVETABLE, 'filterCutoff': 14000.0, 'brightness': 0.55, 'sampleMix': 0.6},
    ('piano', 'Electric Grand'): {'osc1Wave': FM, 'osc2Wave': SINE, 'filterCutoff': 10000.0, 'sampleMix': 0.4},
    ('piano', 'Honky Tonk'): {'osc1Wave': WAVETABLE, 'filterCutoff': 8000.0, 'filterRes': 0.2, 'sampleMix': 0.5},
    ('piano', 'Electric Piano 1'): {'osc1Wave': FM, 'osc2Wave': SINE, 'filterCutoff': 9000.0, 'sampleMix': 0.3},
    ('piano', 'Electric Piano 2'): {'osc1Wave': FM, 'osc2Wave': TRIANGLE, 'filterCutoff': 8500.0, 'sampleMix': 0.3},
    ('piano', 'Harpsichord'): {'osc1Wave': PM_KARPLUS_BRIGHT, 'osc1Vol': 0.7, 'ampAttack': 1.0, 'ampRelease': 150.0, 'sampleMix': 0.4},
    ('piano', 'Clavinet'): {'osc1Wave': SAW, 'osc2Wave': SQUARE, 'filterCutoff': 6000.0, 'ampAttack': 1.0, 'sampleMix': 0.3},
    ('piano', 'Celesta'): {'osc1Wave': PM_MODAL_MALLET, 'osc1Vol': 0.75, 'filterCutoff': 10000.0, 'ampAttack': 2.0, 'sampleMix': 0.5},
    ('piano', 'Music Box'): {'osc1Wave': PM_MODAL_MALLET, 'osc1Vol': 0.7, 'filterCutoff': 12000.0, 'ampAttack': 3.0, 'sampleMix': 0.4},

    # Strings — bowed vs plucked
    ('strings', 'Violin'): {'osc1Wave': SAW, 'osc1Uni': 3, 'osc1Det': 8.0, 'filterCutoff': 5500.0, 'sampleMix': 0.75},
    ('strings', 'Viola'): {'osc1Wave': SAW, 'osc1Uni': 3, 'osc1Det': 7.0, 'filterCutoff': 5000.0, 'sampleMix': 0.75},
    ('strings', 'Cello'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 6.0, 'filterCutoff': 4500.0, 'sampleMix': 0.7},
    ('strings', 'Contrabass'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 5.0, 'filterCutoff': 3500.0, 'sampleMix': 0.7},
    ('strings', 'Pizzicato Strings'): {'osc1Wave': PM_KARPLUS, 'osc1Vol': 0.7, 'ampAttack': 1.0, 'ampRelease': 180.0, 'sampleMix': 0.6},
    ('strings', 'Harp'): {'osc1Wave': PM_KARPLUS_BRIGHT, 'osc1Vol': 0.75, 'ampAttack': 2.0, 'ampRelease': 200.0, 'sampleMix': 0.65},
    ('strings', 'Tremolo Strings'): {'osc1Wave': SAW, 'osc1Uni': 5, 'osc1Det': 14.0, 'lfo1Depth': 0.4, 'lfo1Rate': 5.5, 'sampleMix': 0.7},
    ('strings', 'Choir Aahs'): {'osc1Wave': SAW, 'osc1Uni': 6, 'osc1Det': 18.0, 'filterCutoff': 4000.0, 'sampleMix': 0.5},
    ('strings', 'Choir Oohs'): {'osc1Wave': SAW, 'osc1Uni': 6, 'osc1Det': 16.0, 'filterCutoff': 3800.0, 'sampleMix': 0.5},
    ('strings', 'Orchestra Hit'): {'osc1Wave': SAW, 'osc1Uni': 7, 'osc1Det': 20.0, 'ampAttack': 2.0, 'ampDecay': 150.0, 'ampSustain': 0.3, 'ampRelease': 400.0, 'sampleMix': 0.6},

    # Brass — different sizes
    ('brass', 'Trumpet'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 6.0, 'filterCutoff': 5000.0, 'sampleMix': 0.65},
    ('brass', 'Trombone'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 5.0, 'filterCutoff': 4200.0, 'sampleMix': 0.65},
    ('brass', 'Tuba'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 4.0, 'filterCutoff': 3000.0, 'sampleMix': 0.6},
    ('brass', 'French Horn'): {'osc1Wave': SAW, 'osc1Uni': 3, 'osc1Det': 8.0, 'filterCutoff': 4000.0, 'sampleMix': 0.7},
    ('brass', 'Brass Section'): {'osc1Wave': SAW, 'osc1Uni': 5, 'osc1Det': 14.0, 'filterCutoff': 4500.0, 'sampleMix': 0.65},
    ('brass', 'Soprano Sax'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 7.0, 'filterCutoff': 5500.0, 'sampleMix': 0.7},
    ('brass', 'Alto Sax'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 6.0, 'filterCutoff': 5000.0, 'sampleMix': 0.7},
    ('brass', 'Tenor Sax'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 5.0, 'filterCutoff': 4500.0, 'sampleMix': 0.7},
    ('brass', 'Baritone Sax'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 4.0, 'filterCutoff': 3800.0, 'sampleMix': 0.7},
    ('brass', 'Muted Trumpet'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 5.0, 'filterCutoff': 3500.0, 'filterRes': 0.5, 'sampleMix': 0.6},

    # Woodwind
    ('woodwind', 'Flute'): {'osc1Wave': TRIANGLE, 'osc1Uni': 2, 'osc1Det': 4.0, 'filterCutoff': 7000.0, 'sampleMix': 0.75},
    ('woodwind', 'Piccolo'): {'osc1Wave': TRIANGLE, 'osc1Uni': 2, 'osc1Det': 5.0, 'filterCutoff': 9000.0, 'sampleMix': 0.75},
    ('woodwind', 'Clarinet'): {'osc1Wave': SQUARE, 'osc1Uni': 2, 'osc1Det': 4.0, 'filterCutoff': 5500.0, 'sampleMix': 0.7},
    ('woodwind', 'Oboe'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 5.0, 'filterCutoff': 6000.0, 'sampleMix': 0.7},
    ('woodwind', 'Bassoon'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 4.0, 'filterCutoff': 4000.0, 'sampleMix': 0.7},
    ('woodwind', 'Pan Flute'): {'osc1Wave': SINE, 'osc1Uni': 2, 'osc1Det': 3.0, 'filterCutoff': 8000.0, 'sampleMix': 0.6},
    ('woodwind', 'Shakuhachi'): {'osc1Wave': SINE, 'osc1Uni': 1, 'osc1Det': 2.0, 'filterCutoff': 6000.0, 'sampleMix': 0.65},
    ('woodwind', 'Recorder'): {'osc1Wave': TRIANGLE, 'osc1Uni': 2, 'osc1Det': 3.0, 'filterCutoff': 7500.0, 'sampleMix': 0.6},

    # Percussion — tuned vs untuned
    ('percussion', 'Glockenspiel'): {'osc1Wave': PM_MODAL_MALLET, 'osc1Vol': 0.8, 'ampAttack': 1.0, 'ampRelease': 180.0, 'sampleMix': 0.6},
    ('percussion', 'Vibraphone'): {'osc1Wave': PM_MODAL_VIBRAPHONE, 'osc1Vol': 0.8, 'ampAttack': 3.0, 'ampRelease': 250.0, 'sampleMix': 0.65},
    ('percussion', 'Marimba'): {'osc1Wave': PM_MODAL_MALLET, 'osc1Vol': 0.75, 'ampAttack': 2.0, 'ampRelease': 200.0, 'sampleMix': 0.6},
    ('percussion', 'Xylophone'): {'osc1Wave': PM_MODAL_MALLET, 'osc1Vol': 0.78, 'ampAttack': 1.0, 'ampRelease': 150.0, 'sampleMix': 0.55},
    ('percussion', 'Tubular Bells'): {'osc1Wave': PM_MODAL_STEEL, 'osc1Vol': 0.8, 'ampAttack': 3.0, 'ampRelease': 400.0, 'sampleMix': 0.6},
    ('percussion', 'Timpani'): {'osc1Wave': SINE, 'osc1Uni': 2, 'osc1Det': 4.0, 'filterCutoff': 4000.0, 'ampAttack': 5.0, 'sampleMix': 0.7},
    ('percussion', 'Steel Drums'): {'osc1Wave': PM_MODAL_STEEL, 'osc1Vol': 0.75, 'ampAttack': 2.0, 'sampleMix': 0.6},
    ('percussion', 'Taiko Drum'): {'osc1Wave': SINE, 'osc1Uni': 1, 'filterCutoff': 3000.0, 'ampAttack': 3.0, 'ampDecay': 250.0, 'sampleMix': 0.75},
    ('percussion', 'Melodic Tom'): {'osc1Wave': SINE, 'osc1Uni': 1, 'filterCutoff': 5000.0, 'ampAttack': 2.0, 'ampDecay': 180.0, 'sampleMix': 0.5},
    ('percussion', 'Synth Drum'): {'osc1Wave': SINE, 'osc2Wave': NOISE, 'filterCutoff': 7000.0, 'ampAttack': 1.0, 'ampDecay': 120.0, 'sampleMix': 0.0},
    ('percussion', '808 Tom'): {'osc1Wave': SINE, 'osc1Uni': 1, 'filterCutoff': 6000.0, 'ampAttack': 1.0, 'ampDecay': 150.0, 'sampleMix': 0.0},
    ('percussion', 'Woodblock'): {'osc1Wave': PM_MODAL_MALLET, 'osc1Vol': 0.7, 'ampAttack': 1.0, 'ampRelease': 100.0, 'sampleMix': 0.5},
    ('percussion', 'Triangle'): {'osc1Wave': PM_MODAL_STEEL, 'osc1Vol': 0.75, 'ampAttack': 2.0, 'ampRelease': 300.0, 'sampleMix': 0.55},
    ('percussion', 'Tambourine'): {'osc1Wave': NOISE, 'osc1Vol': 0.7, 'ampAttack': 1.0, 'ampDecay': 80.0, 'sampleMix': 0.6},
    ('percussion', 'Castanets'): {'osc1Wave': PM_MODAL_MALLET, 'osc1Vol': 0.7, 'ampAttack': 1.0, 'ampRelease': 80.0, 'sampleMix': 0.5},

    # Chromatic
    ('chromatic', 'Celesta'): {'osc1Wave': PM_MODAL_MALLET, 'osc1Vol': 0.8, 'ampAttack': 2.0, 'sampleMix': 0.55},
    ('chromatic', 'Glockenspiel'): {'osc1Wave': PM_MODAL_MALLET, 'osc1Vol': 0.82, 'ampAttack': 1.5, 'sampleMix': 0.55},
    ('chromatic', 'Vibraphone'): {'osc1Wave': PM_MODAL_VIBRAPHONE, 'osc1Vol': 0.8, 'ampAttack': 3.0, 'sampleMix': 0.6},
    ('chromatic', 'Marimba'): {'osc1Wave': PM_MODAL_MALLET, 'osc1Vol': 0.78, 'ampAttack': 2.0, 'sampleMix': 0.55},
    ('chromatic', 'Xylophone'): {'osc1Wave': PM_MODAL_MALLET, 'osc1Vol': 0.8, 'ampAttack': 1.0, 'sampleMix': 0.5},
    ('chromatic', 'Tubular Bells'): {'osc1Wave': PM_MODAL_STEEL, 'osc1Vol': 0.82, 'ampAttack': 3.0, 'sampleMix': 0.55},
    ('chromatic', 'Timpani'): {'osc1Wave': SINE, 'osc1Uni': 2, 'osc1Det': 4.0, 'ampAttack': 5.0, 'sampleMix': 0.7},
    ('chromatic', 'Steel Drums'): {'osc1Wave': PM_MODAL_STEEL, 'osc1Vol': 0.75, 'ampAttack': 2.0, 'sampleMix': 0.55},
    ('chromatic', 'Kalimba'): {'osc1Wave': PM_MODAL_MALLET, 'osc1Vol': 0.7, 'filterCutoff': 8000.0, 'sampleMix': 0.5},

    # Synth leads — each gets a distinct character
    ('synth_lead', 'Square Lead'): {'osc1Wave': SQUARE, 'osc1Uni': 1, 'osc1Det': 0.0, 'filterCutoff': 7000.0, 'filterRes': 0.3},
    ('synth_lead', 'Saw Wave'): {'osc1Wave': SAW, 'osc1Uni': 3, 'osc1Det': 8.0, 'filterCutoff': 9000.0, 'filterRes': 0.35},
    ('synth_lead', 'Super Saw'): {'osc1Wave': SAW, 'osc1Uni': 7, 'osc1Det': 22.0, 'osc1Stereo': 0.9, 'osc1Mix': 0.7, 'filterCutoff': 10000.0, 'filterRes': 0.4},
    ('synth_lead', 'Hyper Saw'): {'osc1Wave': SAW, 'osc1Uni': 9, 'osc1Det': 28.0, 'osc1Stereo': 1.0, 'osc1Mix': 0.8, 'filterCutoff': 11000.0, 'filterRes': 0.45},
    ('synth_lead', 'Acid Lead'): {'osc1Wave': SAW, 'osc1Uni': 1, 'osc1Det': 0.0, 'filterCutoff': 800.0, 'filterRes': 0.6, 'filterEnv': 0.8, 'ampAttack': 1.0},
    ('synth_lead', 'Trance Lead'): {'osc1Wave': SAW, 'osc1Uni': 5, 'osc1Det': 16.0, 'filterCutoff': 12000.0, 'filterRes': 0.35, 'delay': True},
    ('synth_lead', 'FM Lead'): {'osc1Wave': FM, 'osc1Uni': 1, 'osc1Det': 0.0, 'filterCutoff': 8000.0, 'filterRes': 0.25},
    ('synth_lead', 'Wavetable Lead'): {'osc1Wave': WAVETABLE, 'osc1Uni': 2, 'osc1Det': 4.0, 'filterCutoff': 9000.0, 'filterRes': 0.3},
    ('synth_lead', 'PWM Lead'): {'osc1Wave': PULSE, 'osc1Uni': 2, 'osc1Det': 3.0, 'filterCutoff': 7500.0, 'filterRes': 0.3, 'lfo1Target': 2, 'lfo1Depth': 0.4, 'lfo1Rate': 3.5},
    ('synth_lead', 'Sync Lead'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 12.0, 'filterCutoff': 6000.0, 'filterRes': 0.5},
    ('synth_lead', 'Pluck Lead'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 6.0, 'ampAttack': 1.0, 'ampDecay': 120.0, 'ampSustain': 0.2, 'ampRelease': 180.0, 'filterCutoff': 5000.0, 'filterEnv': 0.7},
    ('synth_lead', 'Bell Lead'): {'osc1Wave': FM, 'osc1Uni': 1, 'osc1Det': 0.0, 'ampAttack': 2.0, 'ampDecay': 300.0, 'ampSustain': 0.3, 'ampRelease': 400.0, 'filterCutoff': 10000.0},
    ('synth_lead', 'Vocal Lead'): {'osc1Wave': SAW, 'osc1Uni': 4, 'osc1Det': 12.0, 'filterCutoff': 3500.0, 'filterRes': 0.4, 'filterEnv': 0.5},
    ('synth_lead', 'Brass Lead'): {'osc1Wave': SAW, 'osc1Uni': 3, 'osc1Det': 10.0, 'ampAttack': 8.0, 'ampDecay': 180.0, 'ampSustain': 0.75, 'ampRelease': 350.0, 'filterCutoff': 4500.0, 'filterRes': 0.4},
    ('synth_lead', 'Flute Lead'): {'osc1Wave': TRIANGLE, 'osc1Uni': 2, 'osc1Det': 4.0, 'ampAttack': 10.0, 'ampDecay': 200.0, 'ampSustain': 0.7, 'ampRelease': 300.0, 'filterCutoff': 7000.0},
    ('synth_lead', 'Retro Lead'): {'osc1Wave': SAW, 'osc1Uni': 4, 'osc1Det': 14.0, 'filterCutoff': 6500.0, 'filterRes': 0.35, 'delay': True, 'chorus': True},
    ('synth_lead', 'Chip Lead'): {'osc1Wave': SQUARE, 'osc1Uni': 1, 'osc1Det': 0.0, 'filterCutoff': 8000.0, 'ampAttack': 1.0, 'ampDecay': 100.0, 'ampSustain': 0.5, 'ampRelease': 100.0},
    ('synth_lead', 'Stab Lead'): {'osc1Wave': SAW, 'osc1Uni': 3, 'osc1Det': 10.0, 'ampAttack': 2.0, 'ampDecay': 150.0, 'ampSustain': 0.4, 'ampRelease': 200.0, 'filterCutoff': 4000.0, 'filterEnv': 0.6},
    ('synth_lead', 'Rave Lead'): {'osc1Wave': SAW, 'osc1Uni': 5, 'osc1Det': 18.0, 'filterCutoff': 11000.0, 'filterRes': 0.4, 'filterDrive': 0.1},
    ('synth_lead', 'Detuned Lead'): {'osc1Wave': SAW, 'osc1Uni': 3, 'osc1Det': 25.0, 'filterCutoff': 8000.0, 'filterRes': 0.3},

    # Synth pads
    ('synth_pad', 'Warm Pad'): {'osc1Wave': SAW, 'osc1Uni': 7, 'osc1Det': 20.0, 'ampAttack': 30.0, 'ampRelease': 900.0, 'filterCutoff': 3500.0, 'filterRes': 0.25},
    ('synth_pad', 'Fantasia'): {'osc1Wave': TRIANGLE, 'osc1Uni': 6, 'osc1Det': 18.0, 'ampAttack': 35.0, 'ampRelease': 1000.0, 'filterCutoff': 5000.0, 'filterRes': 0.2},
    ('synth_pad', 'Space Voice'): {'osc1Wave': SAW, 'osc1Uni': 8, 'osc1Det': 24.0, 'ampAttack': 40.0, 'ampRelease': 1100.0, 'filterCutoff': 4000.0, 'filterRes': 0.3, 'chorus': True},
    ('synth_pad', 'Bowed Glass'): {'osc1Wave': SINE, 'osc1Uni': 4, 'osc1Det': 10.0, 'ampAttack': 50.0, 'ampRelease': 1200.0, 'filterCutoff': 6000.0, 'filterRes': 0.15},
    ('synth_pad', 'Sweep Pad'): {'osc1Wave': SAW, 'osc1Uni': 6, 'osc1Det': 20.0, 'ampAttack': 20.0, 'ampRelease': 800.0, 'filterCutoff': 3000.0, 'filterRes': 0.35, 'lfo1Target': 2, 'lfo1Depth': 0.5, 'lfo1Rate': 0.3},
    ('synth_pad', 'Crystal'): {'osc1Wave': FM, 'osc1Uni': 3, 'osc1Det': 6.0, 'ampAttack': 15.0, 'ampRelease': 700.0, 'filterCutoff': 10000.0, 'filterRes': 0.15},
    ('synth_pad', 'Atmosphere'): {'osc1Wave': SAW, 'osc1Uni': 8, 'osc1Det': 26.0, 'ampAttack': 45.0, 'ampRelease': 1200.0, 'filterCutoff': 2500.0, 'filterRes': 0.3, 'reverb': True, 'delay': True},
    ('synth_pad', 'Dark Pad'): {'osc1Wave': SAW, 'osc1Uni': 6, 'osc1Det': 18.0, 'ampAttack': 35.0, 'ampRelease': 1000.0, 'filterCutoff': 2000.0, 'filterRes': 0.35},
    ('synth_pad', 'Ambient Pad'): {'osc1Wave': SINE, 'osc1Uni': 5, 'osc1Det': 14.0, 'ampAttack': 60.0, 'ampRelease': 1500.0, 'filterCutoff': 4000.0, 'filterRes': 0.1},
    ('synth_pad', 'String Pad'): {'osc1Wave': SAW, 'osc1Uni': 5, 'osc1Det': 16.0, 'ampAttack': 20.0, 'ampRelease': 800.0, 'filterCutoff': 4500.0, 'filterRes': 0.2},
    ('synth_pad', 'Vox Pad'): {'osc1Wave': SAW, 'osc1Uni': 6, 'osc1Det': 20.0, 'ampAttack': 30.0, 'ampRelease': 900.0, 'filterCutoff': 3500.0, 'filterRes': 0.3, 'filterEnv': 0.4},
    ('synth_pad', 'Drone Pad'): {'osc1Wave': SAW, 'osc1Uni': 4, 'osc1Det': 12.0, 'ampAttack': 80.0, 'ampRelease': 2000.0, 'filterCutoff': 1500.0, 'filterRes': 0.4},
    ('synth_pad', 'Motion Pad'): {'osc1Wave': SAW, 'osc1Uni': 6, 'osc1Det': 20.0, 'ampAttack': 25.0, 'ampRelease': 850.0, 'filterCutoff': 3500.0, 'filterRes': 0.3, 'lfo1Target': 1, 'lfo1Depth': 0.3, 'lfo1Rate': 2.0},
    ('synth_pad', 'Evolving Pad'): {'osc1Wave': SAW, 'osc1Uni': 7, 'osc1Det': 22.0, 'ampAttack': 40.0, 'ampRelease': 1100.0, 'filterCutoff': 3000.0, 'filterRes': 0.35, 'lfo1Target': 2, 'lfo1Depth': 0.4, 'lfo1Rate': 0.15},

    # FX / SFX
    ('fx', 'Gun Shot'): {'osc1Wave': NOISE, 'ampAttack': 1.0, 'ampDecay': 80.0, 'ampSustain': 0.0, 'ampRelease': 100.0, 'filterCutoff': 8000.0, 'filterRes': 0.3},
    ('fx', 'Laser'): {'osc1Wave': SAW, 'ampAttack': 1.0, 'ampDecay': 150.0, 'ampSustain': 0.0, 'ampRelease': 200.0, 'filterCutoff': 12000.0, 'filterRes': 0.5, 'lfo1Target': 2, 'lfo1Depth': 0.8, 'lfo1Rate': 8.0},
    ('fx', 'Explosion'): {'osc1Wave': NOISE, 'ampAttack': 5.0, 'ampDecay': 400.0, 'ampSustain': 0.0, 'ampRelease': 600.0, 'filterCutoff': 3000.0, 'filterRes': 0.2},
    ('fx', 'Wind'): {'osc1Wave': NOISE, 'ampAttack': 100.0, 'ampDecay': 500.0, 'ampSustain': 0.8, 'ampRelease': 800.0, 'filterCutoff': 4000.0, 'filterRes': 0.2},
    ('fx', 'Rain'): {'osc1Wave': NOISE, 'ampAttack': 50.0, 'ampDecay': 200.0, 'ampSustain': 0.6, 'ampRelease': 400.0, 'filterCutoff': 10000.0, 'filterRes': 0.1},
    ('fx', 'Thunder'): {'osc1Wave': NOISE, 'ampAttack': 10.0, 'ampDecay': 600.0, 'ampSustain': 0.0, 'ampRelease': 800.0, 'filterCutoff': 2000.0, 'filterRes': 0.15},
    ('fx', 'Sci-Fi'): {'osc1Wave': SAW, 'ampAttack': 5.0, 'ampDecay': 300.0, 'ampSustain': 0.0, 'ampRelease': 400.0, 'filterCutoff': 10000.0, 'filterRes': 0.5, 'lfo1Target': 2, 'lfo1Depth': 0.6, 'lfo1Rate': 5.0},
    ('fx', 'Magic'): {'osc1Wave': FM, 'ampAttack': 10.0, 'ampDecay': 400.0, 'ampSustain': 0.0, 'ampRelease': 500.0, 'filterCutoff': 12000.0, 'filterRes': 0.3},
    ('fx', 'Ghost'): {'osc1Wave': SINE, 'ampAttack': 30.0, 'ampDecay': 500.0, 'ampSustain': 0.3, 'ampRelease': 700.0, 'filterCutoff': 3000.0, 'filterRes': 0.4},
    ('fx', 'Robot'): {'osc1Wave': SQUARE, 'ampAttack': 2.0, 'ampDecay': 200.0, 'ampSustain': 0.5, 'ampRelease': 300.0, 'filterCutoff': 6000.0, 'filterRes': 0.3, 'lfo1Target': 1, 'lfo1Depth': 0.5, 'lfo1Rate': 6.0},

    # Cinematic
    ('cinematic', 'Epic Brass'): {'osc1Wave': SAW, 'osc1Uni': 6, 'osc1Det': 18.0, 'ampAttack': 15.0, 'ampRelease': 700.0, 'filterCutoff': 4000.0, 'filterRes': 0.4},
    ('cinematic', 'Epic Strings'): {'osc1Wave': SAW, 'osc1Uni': 7, 'osc1Det': 20.0, 'ampAttack': 25.0, 'ampRelease': 900.0, 'filterCutoff': 4500.0, 'filterRes': 0.25},
    ('cinematic', 'Epic Choir'): {'osc1Wave': SAW, 'osc1Uni': 8, 'osc1Det': 22.0, 'ampAttack': 30.0, 'ampRelease': 1000.0, 'filterCutoff': 3500.0, 'filterRes': 0.3},
    ('cinematic', 'Trailer Hit'): {'osc1Wave': NOISE, 'osc2Wave': SAW, 'ampAttack': 2.0, 'ampDecay': 200.0, 'ampSustain': 0.1, 'ampRelease': 500.0, 'filterCutoff': 5000.0, 'filterRes': 0.3},
    ('cinematic', 'Cinematic Drums'): {'osc1Wave': NOISE, 'osc2Wave': SINE, 'ampAttack': 3.0, 'ampDecay': 250.0, 'ampSustain': 0.05, 'ampRelease': 400.0, 'filterCutoff': 4000.0, 'filterRes': 0.2},
    ('cinematic', 'Cinematic Pad'): {'osc1Wave': SAW, 'osc1Uni': 7, 'osc1Det': 20.0, 'ampAttack': 35.0, 'ampRelease': 1100.0, 'filterCutoff': 3000.0, 'filterRes': 0.35},
    ('cinematic', 'Suspense'): {'osc1Wave': SAW, 'osc1Uni': 5, 'osc1Det': 16.0, 'ampAttack': 40.0, 'ampRelease': 1200.0, 'filterCutoff': 2000.0, 'filterRes': 0.4},
    ('cinematic', 'Tension'): {'osc1Wave': SAW, 'osc1Uni': 6, 'osc1Det': 18.0, 'ampAttack': 20.0, 'ampRelease': 800.0, 'filterCutoff': 2500.0, 'filterRes': 0.45},
    ('cinematic', 'Horror'): {'osc1Wave': SAW, 'osc1Uni': 4, 'osc1Det': 14.0, 'ampAttack': 50.0, 'ampRelease': 1500.0, 'filterCutoff': 1500.0, 'filterRes': 0.5},
    ('cinematic', 'Triumph'): {'osc1Wave': SAW, 'osc1Uni': 7, 'osc1Det': 20.0, 'ampAttack': 20.0, 'ampRelease': 900.0, 'filterCutoff': 5000.0, 'filterRes': 0.3},
    ('cinematic', 'Discovery'): {'osc1Wave': FM, 'osc1Uni': 3, 'osc1Det': 6.0, 'ampAttack': 25.0, 'ampRelease': 1000.0, 'filterCutoff': 8000.0, 'filterRes': 0.2},
    ('cinematic', 'Mystery'): {'osc1Wave': SINE, 'osc1Uni': 4, 'osc1Det': 10.0, 'ampAttack': 45.0, 'ampRelease': 1300.0, 'filterCutoff': 3000.0, 'filterRes': 0.35},

    # Synth bass
    ('synth_bass', 'Sub Bass'): {'osc1Wave': SINE, 'osc1Uni': 1, 'filterCutoff': 800.0, 'filterRes': 0.2},
    ('synth_bass', 'Reese Bass'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 16.0, 'filterCutoff': 2500.0, 'filterRes': 0.45},
    ('synth_bass', 'Acid Bass'): {'osc1Wave': SAW, 'osc1Uni': 1, 'filterCutoff': 600.0, 'filterRes': 0.6, 'filterEnv': 0.85, 'ampAttack': 1.0},
    ('synth_bass', 'Growl Bass'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 14.0, 'filterCutoff': 2000.0, 'filterRes': 0.5, 'filterDrive': 0.15},
    ('synth_bass', 'Talking Bass'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 12.0, 'filterCutoff': 1800.0, 'filterRes': 0.55, 'lfo1Target': 2, 'lfo1Depth': 0.6, 'lfo1Rate': 4.0},
    ('synth_bass', 'Wobble Bass'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 10.0, 'filterCutoff': 1500.0, 'filterRes': 0.5, 'lfo1Target': 2, 'lfo1Depth': 0.7, 'lfo1Rate': 2.5},
    ('synth_bass', 'FM Bass'): {'osc1Wave': FM, 'osc1Uni': 1, 'filterCutoff': 3500.0, 'filterRes': 0.3},
    ('synth_bass', 'Pluck Bass'): {'osc1Wave': SAW, 'osc1Uni': 1, 'ampAttack': 1.0, 'ampDecay': 120.0, 'ampSustain': 0.2, 'ampRelease': 150.0, 'filterCutoff': 3000.0, 'filterEnv': 0.7},
    ('synth_bass', 'Sine Bass'): {'osc1Wave': SINE, 'osc1Uni': 1, 'filterCutoff': 1200.0, 'filterRes': 0.15},
    ('synth_bass', 'Saw Bass'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 8.0, 'filterCutoff': 2800.0, 'filterRes': 0.35},
    ('synth_bass', 'Square Bass'): {'osc1Wave': SQUARE, 'osc1Uni': 2, 'osc1Det': 6.0, 'filterCutoff': 2500.0, 'filterRes': 0.3},
    ('synth_bass', 'Pulse Bass'): {'osc1Wave': PULSE, 'osc1Uni': 1, 'filterCutoff': 2200.0, 'filterRes': 0.35},
    ('synth_bass', 'Distorted Bass'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 10.0, 'filterCutoff': 3500.0, 'filterRes': 0.4, 'filterDrive': 0.25},
    ('synth_bass', 'Fuzz Bass'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 12.0, 'filterCutoff': 4000.0, 'filterRes': 0.45, 'filterDrive': 0.35},
    ('synth_bass', 'Deep Bass'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 8.0, 'filterCutoff': 1500.0, 'filterRes': 0.3, 'ampAttack': 3.0},
    ('synth_bass', 'Reso Bass'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 10.0, 'filterCutoff': 2000.0, 'filterRes': 0.55},
    ('synth_bass', 'Tech Bass'): {'osc1Wave': SAW, 'osc1Uni': 1, 'filterCutoff': 3000.0, 'filterRes': 0.3, 'ampAttack': 1.5},
    ('synth_bass', 'Electro Bass'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 8.0, 'filterCutoff': 3200.0, 'filterRes': 0.35, 'ampAttack': 1.0},
    ('synth_bass', 'Future Bass'): {'osc1Wave': SAW, 'osc1Uni': 3, 'osc1Det': 14.0, 'filterCutoff': 3500.0, 'filterRes': 0.4, 'ampAttack': 2.0},
    ('synth_bass', 'Trap Bass'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 12.0, 'filterCutoff': 2800.0, 'filterRes': 0.45, 'ampAttack': 1.0, 'ampDecay': 100.0},
    ('synth_bass', 'Dub Bass'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 10.0, 'filterCutoff': 1800.0, 'filterRes': 0.5, 'lfo1Target': 2, 'lfo1Depth': 0.5, 'lfo1Rate': 1.5},

    # Synth organ
    ('synth_organ', 'Digital Organ'): {'osc1Wave': SQUARE, 'osc1Uni': 4, 'osc1Det': 6.0, 'filterCutoff': 8000.0, 'ampAttack': 5.0},
    ('synth_organ', 'FM Organ'): {'osc1Wave': FM, 'osc1Uni': 2, 'osc1Det': 3.0, 'filterCutoff': 9000.0, 'ampAttack': 8.0},
    ('synth_organ', 'Wavetable Organ'): {'osc1Wave': WAVETABLE, 'osc1Uni': 3, 'osc1Det': 4.0, 'filterCutoff': 8500.0, 'ampAttack': 6.0},
    ('synth_organ', 'Pulse Organ'): {'osc1Wave': PULSE, 'osc1Uni': 3, 'osc1Det': 5.0, 'filterCutoff': 7500.0, 'ampAttack': 5.0},
    ('synth_organ', 'Saw Organ'): {'osc1Wave': SAW, 'osc1Uni': 4, 'osc1Det': 8.0, 'filterCutoff': 7000.0, 'ampAttack': 5.0},
    ('synth_organ', 'Square Organ'): {'osc1Wave': SQUARE, 'osc1Uni': 4, 'osc1Det': 6.0, 'filterCutoff': 8000.0, 'ampAttack': 5.0},
    ('synth_organ', 'Percussive Synth Organ'): {'osc1Wave': SAW, 'osc1Uni': 3, 'osc1Det': 5.0, 'ampAttack': 2.0, 'filterCutoff': 6000.0},
    ('synth_organ', 'Cathedral Organ'): {'osc1Wave': SQUARE, 'osc1Uni': 5, 'osc1Det': 8.0, 'ampAttack': 15.0, 'ampRelease': 300.0, 'filterCutoff': 6000.0, 'reverb': True},
    ('synth_organ', 'Pipe Organ'): {'osc1Wave': SQUARE, 'osc1Uni': 4, 'osc1Det': 4.0, 'ampAttack': 10.0, 'ampRelease': 250.0, 'filterCutoff': 7000.0},

    # Synth piano
    ('synth_piano', 'Digital Piano'): {'osc1Wave': FM, 'osc1Uni': 2, 'osc1Det': 3.0, 'filterCutoff': 10000.0, 'ampAttack': 3.0},
    ('synth_piano', 'FM Piano'): {'osc1Wave': FM, 'osc1Uni': 1, 'filterCutoff': 11000.0, 'ampAttack': 2.0},
    ('synth_piano', 'Wavetable Piano'): {'osc1Wave': WAVETABLE, 'osc1Uni': 2, 'osc1Det': 2.0, 'filterCutoff': 12000.0, 'ampAttack': 3.0},
    ('synth_piano', 'Bell Piano'): {'osc1Wave': FM, 'osc1Uni': 1, 'filterCutoff': 12000.0, 'ampAttack': 2.0, 'ampDecay': 250.0, 'ampSustain': 0.3},
    ('synth_piano', 'Glass Piano'): {'osc1Wave': FM, 'osc1Uni': 2, 'osc1Det': 4.0, 'filterCutoff': 14000.0, 'ampAttack': 4.0, 'ampDecay': 300.0},
    ('synth_piano', 'Crystal Piano'): {'osc1Wave': FM, 'osc1Uni': 2, 'osc1Det': 3.0, 'filterCutoff': 13000.0, 'ampAttack': 3.0, 'ampDecay': 280.0},
    ('synth_piano', 'Dream Piano'): {'osc1Wave': FM, 'osc1Uni': 2, 'osc1Det': 5.0, 'filterCutoff': 10000.0, 'ampAttack': 8.0, 'ampRelease': 400.0, 'reverb': True},
    ('synth_piano', 'Ambient Piano'): {'osc1Wave': FM, 'osc1Uni': 2, 'osc1Det': 4.0, 'filterCutoff': 9000.0, 'ampAttack': 15.0, 'ampRelease': 600.0, 'reverb': True, 'delay': True},
    ('synth_piano', 'Chime Piano'): {'osc1Wave': FM, 'osc1Uni': 1, 'filterCutoff': 12000.0, 'ampAttack': 2.0, 'ampDecay': 200.0, 'ampSustain': 0.25},
    ('synth_piano', 'Marimba Piano'): {'osc1Wave': PM_MODAL_MALLET, 'osc1Uni': 1, 'filterCutoff': 9000.0, 'ampAttack': 2.0, 'ampDecay': 180.0},

    # World
    ('world', 'Sitar'): {'osc1Wave': PM_KARPLUS, 'osc1Uni': 2, 'osc1Det': 6.0, 'filterCutoff': 6000.0, 'sampleMix': 0.5},
    ('world', 'Koto'): {'osc1Wave': PM_KARPLUS_BRIGHT, 'osc1Uni': 1, 'filterCutoff': 7000.0, 'sampleMix': 0.5},
    ('world', 'Shamisen'): {'osc1Wave': PM_KARPLUS, 'osc1Uni': 1, 'filterCutoff': 6500.0, 'sampleMix': 0.5},
    ('world', 'Balalaika'): {'osc1Wave': PM_KARPLUS_BRIGHT, 'osc1Uni': 2, 'osc1Det': 5.0, 'filterCutoff': 7000.0, 'sampleMix': 0.45},
    ('world', 'Oud'): {'osc1Wave': PM_KARPLUS, 'osc1Uni': 1, 'filterCutoff': 6000.0, 'sampleMix': 0.5},
    ('world', 'Bouzouki'): {'osc1Wave': PM_KARPLUS_BRIGHT, 'osc1Uni': 2, 'osc1Det': 4.0, 'filterCutoff': 6500.0, 'sampleMix': 0.45},
    ('world', 'Charango'): {'osc1Wave': PM_KARPLUS, 'osc1Uni': 1, 'filterCutoff': 7000.0, 'sampleMix': 0.4},
    ('world', 'Didgeridoo'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 8.0, 'filterCutoff': 2500.0, 'ampAttack': 20.0, 'sampleMix': 0.3},
    ('world', 'Pan Pipes'): {'osc1Wave': SINE, 'osc1Uni': 2, 'osc1Det': 3.0, 'filterCutoff': 8000.0, 'ampAttack': 15.0, 'sampleMix': 0.5},
    ('world', 'Native Flute'): {'osc1Wave': SINE, 'osc1Uni': 1, 'filterCutoff': 7000.0, 'ampAttack': 12.0, 'sampleMix': 0.5},
    ('world', 'Shakuhachi'): {'osc1Wave': SINE, 'osc1Uni': 1, 'filterCutoff': 6000.0, 'ampAttack': 20.0, 'sampleMix': 0.55},
    ('world', 'Erhu'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 5.0, 'filterCutoff': 5500.0, 'ampAttack': 15.0, 'sampleMix': 0.5},
    ('world', 'Pipa'): {'osc1Wave': PM_KARPLUS, 'osc1Uni': 1, 'filterCutoff': 7000.0, 'sampleMix': 0.45},
    ('world', 'Guzheng'): {'osc1Wave': PM_KARPLUS_BRIGHT, 'osc1Uni': 2, 'osc1Det': 4.0, 'filterCutoff': 7500.0, 'sampleMix': 0.45},
    ('world', 'Santoor'): {'osc1Wave': PM_MODAL_MALLET, 'osc1Uni': 2, 'osc1Det': 3.0, 'filterCutoff': 8000.0, 'sampleMix': 0.4},
    ('world', 'Steel Drum World'): {'osc1Wave': PM_MODAL_STEEL, 'osc1Uni': 1, 'filterCutoff': 9000.0, 'sampleMix': 0.5},
    ('world', 'Kalimba World'): {'osc1Wave': PM_MODAL_MALLET, 'osc1Uni': 1, 'filterCutoff': 8500.0, 'sampleMix': 0.45},
    ('world', 'Bongo World'): {'osc1Wave': NOISE, 'osc1Uni': 1, 'filterCutoff': 8000.0, 'ampAttack': 1.0, 'sampleMix': 0.6},
    ('world', 'Tabla'): {'osc1Wave': SINE, 'osc1Uni': 1, 'filterCutoff': 5000.0, 'ampAttack': 2.0, 'sampleMix': 0.6},
    ('world', 'Djembe'): {'osc1Wave': SINE, 'osc1Uni': 1, 'filterCutoff': 4500.0, 'ampAttack': 2.0, 'sampleMix': 0.6},
    ('world', 'Talking Drum'): {'osc1Wave': SINE, 'osc1Uni': 1, 'filterCutoff': 4000.0, 'ampAttack': 3.0, 'sampleMix': 0.55},
    ('world', 'Celtic Harp'): {'osc1Wave': PM_KARPLUS_BRIGHT, 'osc1Uni': 2, 'osc1Det': 4.0, 'filterCutoff': 8000.0, 'sampleMix': 0.55},
    ('world', 'Fiddle World'): {'osc1Wave': SAW, 'osc1Uni': 2, 'osc1Det': 6.0, 'filterCutoff': 6000.0, 'ampAttack': 8.0, 'sampleMix': 0.5},
    ('world', 'Bagpipe World'): {'osc1Wave': SAW, 'osc1Uni': 3, 'osc1Det': 8.0, 'filterCutoff': 4500.0, 'ampAttack': 15.0, 'sampleMix': 0.5},

    # SFX
    ('sfx', 'Rise'): {'osc1Wave': SAW, 'ampAttack': 50.0, 'ampDecay': 500.0, 'ampSustain': 0.0, 'ampRelease': 600.0, 'filterCutoff': 500.0, 'filterRes': 0.4, 'lfo1Target': 2, 'lfo1Depth': 0.8, 'lfo1Rate': 0.2},
    ('sfx', 'Downer'): {'osc1Wave': SAW, 'ampAttack': 10.0, 'ampDecay': 400.0, 'ampSustain': 0.0, 'ampRelease': 500.0, 'filterCutoff': 10000.0, 'filterRes': 0.3, 'lfo1Target': 2, 'lfo1Depth': 0.7, 'lfo1Rate': 0.15},
    ('sfx', 'Impact'): {'osc1Wave': NOISE, 'osc2Wave': SAW, 'ampAttack': 2.0, 'ampDecay': 200.0, 'ampSustain': 0.0, 'ampRelease': 400.0, 'filterCutoff': 4000.0, 'filterRes': 0.2},
    ('sfx', 'Whoosh'): {'osc1Wave': NOISE, 'ampAttack': 5.0, 'ampDecay': 300.0, 'ampSustain': 0.0, 'ampRelease': 400.0, 'filterCutoff': 8000.0, 'filterRes': 0.15},
    ('sfx', 'Stinger'): {'osc1Wave': FM, 'ampAttack': 1.0, 'ampDecay': 150.0, 'ampSustain': 0.0, 'ampRelease': 300.0, 'filterCutoff': 12000.0, 'filterRes': 0.3},
    ('sfx', 'Hit'): {'osc1Wave': NOISE, 'osc2Wave': SAW, 'ampAttack': 1.0, 'ampDecay': 100.0, 'ampSustain': 0.0, 'ampRelease': 200.0, 'filterCutoff': 6000.0, 'filterRes': 0.2},
    ('sfx', 'Sweep'): {'osc1Wave': SAW, 'ampAttack': 20.0, 'ampDecay': 400.0, 'ampSustain': 0.0, 'ampRelease': 500.0, 'filterCutoff': 1000.0, 'filterRes': 0.5, 'lfo1Target': 2, 'lfo1Depth': 0.9, 'lfo1Rate': 0.5},
    ('sfx', 'Zap'): {'osc1Wave': SAW, 'ampAttack': 1.0, 'ampDecay': 80.0, 'ampSustain': 0.0, 'ampRelease': 100.0, 'filterCutoff': 12000.0, 'filterRes': 0.4},
    ('sfx', 'Buzz'): {'osc1Wave': SAW, 'ampAttack': 5.0, 'ampDecay': 200.0, 'ampSustain': 0.3, 'ampRelease': 300.0, 'filterCutoff': 3000.0, 'filterRes': 0.5},
    ('sfx', 'Glitch'): {'osc1Wave': NOISE, 'ampAttack': 1.0, 'ampDecay': 50.0, 'ampSustain': 0.0, 'ampRelease': 80.0, 'filterCutoff': 10000.0, 'filterRes': 0.3},
    ('sfx', 'Stutter'): {'osc1Wave': SQUARE, 'ampAttack': 1.0, 'ampDecay': 60.0, 'ampSustain': 0.0, 'ampRelease': 80.0, 'filterCutoff': 8000.0, 'filterRes': 0.25, 'lfo1Target': 3, 'lfo1Depth': 0.8, 'lfo1Rate': 12.0},
    ('sfx', 'Reverse'): {'osc1Wave': SAW, 'ampAttack': 300.0, 'ampDecay': 100.0, 'ampSustain': 0.0, 'ampRelease': 50.0, 'filterCutoff': 5000.0, 'filterRes': 0.3},
    ('sfx', 'Morph'): {'osc1Wave': SAW, 'ampAttack': 30.0, 'ampDecay': 500.0, 'ampSustain': 0.4, 'ampRelease': 600.0, 'filterCutoff': 4000.0, 'filterRes': 0.4, 'lfo1Target': 2, 'lfo1Depth': 0.5, 'lfo1Rate': 0.3},
    ('sfx', 'Warp'): {'osc1Wave': SAW, 'ampAttack': 10.0, 'ampDecay': 400.0, 'ampSustain': 0.0, 'ampRelease': 500.0, 'filterCutoff': 2000.0, 'filterRes': 0.5, 'lfo1Target': 2, 'lfo1Depth': 0.7, 'lfo1Rate': 1.0},
    ('sfx', 'Portal'): {'osc1Wave': FM, 'ampAttack': 20.0, 'ampDecay': 600.0, 'ampSustain': 0.3, 'ampRelease': 800.0, 'filterCutoff': 6000.0, 'filterRes': 0.3},
    ('sfx', 'Beam'): {'osc1Wave': SAW, 'ampAttack': 2.0, 'ampDecay': 200.0, 'ampSustain': 0.0, 'ampRelease': 300.0, 'filterCutoff': 10000.0, 'filterRes': 0.4},
    ('sfx', 'Alarm'): {'osc1Wave': SQUARE, 'ampAttack': 5.0, 'ampDecay': 100.0, 'ampSustain': 0.8, 'ampRelease': 100.0, 'filterCutoff': 5000.0, 'filterRes': 0.3, 'lfo1Target': 1, 'lfo1Depth': 0.3, 'lfo1Rate': 5.0},
    ('sfx', 'Siren'): {'osc1Wave': SAW, 'ampAttack': 10.0, 'ampDecay': 200.0, 'ampSustain': 0.7, 'ampRelease': 200.0, 'filterCutoff': 6000.0, 'filterRes': 0.3, 'lfo1Target': 1, 'lfo1Depth': 0.5, 'lfo1Rate': 3.0},
}


def merge_profile(base, overrides):
    """Deep-merge overrides into base profile."""
    result = dict(base)
    for k, v in overrides.items():
        if k in result and isinstance(result[k], (int, float)) and isinstance(v, (int, float)):
            result[k] = result[k] + v if k in ('filterCutoff', 'brightness', 'ampAttack', 'ampRelease',
                                                  'filterRes', 'osc2Vol', 'sampleMix', 'osc1Uni', 'osc1Stereo') else v
        else:
            result[k] = v
    return result


def generate_preset(idx, name, category, variation_suffix, variation_overrides):
    """Generate a single PresetData aggregate initializer."""
    base = CATEGORY_PROFILES.get(category, CATEGORY_PROFILES['other'])

    # Apply per-preset overrides first
    preset_key = (category, name)
    preset_ovr = PRESET_OVERRIDES.get(preset_key, {})
    profile = merge_profile(base, preset_ovr)

    # Then apply variation overrides
    profile = merge_profile(profile, variation_overrides)

    # Clamp values
    profile['filterCutoff'] = max(100.0, min(20000.0, profile['filterCutoff']))
    profile['filterRes'] = max(0.0, min(0.95, profile['filterRes']))
    profile['ampAttack'] = max(0.5, profile['ampAttack'])
    profile['ampRelease'] = max(10.0, profile['ampRelease'])
    profile['brightness'] = max(0.0, min(1.0, profile.get('brightness', 0.0)))
    profile['sampleMix'] = max(0.0, min(1.0, profile['sampleMix']))
    profile['osc1Uni'] = max(1, min(16, profile['osc1Uni']))
    profile['osc1Stereo'] = max(0.0, min(1.0, profile['osc1Stereo']))
    profile['osc1Mix'] = max(0.0, min(1.0, profile['osc1Mix']))

    pid = f"juno-{idx:04d}"
    is_bass = 'true' if category in ('bass', 'synth_bass') else 'false'

    # LFO defaults
    lfo1_target = profile.get('lfo1Target', 0)
    lfo1_depth = profile.get('lfo1Depth', 0.3)
    lfo1_rate = profile.get('lfo1Rate', 4.0)

    lines = [
        f'        "{pid}", "{name}{variation_suffix}", "{category}",',
        # Osc 1
        f'        {profile["osc1Wave"]}, 0, 0.0, 0.50, {profile["osc1Vol"]:.2f}, 0, 0, 0.0, false, 0.0, {profile["osc1Uni"]}, {profile["osc1Det"]:.1f}, {profile["osc1Stereo"]:.1f}, {profile["osc1Mix"]:.1f},',
        # Osc 2
        f'        {profile["osc2Wave"]}, 0, 0.0, 0.50, {profile["osc2Vol"]:.2f}, 0, 0, 0.0, false, 0.0, {profile["osc2Uni"]}, {profile["osc2Det"]:.1f}, {profile["osc2Stereo"]:.1f}, {profile["osc2Mix"]:.1f},',
        # Osc mix
        f'        {profile["oscMix"]:.2f},',
        # Filter
        f'        {profile["filterType"]}, {profile["filterCutoff"]:.1f}, {profile["filterRes"]:.2f}, {profile["filterEnv"]:.2f}, {profile["filterKeyTrack"]:.1f}, {profile["filterDrive"]:.2f},',
        # Amp env
        f'        {profile["ampAttack"]:.1f}, {profile["ampDecay"]:.1f}, {profile["ampSustain"]:.2f}, {profile["ampRelease"]:.1f}, 0.0, 0.0, 0, 0, 0,',
        # Filter env
        f'        {profile["filterAttack"]:.1f}, {profile["filterDecay"]:.1f}, {profile["filterSustain"]:.2f}, {profile["filterRelease"]:.1f}, 0.0, 0.0, 0, 0, 0,',
        # Pitch env
        f'        0.0, 0.0, 0.00, 0.0, 0.00,',
        # LFO 1
        f'        0, {lfo1_rate:.2f}, {lfo1_depth:.2f}, {lfo1_target}, 0.0, false, 4,',
        # LFO 2
        f'        0, 4.00, 0.00, 0, 0.0, false, 4,',
        # Chorus
        f'        {str(profile["chorus"]).lower()}, 1.00, 0.30, 0.50,',
        # Delay
        f'        {str(profile["delay"]).lower()}, 400.0, 0.30, 0.30,',
        # Reverb
        f'        {str(profile["reverb"]).lower()}, 0.50, 0.50, 0.25,',
        # Phaser
        f'        false, 0.50, 0.50, 0.30, 0.30,',
        # Flanger
        f'        false, 0.30, 0.50, 0.30, 0.30,',
        # Compressor
        f'        false, -20.0, 4.0, 10.0, 100.0, 0.0,',
        # Drive
        f'        false, 0.30, 0,',
        # FX slots
        f'        {{0, 0, 0}}, {{false, false, false}}, {{ {{0.0, 0.0, 0.0, 0.0}}, {{0.0, 0.0, 0.0, 0.0}}, {{0.0, 0.0, 0.0, 0.0}} }},',
        # Master
        f'        0.80,',
        # sampleMix
        f'        {profile["sampleMix"]:.2f},',
        # isBass
        f'        {is_bass},',
        # Realism
        f'        {profile["bodyType"]}, {profile["bodyMix"]:.2f}, {profile["clickMix"]:.2f}, {profile["sympathetic"]:.2f}, {profile["attackCurve"]}, {profile["brightness"]:.2f},',
        # Arpeggiator
        f'        false, 0, 120.0, 0.50, 0.00, 1,',
        # Manifest
        f'        "{profile["manifest"]}"',
    ]
    return "\n".join(lines)


# ── Build preset list ─────────────────────────────────────────────────────────
PRESETS = []
idx = 1
for category, names in BASE_PRESETS.items():
    for name in names:
        for suffix, overrides in VARIATIONS:
            PRESETS.append((idx, name, category, suffix, overrides))
            idx += 1

# Target: 1338 presets (Juno-Di style)
target_count = 1338
if len(PRESETS) > target_count:
    PRESETS = PRESETS[:target_count]
while len(PRESETS) < target_count:
    base_idx = len(PRESETS) % len(PRESETS) if PRESETS else 0
    if PRESETS:
        _, base_name, base_cat, _, _ = PRESETS[base_idx]
        PRESETS.append((idx, base_name, base_cat, " Alt", {}))
        idx += 1
    else:
        break

# ── Generate header ───────────────────────────────────────────────────────────
parts = []
parts.append('#pragma once')
parts.append('#include "preset_data.h"')
parts.append('')
parts.append('namespace opensynth {')
parts.append('')
parts.append(f'inline constexpr int kNumFullPresets = {len(PRESETS)};')
parts.append('')
parts.append('inline constexpr PresetData kFullPresets[] = {')

for i, (preset_idx, name, cat, suffix, overrides) in enumerate(PRESETS):
    parts.append(generate_preset(preset_idx, name, cat, suffix, overrides))
    if i < len(PRESETS) - 1:
        parts[-1] += ','

parts.append('};')
parts.append('')
parts.append('} // namespace opensynth')

with open(OUTPUT, 'w') as f:
    f.write('\n'.join(parts))

print(f"Generated {len(PRESETS)} presets -> {OUTPUT}")
