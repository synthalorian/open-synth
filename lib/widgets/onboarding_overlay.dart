import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import '../theme/synth_theme.dart';

/// Whether the user has completed onboarding.
final onboardingCompletedProvider = StateProvider<bool>((ref) {
  // Check Hive on first read
  final box = Hive.box('open_synth');
  return box.get('onboarding_completed', defaultValue: false) as bool;
});

/// Mark onboarding as completed.
Future<void> completeOnboarding(WidgetRef ref) async {
  final box = Hive.box('open_synth');
  await box.put('onboarding_completed', true);
  ref.read(onboardingCompletedProvider.notifier).state = true;
}

/// A step in the onboarding tour.
class _OnboardingStep {
  final String title;
  final String description;
  final IconData icon;

  const _OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Full-screen onboarding overlay that guides users through the synth.
///
/// Shows a series of step-by-step cards with a progress indicator.
/// The user taps "Next" or "Skip" to advance.
class OnboardingOverlay extends ConsumerStatefulWidget {
  const OnboardingOverlay({super.key});

  @override
  ConsumerState<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends ConsumerState<OnboardingOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const _steps = <_OnboardingStep>[
    _OnboardingStep(
      title: 'WELCOME TO OPEN SYNTH',
      description:
          'A neon-soaked, grid-powered software synthesizer. '
          'This quick tour will show you the essentials.\n\n'
          'Tap Next to begin or Skip to jump straight in.',
      icon: Icons.waving_hand,
    ),
    _OnboardingStep(
      title: 'OSCILLATORS',
      description:
          'Two oscillators (OSC 1 & OSC 2) generate the raw sound. '
          'Choose waveforms: Sine, Saw, Square, Triangle, Noise, or Wavetable. '
          'Adjust octave, detune, pulse width, and volume per oscillator.',
      icon: Icons.graphic_eq,
    ),
    _OnboardingStep(
      title: 'UNISON',
      description:
          'Stack up to 8 detuned voices per oscillator for massive, '
          'phat sounds. Adjust voice count, detune spread, stereo '
          'width, and blend with the dry signal.',
      icon: Icons.layers,
    ),
    _OnboardingStep(
      title: 'FILTER & ENVELOPES',
      description:
          'Shape your sound: the filter (LP/HP/BP/Notch) sculpts '
          'the tone. The Amp Envelope controls volume over time '
          '(Attack → Decay → Sustain → Release). The Filter Envelope '
          'modulates the filter cutoff.',
      icon: Icons.tune,
    ),
    _OnboardingStep(
      title: 'LFOs',
      description:
          'Two low-frequency oscillators (LFO 1 & LFO 2) add movement. '
          'Route them to pitch, filter, amplitude, or pan for wobbles, '
          'tremolo, vibrato, and auto-pan effects.',
      icon: Icons.waves,
    ),
    _OnboardingStep(
      title: 'FX & DRIVE',
      description:
          'Seven effects to polish your sound: Chorus, Delay, Reverb, '
          'Phaser, Flanger, Compressor, and Drive. Stack them for '
          'everything from subtle warmth to full sonic destruction.',
      icon: Icons.blur_on,
    ),
    _OnboardingStep(
      title: 'ARPEGGIATOR',
      description:
          'The arpeggiator turns held chords into rhythmic patterns. '
          'Choose Up, Down, Up/Down, Random, or Chord mode. Sync to '
          'MIDI clock or let it free-run.',
      icon: Icons.repeat,
    ),
    _OnboardingStep(
      title: 'SEQUENCER',
      description:
          'Built-in step sequencer with scale-quantized notes. '
          'Program up to 16 steps per track with adjustable velocity '
          'and gate. Perfect for bass lines and rhythmic patterns.',
      icon: Icons.grid_on,
    ),
    _OnboardingStep(
      title: 'MODULATION MATRIX',
      description:
          'Route modulation sources (LFO, Envelope, Mod Wheel, Velocity) '
          'to destinations (Pitch, Filter Cutoff, Pan, etc.) with '
          'adjustable amounts. Create evolving, animated patches.',
      icon: Icons.shuffle,
    ),
    _OnboardingStep(
      title: 'MACROS & MORPH',
      description:
          'Four assignable macro knobs control multiple parameters at '
          'once. The Morph panel lets you blend between two patches '
          'for dynamic sound transitions.',
      icon: Icons.timeline,
    ),
    _OnboardingStep(
      title: 'PERFORMANCE MODE',
      description:
          'Tap the fullscreen icon to enter Performance Mode — a '
          'streamlined view with an X/Y expression pad for real-time '
          'filter/resonance control. Great for live playing.',
      icon: Icons.fullscreen,
    ),
    _OnboardingStep(
      title: "YOU'RE READY!",
      description:
          'Start playing with the on-screen keyboard or connect a '
          'MIDI controller. Use the patch browser to explore factory '
          'presets, or hit the dice icon to randomize and discover '
          'something new.',
      icon: Icons.celebration,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _nextStep() {
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() {
          if (_currentStep < _steps.length - 1) {
            _currentStep++;
          }
        });
        _animController.forward();
      }
    });
  }

  void _prevStep() {
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() {
          if (_currentStep > 0) {
            _currentStep--;
          }
        });
        _animController.forward();
      }
    });
  }

  void _skip() {
    completeOnboarding(ref);
    Navigator.of(context).pop();
  }

  void _finish() {
    completeOnboarding(ref);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == _steps.length - 1;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: const Color(0xCC0A0018), // semi-transparent dark bg
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar: Skip + Progress ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    if (!isFirst)
                      GestureDetector(
                        onTap: _prevStep,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back,
                                color: SynthTheme.textSecondary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'BACK',
                              style: TextStyle(
                                color: SynthTheme.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(),
                    const Spacer(),
                    Text(
                      '${_currentStep + 1} / ${_steps.length}',
                      style: TextStyle(
                        color: SynthTheme.purple,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _skip,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: SynthTheme.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: SynthTheme.purple.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          'SKIP',
                          style: TextStyle(
                            color: SynthTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // ── Step content ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SynthTheme.magenta.withValues(alpha: 0.15),
                        border: Border.all(
                          color: SynthTheme.magenta.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: SynthTheme.magenta.withValues(alpha: 0.2),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Icon(
                        step.icon,
                        color: SynthTheme.magenta,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      step.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      step.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SynthTheme.textSecondary.withValues(alpha: 0.85),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // ── Progress dots ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (i) {
                  final isActive = i == _currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 24 : 8,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? SynthTheme.magenta
                          : SynthTheme.purple.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // ── Next / Finish button ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: GestureDetector(
                  onTap: isLast ? _finish : _nextStep,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isLast
                            ? [SynthTheme.magenta, SynthTheme.purple]
                            : [SynthTheme.cyan, SynthTheme.purple],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: (isLast
                                  ? SynthTheme.magenta
                                  : SynthTheme.cyan)
                              .withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Text(
                      isLast ? 'GET STARTED' : 'NEXT',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Sub text ──
              if (isLast)
                GestureDetector(
                  onTap: () {
                    completeOnboarding(ref);
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Or tap to go straight to the synth',
                      style: TextStyle(
                        color: SynthTheme.textSecondary.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  'Swipe up to dismiss or tap Skip to exit the tour',
                  style: TextStyle(
                    color: SynthTheme.textSecondary.withValues(alpha: 0.3),
                    fontSize: 10,
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
