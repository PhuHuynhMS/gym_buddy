import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({
    this.size = 44,
    this.foregroundColor = const Color(0xFFF05A5A),
    this.accentColor = const Color(0xFFF2B84B),
    this.connectionColor = const Color(0xFF16A34A),
    super.key,
  });

  final double size;
  final Color foregroundColor;
  final Color accentColor;
  final Color connectionColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _BrandMarkPainter(
          foregroundColor: foregroundColor,
          accentColor: accentColor,
          connectionColor: connectionColor,
        ),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter({
    required this.foregroundColor,
    required this.accentColor,
    required this.connectionColor,
  });

  final Color foregroundColor;
  final Color accentColor;
  final Color connectionColor;

  @override
  void paint(Canvas canvas, Size size) {
    final heartPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.fill;
    final barPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.085;
    final connectionPaint = Paint()
      ..color = connectionColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.055;

    final heart = Path()
      ..moveTo(size.width * 0.50, size.height * 0.83)
      ..cubicTo(
        size.width * 0.11,
        size.height * 0.56,
        size.width * 0.10,
        size.height * 0.27,
        size.width * 0.30,
        size.height * 0.20,
      )
      ..cubicTo(
        size.width * 0.41,
        size.height * 0.16,
        size.width * 0.49,
        size.height * 0.22,
        size.width * 0.50,
        size.height * 0.33,
      )
      ..cubicTo(
        size.width * 0.51,
        size.height * 0.22,
        size.width * 0.59,
        size.height * 0.16,
        size.width * 0.70,
        size.height * 0.20,
      )
      ..cubicTo(
        size.width * 0.90,
        size.height * 0.27,
        size.width * 0.89,
        size.height * 0.56,
        size.width * 0.50,
        size.height * 0.83,
      )
      ..close();

    canvas.drawPath(heart, heartPaint);

    final y = size.height * 0.50;
    canvas.drawLine(
      Offset(size.width * 0.20, y),
      Offset(size.width * 0.80, y),
      barPaint,
    );

    _drawPlate(canvas, Offset(size.width * 0.13, y), size, barPaint);
    _drawPlate(canvas, Offset(size.width * 0.87, y), size, barPaint);

    final connection = Path()
      ..moveTo(size.width * 0.34, size.height * 0.40)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.28,
        size.width * 0.66,
        size.height * 0.40,
      );
    canvas.drawPath(connection, connectionPaint);

    _drawPerson(
      canvas,
      center: Offset(size.width * 0.32, size.height * 0.42),
      size: size,
      fillColor: const Color(0xFF60A5FA),
    );
    _drawPerson(
      canvas,
      center: Offset(size.width * 0.68, size.height * 0.42),
      size: size,
      fillColor: const Color(0xFFF9A8D4),
    );
  }

  void _drawPlate(Canvas canvas, Offset center, Size size, Paint paint) {
    final plateHeight = size.height * 0.25;
    final gap = size.width * 0.055;
    canvas
      ..drawLine(
        Offset(center.dx - gap, center.dy - plateHeight / 2),
        Offset(center.dx - gap, center.dy + plateHeight / 2),
        paint,
      )
      ..drawLine(
        Offset(center.dx + gap, center.dy - plateHeight / 2),
        Offset(center.dx + gap, center.dy + plateHeight / 2),
        paint,
      );
  }

  void _drawPerson(
    Canvas canvas, {
    required Offset center,
    required Size size,
    required Color fillColor,
  }) {
    final headPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final bodyPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.045;
    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.018;

    final radius = size.width * 0.075;
    canvas
      ..drawCircle(center, radius, headPaint)
      ..drawCircle(center, radius, outlinePaint)
      ..drawLine(
        Offset(center.dx, center.dy + radius),
        Offset(center.dx, center.dy + size.height * 0.24),
        bodyPaint,
      );
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) {
    return oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.connectionColor != connectionColor;
  }
}
