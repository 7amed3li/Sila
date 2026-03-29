import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sila_app/core/services/isar_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final AnimationController _rotationController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _rotationAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _rotationAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.25), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.25, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut));

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await Future.wait<void>([
      _scaleController.forward(),
      _fadeController.forward(),
      _rotationController.forward(),
      // Warm up Isar database during splash
      IsarService().db,
    ]);

    await Future<void>.delayed(const Duration(milliseconds: 200));

    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // Parchment background from design system
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: AnimatedBuilder(
                animation: _rotationAnim,
                builder: (context, child) {
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Perspective
                      ..rotateY(_rotationAnim.value),
                    alignment: Alignment.center,
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 220,
                  height: 220,
                  errorBuilder: (_, __, ___) => Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mosque_rounded,
                        size: 56, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Removed redundant app_name text since it's already in the logo
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                'app_tagline'.tr(), // رفيقك في العبادة
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: const Color(0xFF064E3B), // Emerald Deep
                ),
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: const Color(0xFF064E3B), // Emerald Deep
              ),
            ),
          ],
        ),
      ),
    );
  }
}
