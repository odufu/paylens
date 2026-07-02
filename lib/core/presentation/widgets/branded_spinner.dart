import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mspay/core/constants/app_colors.dart';

class AnimatedLogoBorder extends StatefulWidget {
  final Widget child;
  final double scale;
  const AnimatedLogoBorder({super.key, required this.child, this.scale = 1.0});

  @override
  State<AnimatedLogoBorder> createState() => _AnimatedLogoBorderState();
}

class _AnimatedLogoBorderState extends State<AnimatedLogoBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _controller.value * 2.0 * math.pi;
        final pulse = 1.0 + 0.12 * math.sin(angle);
        final glow = 1.0 + 3.0 * (0.5 + 0.5 * math.sin(angle * 2.0));
        
        return Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: pulse,
            child: Container(
              padding: EdgeInsets.all(24 * widget.scale),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentLime.withOpacity(0.04 * glow),
                    blurRadius: 8.0 * glow * widget.scale,
                    spreadRadius: 1.0 * glow * widget.scale,
                  ),
                ],
                border: Border.all(
                  color: AppColors.accentLime.withOpacity(0.1 + (0.15 * (glow / 4.0))),
                  width: (1.25 + (1.0 * (glow / 4.0))) * widget.scale,
                ),
              ),
              child: Transform.rotate(
                angle: -angle, // Keep the inner child logo perfectly upright
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class BrandedSpinner extends StatelessWidget {
  final double radius;
  const BrandedSpinner({super.key, this.radius = 28});

  @override
  Widget build(BuildContext context) {
    final scale = radius / 40.0;
    return AnimatedLogoBorder(
      scale: scale,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.transparent,
        backgroundImage: const AssetImage('assets/images/logo.png'),
      ),
    );
  }
}

class BrandedLoadingOverlay {
  static void show(BuildContext context, {String message = 'Processing...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Center(
              child: BrandedSpinner(radius: 28),
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

class FailureDialog extends StatelessWidget {
  final String title;
  final String message;
  final String ticketId;

  const FailureDialog({
    super.key,
    required this.title,
    required this.message,
    required this.ticketId,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    required String ticketId,
  }) {
    showDialog(
      context: context,
      builder: (context) => FailureDialog(
        title: title,
        message: message,
        ticketId: ticketId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF161E1A) : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.textDark;
    
    return AlertDialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(
        Icons.error_outline_rounded,
        color: Colors.redAccent,
        size: 48,
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: titleColor),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
            ),
            child: Text(
              'Support Ticket: $ticketId',
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryForest)),
        ),
      ],
    );
  }
}
