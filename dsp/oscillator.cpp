#include "oscillator.h"
#include "wavetable_bank.h"
#include <cstdlib>
#include <algorithm>

namespace opensynth {

void Oscillator::setWaveform(int w) {
    // Map from Dart Waveform enum to internal OscWaveform enum.
    // Dart: sine(0), saw(1), square(2), triangle(3), noise(4), wavetable(5),
    //       wt_piano(6), wt_guitar(7), wt_choir(8), wt_brass(9), wt_strings(10),
    //       wt_woodwind(11), wt_organ(12), wt_bell(13), wt_synth_bass(14),
    //       wt_synth_lead(15), wt_pad(16), wt_epiano(17),
    //       pm_karplus(18), pm_karplus_bright(19), pm_karplus_bass(20),
    //       pm_modal_mallet(21), pm_modal_vibraphone(22), pm_modal_steel(23)
    // Internal: SAW(0), SQUARE(1), TRIANGLE(2), SINE(3), NOISE(4), PULSE(5),
    //           WT_PIANO(6), WT_GUITAR(7), WT_CHOIR(8), WT_BRASS(9), WT_STRINGS(10),
    //           WT_WOODWIND(11), WT_ORGAN(12), WT_BELL(13), WT_SYNTH_BASS(14),
    //           WT_SYNTH_LEAD(15), WT_PAD(16), WT_EPIANO(17),
    //           PM_KARPLUS(18), PM_KARPLUS_BRIGHT(19), PM_KARPLUS_BASS(20),
    //           PM_MODAL_MALLET(21), PM_MODAL_VIBRAPHONE(22), PM_MODAL_STEEL(23)
    static constexpr int dartToInternal[] = {
        3,  // Dart sine(0) → SINE
        0,  // Dart saw(1) → SAW
        1,  // Dart square(2) → SQUARE
        2,  // Dart triangle(3) → TRIANGLE
        4,  // Dart noise(4) → NOISE
        5,  // Dart wavetable(5) → PULSE (placeholder; use wavetable for 6+)
        6,  // Dart wt_piano(6) → WT_PIANO
        7,  // Dart wt_guitar(7) → WT_GUITAR
        8,  // Dart wt_choir(8) → WT_CHOIR
        9,  // Dart wt_brass(9) → WT_BRASS
        10, // Dart wt_strings(10) → WT_STRINGS
        11, // Dart wt_woodwind(11) → WT_WOODWIND
        12, // Dart wt_organ(12) → WT_ORGAN
        13, // Dart wt_bell(13) → WT_BELL
        14, // Dart wt_synth_bass(14) → WT_SYNTH_BASS
        15, // Dart wt_synth_lead(15) → WT_SYNTH_LEAD
        16, // Dart wt_pad(16) → WT_PAD
        17, // Dart wt_epiano(17) → WT_EPIANO
        18, // Dart pm_karplus(18) → PM_KARPLUS
        19, // Dart pm_karplus_bright(19) → PM_KARPLUS_BRIGHT
        20, // Dart pm_karplus_bass(20) → PM_KARPLUS_BASS
        21, // Dart pm_modal_mallet(21) → PM_MODAL_MALLET
        22, // Dart pm_modal_vibraphone(22) → PM_MODAL_VIBRAPHONE
        23, // Dart pm_modal_steel(23) → PM_MODAL_STEEL
    };

    int mapped;
    if (w >= 0 && w <= 23) {
        mapped = dartToInternal[w];
    } else {
        mapped = 3; // default to SINE
    }

    waveform_ = std::clamp(mapped, 0, 23);

    // Configure wavetable oscillator for wavetable types
    auto wf = static_cast<OscWaveform>(waveform_);
    if (wf >= OscWaveform::WT_PIANO && wf <= OscWaveform::WT_EPIANO) {
        int wtType = waveform_ - 6; // 0=piano, 1=guitar, ..., 11=epiano
        const Wavetable* wt = getBuiltinWavetable(wtType);
        wtOsc_.setWavetable(wt);
    }
}

void Oscillator::setOctave(int oct) { octave_ = std::clamp(oct, -2, 2); }
void Oscillator::setDetune(float cents) { detune_ = std::clamp(cents, -100.0f, 100.0f); }
void Oscillator::setPulseWidth(float pw) { pulseWidth_ = std::clamp(pw, 0.01f, 0.99f); }
void Oscillator::setVolume(float vol) { volume_ = std::clamp(vol, 0.0f, 1.0f); }

void Oscillator::setNoiseType(int nt) { noiseType_ = static_cast<NoiseType>(std::clamp(nt, 0, 2)); }

void Oscillator::setSubOscMode(int mode) { subOscMode_ = static_cast<SubOscMode>(std::clamp(mode, 0, 3)); }
void Oscillator::setSubOscVolume(float vol) { subOscVolume_ = std::clamp(vol, 0.0f, 1.0f); }

void Oscillator::setUnisonVoiceCount(int count) {
    unison_.voiceCount = std::clamp(count, 1, 8);
}
void Oscillator::setUnisonDetuneSpread(float cents) {
    unison_.detuneSpread = std::clamp(cents, 0.0f, 50.0f);
}
void Oscillator::setUnisonStereoSpread(float spread) {
    unison_.stereoSpread = std::clamp(spread, 0.0f, 1.0f);
}
void Oscillator::setUnisonMix(float mix) {
    unison_.mix = std::clamp(mix, 0.0f, 1.0f);
}

void Oscillator::reset() {
    // No state to reset besides parameters which stay as set
}

float Oscillator::voiceDetuneCents(int voiceIndex) const {
    if (voiceIndex == 0 || unison_.voiceCount <= 1) return 0.0f;
    // Spread unison voices across [-spread/2, +spread/2] cents
    int total = unison_.voiceCount - 1;
    float step = unison_.detuneSpread / total;
    return -unison_.detuneSpread * 0.5f + voiceIndex * step;
}

float Oscillator::voicePan(int voiceIndex) const {
    if (unison_.voiceCount <= 1) return 0.0f;
    // Stereo spread across unison voices
    int total = unison_.voiceCount - 1;
    if (total == 0) return 0.0f;
    float spread = unison_.stereoSpread;
    float pan = -spread * 0.5f + (voiceIndex / (float)total) * spread;
    return std::clamp(pan, -1.0f, 1.0f);
}

float Oscillator::phaseIncrement(float midiNoteFreq, int voiceIndex, double sampleRate) const {
    float detuneCents = detune_;
    if (voiceIndex > 0) {
        detuneCents += voiceDetuneCents(voiceIndex);
    }
    // Convert cents to frequency ratio: 2^(cents/1200)
    float ratio = std::pow(2.0f, detuneCents / 1200.0f);
    float octaveMult = std::pow(2.0f, (float)octave_);
    return (midiNoteFreq * octaveMult * ratio) / static_cast<float>(sampleRate);
}

float Oscillator::generateWaveform(float phase) const {
    // Wrap phase to [0, 1)
    phase = phase - std::floor(phase);

    switch (static_cast<OscWaveform>(waveform_)) {
    case OscWaveform::SAW:
        return 2.0f * phase - 1.0f;

    case OscWaveform::SQUARE:
        return phase < 0.5f ? 1.0f : -1.0f;

    case OscWaveform::TRIANGLE:
        return 4.0f * std::abs(phase - 0.5f) - 1.0f;

    case OscWaveform::SINE:
        return std::sin(2.0f * M_PI * phase);

    case OscWaveform::NOISE: {
        // Generate noise based on type
        switch (noiseType_) {
        case NoiseType::WHITE: {
            float hash = std::sin(phase * 12453.789f) * 43758.5453f;
            return 2.0f * (hash - std::floor(hash)) - 1.0f;
        }
        case NoiseType::PINK: {
            // Paul Kellet's refined pink noise approximation
            // Uses 6 white noise generators at different octaves
            float white = std::sin(phase * 12453.789f) * 43758.5453f;
            white = 2.0f * (white - std::floor(white)) - 1.0f;
            // Approximate pink by averaging with lower-frequency white noise
            float lowFreq = std::sin(phase * 0.125f * 12453.789f) * 43758.5453f;
            lowFreq = 2.0f * (lowFreq - std::floor(lowFreq)) - 1.0f;
            float midFreq = std::sin(phase * 0.5f * 12453.789f) * 43758.5453f;
            midFreq = 2.0f * (midFreq - std::floor(midFreq)) - 1.0f;
            return std::clamp((white * 0.5f + midFreq * 0.3f + lowFreq * 0.2f) * 1.4f, -1.0f, 1.0f);
        }
        case NoiseType::BROWN: {
            // Brown noise: integrate white noise (random walk approximation)
            float white = std::sin(phase * 12453.789f) * 43758.5453f;
            white = 2.0f * (white - std::floor(white)) - 1.0f;
            // Leaky integrator to approximate brown noise
            static float brownState = 0.0f;
            brownState = brownState * 0.99f + white * 0.01f;
            return std::clamp(brownState * 5.0f, -1.0f, 1.0f);
        }
        default:
            return 0.0f;
        }
    }

    case OscWaveform::PULSE:
        return phase < pulseWidth_ ? 1.0f : -1.0f;

    case OscWaveform::WT_GUITAR:
    case OscWaveform::WT_CHOIR:
    case OscWaveform::WT_BRASS:
    case OscWaveform::WT_STRINGS:
    case OscWaveform::WT_WOODWIND:
    case OscWaveform::WT_ORGAN:
    case OscWaveform::WT_BELL:
    case OscWaveform::WT_SYNTH_BASS:
    case OscWaveform::WT_SYNTH_LEAD:
    case OscWaveform::WT_PAD:
    case OscWaveform::WT_EPIANO: {
        float sample = wtOsc_.getSampleAtPhase(phase);
        return sample;
    }

    case OscWaveform::PM_KARPLUS:
    case OscWaveform::PM_KARPLUS_BRIGHT:
    case OscWaveform::PM_KARPLUS_BASS:
    case OscWaveform::PM_MODAL_MALLET:
    case OscWaveform::PM_MODAL_VIBRAPHONE:
    case OscWaveform::PM_MODAL_STEEL:
        // Physical models are rendered per-voice in synth_engine.cpp, not here.
        // This function is called for single-sample waveform lookup.
        // Return a placeholder sine to avoid silence if called directly.
        return std::sin(2.0f * M_PI * phase);

    case OscWaveform::WT_PIANO: {
        float base = wtOsc_.getSampleAtPhase(phase);
        // Inharmonicity: real piano strings are stiff, so overtones are slightly sharp.
        // Add a second partial at ~2.01x the fundamental with lower amplitude.
        float inharmonicPhase = phase * 2.01f;
        inharmonicPhase = inharmonicPhase - std::floor(inharmonicPhase);
        float overtone = wtOsc_.getSampleAtPhase(inharmonicPhase) * 0.25f;
        // Add a 3rd partial (slightly sharp as well)
        float overtone3Phase = phase * 3.02f;
        overtone3Phase = overtone3Phase - std::floor(overtone3Phase);
        float overtone3 = wtOsc_.getSampleAtPhase(overtone3Phase) * 0.12f;
        return base + overtone + overtone3;
    }
    }

    return 0.0f;
}

float Oscillator::process(float phase, int voiceIndex, float freq, double sampleRate) const {
    (void)sampleRate;
    float sample = generateWaveform(phase);

    // Sub-oscillator (square or sine below)
    if (subOscMode_ != SubOscMode::OFF && voiceIndex == 0) {
        float subDiv = 1.0f;
        float subFreq = freq;
        switch (subOscMode_) {
        case SubOscMode::SQUARE_1OCT:
            subDiv = 0.5f;
            subFreq = freq * 0.5f;
            break;
        case SubOscMode::SQUARE_2OCT:
            subDiv = 0.25f;
            subFreq = freq * 0.25f;
            break;
        case SubOscMode::SINE_1OCT:
            subDiv = 0.5f;
            subFreq = freq * 0.5f;
            break;
        default: break;
        }
        // Simple sub-osc: use phase (already independent per voice)
        float subPhase = phase * subDiv;
        subPhase = subPhase - std::floor(subPhase);
        float subSample = 0.0f;
        if (subOscMode_ == SubOscMode::SINE_1OCT) {
            subSample = std::sin(2.0f * M_PI * subPhase);
        } else {
            subSample = subPhase < 0.5f ? 1.0f : -1.0f;
        }
        sample = sample * (1.0f - subOscVolume_ * 0.7f) + subSample * subOscVolume_ * 0.7f;
    }

    // Apply unison mix: for voice 0 (main), blend dry/wet
    if (unison_.voiceCount > 1 && unison_.mix < 1.0f) {
        // Voice 0 = dry, voices 1+ = wet
        if (voiceIndex == 0) {
            sample *= (1.0f - unison_.mix);
        } else {
            sample *= unison_.mix / (float)(unison_.voiceCount - 1);
        }
    }

    return sample * volume_;
}

} // namespace opensynth
