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
      child: FintechWalletLensLogo(
        size: radius * 2,
        isAnimating: true,
      ),
    );
  }
}

class FintechWalletLensLogo extends StatefulWidget {
  final double size;
  final bool isAnimating;
  const FintechWalletLensLogo({
    super.key,
    this.size = 80,
    this.isAnimating = true,
  });

  @override
  State<FintechWalletLensLogo> createState() => _FintechWalletLensLogoState();
}

class _FintechWalletLensLogoState extends State<FintechWalletLensLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(FintechWalletLensLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating != oldWidget.isAnimating) {
      if (widget.isAnimating) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. The Wallet Base (Stationary)
          CustomPaint(
            size: Size(size, size),
            painter: WalletBasePainter(
              walletColor: AppColors.primaryForest,
              accentColor: AppColors.accentLime,
              isDark: isDark,
            ),
          ),
          
          // 2. The Camera Lens (Rotates)
          RotationTransition(
            turns: _controller,
            child: CustomPaint(
              size: Size(size * 0.45, size * 0.45),
              painter: CameraLensPainter(
                accentColor: AppColors.accentLime,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WalletBasePainter extends CustomPainter {
  final Color walletColor;
  final Color accentColor;
  final bool isDark;

  WalletBasePainter({
    required this.walletColor,
    required this.accentColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double w = size.width;
    final double h = size.height;

    // 1. Draw TWO slanted cards sticking out from the top (teal/accent green)
    // First card (back card, slightly more slanted/transparent or darker)
    paint.color = accentColor.withOpacity(0.7);
    final pathCard1 = Path();
    pathCard1.moveTo(w * 0.28, h * 0.3);
    pathCard1.lineTo(w * 0.45, h * 0.12);
    pathCard1.lineTo(w * 0.85, h * 0.25);
    pathCard1.lineTo(w * 0.68, h * 0.43);
    pathCard1.close();
    canvas.drawPath(pathCard1, paint);

    // Second card (front card, slightly overlapping, brighter)
    paint.color = accentColor;
    final pathCard2 = Path();
    pathCard2.moveTo(w * 0.2, h * 0.32);
    pathCard2.lineTo(w * 0.35, h * 0.16);
    pathCard2.lineTo(w * 0.75, h * 0.28);
    pathCard2.lineTo(w * 0.6, h * 0.44);
    pathCard2.close();
    canvas.drawPath(pathCard2, paint);

    // 2. Draw Wallet Main Body (forest green)
    paint.color = walletColor;
    final walletRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.1, h * 0.26, w * 0.8, h * 0.62),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(walletRRect, paint);

    // 3. Draw Wallet Flap / Strap (Right side)
    paint.color = const Color(0xFF011C13); // Darker shadow-like forest green
    final flapRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.72, h * 0.45, w * 0.18, h * 0.24),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(flapRRect, paint);

    // 4. Draw Flap Accent Lock/Button
    paint.color = accentColor;
    canvas.drawCircle(Offset(w * 0.81, h * 0.57), w * 0.035, paint);

    // 5. Border around Wallet outline
    paint
      ..color = accentColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018;
    canvas.drawRRect(walletRRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CameraLensPainter extends CustomPainter {
  final Color accentColor;

  CameraLensPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);

    // 1. Outer metallic ring
    paint.color = const Color(0xFF1E352F); // Metallic grey-green
    canvas.drawCircle(center, w * 0.5, paint);

    // 2. White outer highlights
    paint
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03;
    canvas.drawCircle(center, w * 0.46, paint);

    // 3. Middle dark body
    paint
      ..color = const Color(0xFF0F1A1C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, w * 0.4, paint);

    // 4. Accent ring inside lens
    paint
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035;
    canvas.drawCircle(center, w * 0.32, paint);

    // 5. Inner Glass Reflection (shiny deep green/cyan)
    paint
      ..color = const Color(0xFF03261D)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, w * 0.25, paint);

    // 6. Draw Aperture Blades (Lines creating rotation effect)
    paint
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025;
    
    final double r = w * 0.25;
    for (int i = 0; i < 4; i++) {
      final double angle = i * math.pi / 2;
      final dx1 = center.dx + r * math.cos(angle);
      final dy1 = center.dy + r * math.sin(angle);
      final dx2 = center.dx + r * 0.6 * math.cos(angle + 0.5);
      final dy2 = center.dy + r * 0.6 * math.sin(angle + 0.5);
      canvas.drawLine(Offset(dx1, dy1), Offset(dx2, dy2), paint);
    }

    // 7. Glass Glare reflection spots (makes it feel 3D and shiny)
    paint
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx - w * 0.08, center.dy - h * 0.08), w * 0.06, paint);
    canvas.drawCircle(Offset(center.dx + w * 0.1, center.dy + h * 0.1), w * 0.03, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
