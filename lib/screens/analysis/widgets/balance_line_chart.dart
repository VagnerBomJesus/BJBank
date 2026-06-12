import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

/// Smooth blue line chart (UI-kit "Statistics" style) plotting one value per
/// month, with a highlighted point for the selected month.
class BalanceLineChart extends StatelessWidget {
  const BalanceLineChart({
    super.key,
    required this.values,
    required this.selectedIndex,
    this.height = 190,
  });

  final List<double> values;
  final int selectedIndex;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _LineChartPainter(
          values: values,
          selectedIndex: selectedIndex,
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.values, required this.selectedIndex});

  final List<double> values;
  final int selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const double topPad = 16;
    const double bottomPad = 16;
    final chartH = size.height - topPad - bottomPad;

    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);

    // Faint horizontal grid
    final gridPaint = Paint()
      ..color = BJBankColors.outlineVariant.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = topPad + chartH * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Build points
    final points = <Offset>[];
    final n = values.length;
    for (int i = 0; i < n; i++) {
      final x = n == 1 ? size.width / 2 : size.width * (i / (n - 1));
      final norm = (values[i] - minV) / range;
      final y = topPad + chartH * (1 - norm);
      points.add(Offset(x, y));
    }

    // Smooth path (quadratic through midpoints)
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 1) {
      linePath.lineTo(points.first.dx, points.first.dy);
    } else {
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        linePath.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      }
      linePath.lineTo(points.last.dx, points.last.dy);
    }

    // Gradient fill under the line
    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          BJBankColors.accentBlue.withValues(alpha: 0.28),
          BJBankColors.accentBlue.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = BJBankColors.accentBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Highlighted selected point
    if (selectedIndex >= 0 && selectedIndex < points.length) {
      final sp = points[selectedIndex];
      // vertical guide
      final guide = Paint()
        ..color = BJBankColors.accentBlue.withValues(alpha: 0.25)
        ..strokeWidth = 1.5;
      canvas.drawLine(
          Offset(sp.dx, topPad), Offset(sp.dx, size.height), guide);
      // outer ring + inner dot
      canvas.drawCircle(sp, 9, Paint()..color = BJBankColors.surface);
      canvas.drawCircle(
          sp,
          9,
          Paint()
            ..color = BJBankColors.accentBlue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
      canvas.drawCircle(sp, 4, Paint()..color = BJBankColors.accentBlue);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.values != values || old.selectedIndex != selectedIndex;
}
