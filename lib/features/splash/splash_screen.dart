import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Cinematic splash with staged reveal.
///
/// Navigation is gated on the animation controller completing, not a raw
/// timer. This prevents the "blank black screen" bug when the UI thread
/// is blocked during debug startup: the animation simply pauses and
/// resumes, then exits cleanly once it has actually played.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _totalDuration = Duration(milliseconds: 3500);
  static const _minimumDisplay = Duration(milliseconds: 3500);

  // Staged intervals — same choreography, stretched across more time
  static const _emblemStart = 0.0;
  static const _emblemEnd = 0.23; // was 0.35 → now ~800ms
  static const _wordmarkStart = 0.14; // was 0.20 → now ~500ms
  static const _wordmarkEnd = 0.40; // was 0.55 → now ~900ms
  static const _taglineStart = 0.30; // was 0.40 → now ~1050ms
  static const _taglineEnd = 0.50; // was 0.70 → now ~1750ms
  static const _exitStart = 0.86; // was 0.87 → now ~3000ms
  static const _exitEnd = 1.0; // exit runs ~500ms

  late final AnimationController _controller;

  late final Animation<double> _emblemOpacity;
  late final Animation<double> _emblemScale;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<Offset> _wordmarkOffset;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _exitScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _totalDuration,
    );

    // Emblem: fade + scale in
    final emblemCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        _emblemStart,
        _emblemEnd,
        curve: Curves.easeOutCubic,
      ),
    );
    _emblemOpacity = emblemCurve;
    _emblemScale = Tween<double>(begin: 0.85, end: 1.0).animate(emblemCurve);

    // Wordmark: fade + slide up
    final wordmarkCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        _wordmarkStart,
        _wordmarkEnd,
        curve: Curves.easeOutCubic,
      ),
    );
    _wordmarkOpacity = wordmarkCurve;
    _wordmarkOffset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(wordmarkCurve);

    // Tagline: fade in
    _taglineOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        _taglineStart,
        _taglineEnd,
        curve: Curves.easeOut,
      ),
    );

    // Exit: fade out + subtle zoom
    final exitCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        _exitStart,
        _exitEnd,
        curve: Curves.easeInCubic,
      ),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(exitCurve);
    _exitScale = Tween<double>(begin: 1.0, end: 1.04).animate(exitCurve);

    _run();
  }

  Future<void> _run() async {
    final stopwatch = Stopwatch()..start();

    // Await actual frame delivery. If the UI thread is blocked (debug
    // attach, heavy init), the ticker pauses and this future stays
    // pending until frames flow again.
    await _controller.forward();

    // Enforce minimum branding exposure even if the animation finished
    // faster than expected.
    final remaining = _minimumDisplay - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (!mounted) return;

    // Replace the stack so the user can never navigate back to splash.
    context.go('/diary');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _exitOpacity.value,
            child: Transform.scale(
              scale: _exitScale.value,
              child: child,
            ),
          );
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emblem
              FadeTransition(
                opacity: _emblemOpacity,
                child: ScaleTransition(
                  scale: _emblemScale,
                  child: Image.asset(
                    'assets/branding/emblem.png',
                    width: 110,
                    cacheWidth: 330,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('SPLASH EMBLEM ERROR: $error');
                      return const SizedBox(width: 110, height: 110);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Wordmark
              FadeTransition(
                opacity: _wordmarkOpacity,
                child: SlideTransition(
                  position: _wordmarkOffset,
                  child: Image.asset(
                    'assets/branding/wordmark.png',
                    width: 260,
                    cacheWidth: 780,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('SPLASH WORDMARK ERROR: $error');
                      return const SizedBox(width: 260, height: 60);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Tagline
              FadeTransition(
                opacity: _taglineOpacity,
                child: Image.asset(
                  'assets/branding/tagline.png',
                  width: 220,
                  cacheWidth: 660,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('SPLASH TAGLINE ERROR: $error');
                    return const SizedBox(width: 220, height: 40);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
