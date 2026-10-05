import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Shown when the app needs the user's location for the Maps feature.
/// Follows the traveltales_location_permission UI reference.
///
/// This is a UI-only widget — the actual platform permission request is
/// triggered by the parent [MapsScreen] after the user taps "Allow".
class LocationPermissionScreen extends StatelessWidget {
  /// Called when user taps "Allow" — parent requests the actual permission.
  final VoidCallback onAllow;

  /// Called when user taps "Not Now" — parent continues without location.
  final VoidCallback onDeny;

  const LocationPermissionScreen({
    super.key,
    required this.onAllow,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) onDeny();
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
            children: [
              const Spacer(flex: 3),
              // Illustration circle
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _MapWithPinIcon(),
                ),
              ),
              const SizedBox(height: 40),
              // Title
              const Text(
                'Allow Location Access',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Subtitle
              const Text(
                'We need your location to show nearby places and guides.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.muted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 4),
              // Allow button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: onAllow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Allow',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Not Now button
              GestureDetector(
                onTap: onDeny,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Not Now',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}
}

/// Folded-map-with-pin icon matching the UI reference illustration.
class _MapWithPinIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(96, 96),
      painter: _MapPinPainter(),
    );
  }
}

class _MapPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryTeal
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Map outline (folded map trapezoid)
    final mapPath = Path()
      ..moveTo(w * 0.1, h * 0.28)
      ..lineTo(w * 0.38, h * 0.16)
      ..lineTo(w * 0.62, h * 0.28)
      ..lineTo(w * 0.90, h * 0.16)
      ..lineTo(w * 0.90, h * 0.80)
      ..lineTo(w * 0.62, h * 0.92)
      ..lineTo(w * 0.38, h * 0.80)
      ..lineTo(w * 0.10, h * 0.92)
      ..close();
    canvas.drawPath(mapPath, paint);

    // Fold lines
    canvas.drawLine(Offset(w * 0.38, h * 0.16), Offset(w * 0.38, h * 0.80), paint);
    canvas.drawLine(Offset(w * 0.62, h * 0.28), Offset(w * 0.62, h * 0.92), paint);

    // Dashed route lines on centre panel
    final dashPaint = Paint()
      ..color = AppColors.primaryTeal.withValues(alpha: 0.5)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawDashedLine(canvas,
        Offset(w * 0.44, h * 0.55), Offset(w * 0.56, h * 0.55), dashPaint, 4, 3);
    _drawDashedLine(canvas,
        Offset(w * 0.44, h * 0.65), Offset(w * 0.56, h * 0.65), dashPaint, 4, 3);

    // Location pin on centre panel
    final pinFill = Paint()
      ..color = AppColors.primaryTeal
      ..style = PaintingStyle.fill;
    final pinPath = Path()
      ..moveTo(w * 0.50, h * 0.30)
      ..arcToPoint(Offset(w * 0.50 - w * 0.10, h * 0.38),
          radius: Radius.circular(w * 0.10), clockwise: false)
      ..arcToPoint(Offset(w * 0.50, h * 0.50),
          radius: Radius.circular(w * 0.10), clockwise: false)
      ..arcToPoint(Offset(w * 0.50 + w * 0.10, h * 0.38),
          radius: Radius.circular(w * 0.10), clockwise: false)
      ..arcToPoint(Offset(w * 0.50, h * 0.30),
          radius: Radius.circular(w * 0.10), clockwise: false);
    canvas.drawPath(pinPath, pinFill);

    // White dot inside pin
    canvas.drawCircle(Offset(w * 0.50, h * 0.38),
        w * 0.035, Paint()..color = Colors.white..style = PaintingStyle.fill);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end,
      Paint paint, double dashWidth, double dashSpace) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = (end - start).distance;
    var drawn = 0.0;
    var drawDash = true;
    while (drawn < length) {
      final segLen = drawDash ? dashWidth : dashSpace;
      final frac = (drawn + segLen) / length;
      final to =
          Offset(start.dx + dx * frac.clamp(0.0, 1.0),
              start.dy + dy * frac.clamp(0.0, 1.0));
      if (drawDash) {
        canvas.drawLine(
            Offset(start.dx + dx * (drawn / length),
                start.dy + dy * (drawn / length)),
            to,
            paint);
      }
      drawn += segLen;
      drawDash = !drawDash;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
