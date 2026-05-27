import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/synth_theme.dart';

/// Animated retro synthwave splash screen with a neon grid animation,
/// pulsating logo, and a subtle "loading" simulation before entering the app.
class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _logoScale;
  late Animation<double> _subtitleFade;
  late Animation<double> _powerUpSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.7, curve: Curves.easeIn)),
    );

    _powerUpSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.85, curve: Curves.easeOutCubic)),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SynthTheme.bg,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              // Animated background grid
              CustomPaint(
                painter: _SplashGridPainter(
                  progress: _controller.value,
                  fadeAlpha: _fadeIn.value,
                ),
                size: Size.infinite,
              ),

              // Scanline overlay
              IgnorePointer(
                child: CustomPaint(
                  painter: _SplashScanlinePainter(),
                  size: Size.infinite,
                ),
              ),

              // Central content
              Center(
                child: Opacity(
                  opacity: _fadeIn.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo / Icon
                      Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: SynthTheme.magenta.withValues(alpha: 0.6),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: SynthTheme.magenta.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.music_note,
                            size: 50,
                            color: SynthTheme.magenta.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        'OPEN SYNTH',
                        style: GoogleFonts.orbitron(
                          color: SynthTheme.magenta,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                          shadows: [
                            Shadow(
                              color: SynthTheme.magenta.withValues(alpha: 0.5),
                              blurRadius: 15,
                            ),
                            Shadow(
                              color: SynthTheme.purple.withValues(alpha: 0.3),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tagline
                      Opacity(
                        opacity: _subtitleFade.value,
                        child: Transform.translate(
                          offset: Offset(0, _powerUpSlide.value),
                          child: Column(
                            children: [
                              Text(
                                'SOFTWARE SYNTHESIZER',
                                style: TextStyle(
                                  color: SynthTheme.cyan.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '⚡ POWERING UP THE GRID ⚡',
                                style: TextStyle(
                                  color: SynthTheme.purple.withValues(alpha: 0.6),
                                  fontSize: 9,
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Loading bar
                      Opacity(
                        opacity: _subtitleFade.value,
                        child: SizedBox(
                          width: 200,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: (_controller.value * 1.1).clamp(0.0, 1.0),
                              backgroundColor: SynthTheme.surface,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                SynthTheme.magenta.withValues(alpha: 0.8),
                              ),
                              minHeight: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Status text
                      Opacity(
                        opacity: _subtitleFade.value,
                        child: Text(
                          _statusText(_controller.value),
                          style: TextStyle(
                            color: SynthTheme.textSecondary.withValues(alpha: 0.5),
                            fontSize: 9,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Corner decorations
              Positioned(
                top: 20,
                left: 20,
                child: Opacity(
                  opacity: _fadeIn.value * 0.3,
                  child: Text('// SYSTEM', style: TextStyle(color: SynthTheme.purple, fontSize: 8, letterSpacing: 2)),
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: Opacity(
                  opacity: _fadeIn.value * 0.3,
                  child: Text('v1.2.0 //', style: TextStyle(color: SynthTheme.purple, fontSize: 8, letterSpacing: 2)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _statusText(double progress) {
    if (progress < 0.2) return 'INITIALIZING DSP ENGINE...';
    if (progress < 0.4) return 'LOADING WAVETABLES...';
    if (progress < 0.6) return 'CALIBRATING FILTERS...';
    if (progress < 0.8) return 'SYNCING TO THE GRID...';
    return 'READY';
  }
}

class _SplashGridPainter extends CustomPainter {
  final double progress;
  final double fadeAlpha;

  _SplashGridPainter({required this.progress, required this.fadeAlpha});

  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.65;
    final scroll = progress * 120.0;

    // Horizon line with glow
    final horizonPaint = Paint()
      ..color = SynthTheme.magenta.withValues(alpha: 0.2 * fadeAlpha)
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawLine(Offset(0, horizonY), Offset(size.width, horizonY), horizonPaint);

    // Perspective vertical lines
    final centerX = size.width / 2;
    final vertPaint = Paint()
      ..color = SynthTheme.purple.withValues(alpha: 0.15 * fadeAlpha)
      ..strokeWidth = 1;

    for (int i = -12; i <= 12; i++) {
      if (i == 0) continue;
      final topX = centerX + i * 10.0;
      final spread = i.abs() * 50.0;
      final bottomX = centerX + spread * (i > 0 ? 1 : -1);
      canvas.drawLine(Offset(topX, horizonY), Offset(bottomX, size.height), vertPaint);
    }

    // Scrolling horizontal lines
    final horzPaint = Paint()
      ..color = SynthTheme.purple.withValues(alpha: 0.1 * fadeAlpha)
      ..strokeWidth = 1;

    for (int i = 0; i < 20; i++) {
      final y = horizonY + pow(i + scroll / 60, 2).toDouble() * 3.0;
      if (y > size.height) continue;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), horzPaint);
    }

    // Sun at horizon (synthwave sunrise)
    final sunCenter = Offset(centerX, horizonY + 20);
    final sunRadius = 40.0;

    // Sun glow
    final sunGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          SynthTheme.magenta.withValues(alpha: 0.3 * fadeAlpha),
          SynthTheme.orange.withValues(alpha: 0.15 * fadeAlpha),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius * 3));
    canvas.drawCircle(sunCenter, sunRadius * 3, sunGlow);

    // Sun body
    final sunBody = Paint()
      ..shader = RadialGradient(
        colors: [
          SynthTheme.orange.withValues(alpha: 0.6 * fadeAlpha),
          SynthTheme.magenta.withValues(alpha: 0.4 * fadeAlpha),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));
    canvas.drawCircle(sunCenter, sunRadius, sunBody);

    // Sun horizontal stripe (synthwave horizon cut)
    final cutPaint = Paint()..color = SynthTheme.bg;
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.width, 2),
      cutPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SplashGridPainter old) => true;
}

class _SplashScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.04);
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashScanlinePainter old) => false;
}
