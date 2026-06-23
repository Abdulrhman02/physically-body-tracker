import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class _Anchor {
  final BodyPart part;
  final Offset point;
  final bool labelLeft;
  const _Anchor(this.part, this.point, this.labelLeft);
}

class BodyDiagram extends StatelessWidget {
  final Map<BodyPart, Measurement?> latest;
  final Map<BodyPart, double?> deltas;
  final void Function(BodyPart) onTap;

  const BodyDiagram({
    super.key,
    required this.latest,
    required this.deltas,
    required this.onTap,
  });

  static const _anchors = <_Anchor>[
    _Anchor(BodyPart.neck, Offset(0.50, 0.12), true),
    _Anchor(BodyPart.shoulders, Offset(0.30, 0.20), true),
    _Anchor(BodyPart.chest, Offset(0.62, 0.27), false),
    _Anchor(BodyPart.leftBicep, Offset(0.27, 0.32), true),
    _Anchor(BodyPart.rightBicep, Offset(0.73, 0.32), false),
    _Anchor(BodyPart.leftForearm, Offset(0.22, 0.43), true),
    _Anchor(BodyPart.rightForearm, Offset(0.78, 0.43), false),
    _Anchor(BodyPart.waist, Offset(0.50, 0.40), true),
    _Anchor(BodyPart.hips, Offset(0.50, 0.50), false),
    _Anchor(BodyPart.leftThigh, Offset(0.42, 0.66), true),
    _Anchor(BodyPart.rightThigh, Offset(0.58, 0.66), false),
    _Anchor(BodyPart.leftCalf, Offset(0.42, 0.86), true),
    _Anchor(BodyPart.rightCalf, Offset(0.58, 0.86), false),
  ];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.6,
      child: LayoutBuilder(
        builder: (ctx, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _BodyPainter())),
              Positioned.fill(
                  child: CustomPaint(painter: _LeaderPainter(_anchors))),
              for (final a in _anchors) _tapTarget(a, size),
              for (final a in _anchors) _label(a, size),
            ],
          );
        },
      ),
    );
  }

  Widget _tapTarget(_Anchor a, Size size) {
    final left = a.point.dx * size.width - 18;
    final top = a.point.dy * size.height - 18;

    return Positioned(
      left: left,
      top: top,
      width: 36,
      height: 36,
      child: GestureDetector(
        onTap: () => onTap(a.part),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppTheme.muscle,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(_Anchor a, Size size) {
    final m = latest[a.part];
    final d = deltas[a.part];
    final value = m == null ? '—' : '${m.valueCm.toStringAsFixed(1)} cm';
    final delta =
        d == null ? null : '${d >= 0 ? '+' : ''}${d.toStringAsFixed(1)}cm';

    final py = a.point.dy * size.height;
    const labelW = 110.0;
    final left = a.labelLeft ? 4.0 : size.width - labelW - 4.0;

    return Positioned(
      left: left,
      top: py - 18,
      width: labelW,
      child: GestureDetector(
        onTap: () => onTap(a.part),
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment:
              a.labelLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (delta != null)
              Text(delta,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.muscle,
                      fontWeight: FontWeight.w600)),
            Text(value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            Text(a.part.label,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final outline = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final fill = Paint()
      ..color = Colors.grey.shade50
      ..style = PaintingStyle.fill;

    final w = s.width, h = s.height;
    final cx = w / 2;

    // Head
    final head =
        Rect.fromCircle(center: Offset(cx, h * 0.07), radius: w * 0.07);
    canvas.drawOval(head, fill);
    canvas.drawOval(head, outline);

    // Body silhouette
    final path = Path()
      ..moveTo(cx - w * 0.04, h * 0.13)
      ..lineTo(cx - w * 0.22, h * 0.18)
      ..lineTo(cx - w * 0.26, h * 0.30)
      ..lineTo(cx - w * 0.27, h * 0.45)
      ..lineTo(cx - w * 0.23, h * 0.50)
      ..lineTo(cx - w * 0.18, h * 0.46)
      ..lineTo(cx - w * 0.16, h * 0.32)
      ..lineTo(cx - w * 0.20, h * 0.45)
      ..lineTo(cx - w * 0.22, h * 0.55)
      ..lineTo(cx - w * 0.18, h * 0.75)
      ..lineTo(cx - w * 0.14, h * 0.95)
      ..lineTo(cx - w * 0.04, h * 0.97)
      ..lineTo(cx - w * 0.02, h * 0.55)
      ..lineTo(cx + w * 0.02, h * 0.55)
      ..lineTo(cx + w * 0.04, h * 0.97)
      ..lineTo(cx + w * 0.14, h * 0.95)
      ..lineTo(cx + w * 0.18, h * 0.75)
      ..lineTo(cx + w * 0.22, h * 0.55)
      ..lineTo(cx + w * 0.20, h * 0.45)
      ..lineTo(cx + w * 0.16, h * 0.32)
      ..lineTo(cx + w * 0.18, h * 0.46)
      ..lineTo(cx + w * 0.23, h * 0.50)
      ..lineTo(cx + w * 0.27, h * 0.45)
      ..lineTo(cx + w * 0.26, h * 0.30)
      ..lineTo(cx + w * 0.22, h * 0.18)
      ..lineTo(cx + w * 0.04, h * 0.13)
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, outline);

    // Section guides
    final guide = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.8;
    for (final y in [0.19, 0.25, 0.31, 0.41, 0.46, 0.53, 0.66, 0.86]) {
      canvas.drawLine(
        Offset(cx - w * 0.20, h * y),
        Offset(cx + w * 0.20, h * y),
        guide,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BodyPainter oldDelegate) => false;
}

class _LeaderPainter extends CustomPainter {
  final List<_Anchor> anchors;
  _LeaderPainter(this.anchors);

  @override
  void paint(Canvas canvas, Size s) {
    final paint = Paint()
      ..color = Colors.grey.shade500
      ..strokeWidth = 0.8;
    for (final a in anchors) {
      final p = Offset(a.point.dx * s.width, a.point.dy * s.height);
      final endX = a.labelLeft ? 118.0 : s.width - 118.0;
      canvas.drawLine(p, Offset(endX, p.dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LeaderPainter oldDelegate) => false;
}
