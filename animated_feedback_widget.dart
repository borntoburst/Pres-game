import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/app_theme.dart';
import '../utils/score_provider.dart';

/// Overlay shown when a level is completed.
/// Displays animated stars, score, and action buttons.
class AnimatedFeedbackWidget extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final String message;
  final int points;

  const AnimatedFeedbackWidget({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onReplay,
    required this.message,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        if (controller.value == 0) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryYellow.withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Confetti-like star burst
              _StarBurst(controller: controller),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '+$points điểm!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryOrange,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReplay,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Lại'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                        foregroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      label: const Text(
                        'Tiếp theo',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Animated star particles for celebration.
class _StarBurst extends StatelessWidget {
  final AnimationController controller;
  const _StarBurst({required this.controller});

  @override
  Widget build(BuildContext context) {
    const stars = ['⭐', '🌟', '✨', '⭐', '🌟', '✨', '⭐', '🌟'];
    return SizedBox(
      height: 80,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: List.generate(stars.length, (i) {
            final angle = (i / stars.length) * 2 * pi;
            final delay = (i / stars.length) * 0.4;
            final t = Curves.easeOut
                .transform(((controller.value - delay).clamp(0.0, 1.0)));
            final radius = t * 60;
            return Transform.translate(
              offset: Offset(cos(angle) * radius, sin(angle) * radius),
              child: Opacity(
                opacity: t * (1 - t * 0.5),
                child: Text(stars[i],
                    style: TextStyle(fontSize: 16 + t * 8)),
              ),
            );
          }),
        ),
      ),
    );
  }
}
