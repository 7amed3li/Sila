import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class TasmiListeningIndicator extends StatefulWidget {
  const TasmiListeningIndicator({super.key, required this.isListening});
  final bool isListening;

  @override
  State<TasmiListeningIndicator> createState() =>
      _TasmiListeningIndicatorState();
}

class _TasmiListeningIndicatorState extends State<TasmiListeningIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) {
          controller.repeat(reverse: true);
        }
      });
      return controller;
    });

    _animations = _controllers
        .map(
          (controller) => Tween<double>(begin: 0.3, end: 1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: widget.isListening
          ? Container(
              key: const ValueKey('listening'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(
                    3,
                    (i) => AnimatedBuilder(
                      animation: _animations[i],
                      builder: (_, __) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green
                              .withValues(alpha: _animations[i].value),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'tasmi_indicator_listening'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Cairo',
                      color: isDark ? Colors.green[300] : Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              key: const ValueKey('paused'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic_off_rounded,
                      size: 16,
                      color: isDark ? Colors.white54 : Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'tasmi_indicator_paused'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
