import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class NotebookBackground extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const NotebookBackground({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NotebookPaperPainter(),
      child: Padding(padding: padding, child: child),
    );
  }
}

class NotebookSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool showBinding;

  const NotebookSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.showBinding = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperSurface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.leather.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.leather.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _SheetLinePainter())),
          if (showBinding)
            Positioned(
              left: 0,
              top: 18,
              bottom: 18,
              child: Container(width: 5, color: AppColors.leather.withValues(alpha: 0.24)),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class RecordSlip extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const RecordSlip({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.paperSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.leather.withValues(alpha: 0.16)),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: content,
    );
  }
}

class LabStamp extends StatelessWidget {
  final String label;
  final Color color;

  const LabStamp({
    super.key,
    required this.label,
    this.color = AppColors.leather,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: color,
        fontFamily: 'SpaceGrotesk',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class SparkMark extends StatelessWidget {
  final double size;
  final Color color;

  const SparkMark({
    super.key,
    this.size = 42,
    this.color = AppColors.leather,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SparkMarkPainter(color)),
    );
  }
}

class _NotebookPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(AppColors.paper, BlendMode.src);
    final linePaint = Paint()
      ..color = AppColors.paperLine.withValues(alpha: 0.12)
      ..strokeWidth = 0.6;
    for (double y = 0; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SheetLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.paperLine.withValues(alpha: 0.24)
      ..strokeWidth = 0.7;
    for (double y = 58; y < size.height - 18; y += 42) {
      canvas.drawLine(Offset(18, y), Offset(size.width - 18, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SparkMarkPainter extends CustomPainter {
  final Color color;
  const _SparkMarkPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width * 0.34, paint);
    canvas.drawCircle(center, size.width * 0.2, paint);
    for (var i = 0; i < 6; i++) {
      final a = (math.pi * 2 / 6) * i - math.pi / 2;
      canvas.drawLine(
        center,
        center + Offset(math.cos(a), math.sin(a)) * size.width * 0.36,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparkMarkPainter oldDelegate) => oldDelegate.color != color;
}
