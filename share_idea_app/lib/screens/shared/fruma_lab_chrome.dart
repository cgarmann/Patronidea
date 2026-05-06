import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class FrumaLabBackground extends StatefulWidget {
  final Widget child;
  final bool motion;
  final double intensity;

  const FrumaLabBackground({
    super.key,
    required this.child,
    this.motion = true,
    this.intensity = 1,
  });

  @override
  State<FrumaLabBackground> createState() => _FrumaLabBackgroundState();
}

class _FrumaLabBackgroundState extends State<FrumaLabBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    );
    if (widget.motion) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant FrumaLabBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.motion && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.motion && _controller.isAnimating) {
      _controller.stop();
    }
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
      builder: (context, _) {
        final phase = widget.motion ? _controller.value : 0.0;
        return Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: AppColors.volcanic950),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _WeavePatternPainter(
                  phase: phase,
                  intensity: widget.intensity,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      math.sin(phase * math.pi * 2) * 0.18,
                      -0.28 + math.cos(phase * math.pi * 2) * 0.08,
                    ),
                    radius: 1.08,
                    colors: [
                      AppColors.terracotta
                          .withValues(alpha: 0.11 * widget.intensity),
                      AppColors.patinaTeal
                          .withValues(alpha: 0.04 * widget.intensity),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.42, 1],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.32),
                    ],
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

class FrumaLabHeader extends StatelessWidget {
  final String activeMode;
  final VoidCallback? onInnovator;
  final VoidCallback? onPatron;

  const FrumaLabHeader({
    super.key,
    required this.activeMode,
    this.onInnovator,
    this.onPatron,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 44,
        constraints: const BoxConstraints(maxWidth: 370),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: const LinearGradient(
                  colors: [AppColors.ochre, AppColors.terracotta],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'FRUMA.',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(width: 18),
            _HeaderModeButton(
              label: 'INNOVATOR',
              selected: activeMode == 'innovator',
              onTap: onInnovator,
            ),
            const SizedBox(width: 6),
            _HeaderModeButton(
              label: 'PATRON',
              selected: activeMode == 'patron',
              onTap: onPatron,
            ),
          ],
        ),
      ),
    );
  }
}

class FrumaCeramicOrb extends StatelessWidget {
  const FrumaCeramicOrb({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 125,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 70,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF8E5),
                  Color(0xFFFFD892),
                  Color(0xFFFFE7B5),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ochre.withValues(alpha: 0.24),
                  blurRadius: 38,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.26),
                  blurRadius: 18,
                  offset: const Offset(-10, -12),
                ),
              ],
            ),
          ),
          const Positioned.fill(
            child: CustomPaint(painter: _OrbRingPainter()),
          ),
        ],
      ),
    );
  }
}

class FrumaBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const FrumaBackButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      onPressed: onPressed,
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        color: Colors.white.withValues(alpha: 0.78),
        size: 18,
      ),
    );
  }
}

class FrumaSectionLabel extends StatelessWidget {
  final String label;

  const FrumaSectionLabel({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: AppColors.patinaTeal.withValues(alpha: 0.82),
        fontFamily: 'SpaceGrotesk',
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 3,
      ),
    );
  }
}

class FrumaThinDivider extends StatelessWidget {
  const FrumaThinDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.07),
    );
  }
}

class FrumaStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const FrumaStatusPill({
    super.key,
    required this.label,
    this.color = AppColors.ochre,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontFamily: 'SpaceGrotesk',
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.7,
          ),
        ),
      ),
    );
  }
}

class FrumaLabButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;

  const FrumaLabButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = secondary ? AppColors.ochre : AppColors.volcanic950;
    final bg = secondary ? Colors.transparent : AppColors.ochre;
    final border =
        secondary ? AppColors.ochre.withValues(alpha: 0.55) : AppColors.ochre;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: fg,
          backgroundColor:
              onPressed == null ? Colors.white.withValues(alpha: 0.08) : bg,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
                color: onPressed == null ? AppColors.labLine : border),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 9),
            ],
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FrumaActionRow extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback? onTap;
  final IconData? icon;

  const FrumaActionRow({
    super.key,
    required this.title,
    required this.body,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.ochre, size: 19),
              const SizedBox(width: 13),
            ],
            SizedBox(
              width: icon == null ? 128 : 112,
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            Expanded(
              child: Text(
                body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.42),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.patinaTeal.withValues(alpha: 0.92),
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _HeaderModeButton({
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.ochre
                : Colors.white.withValues(alpha: 0.24),
            fontFamily: 'SpaceGrotesk',
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _OrbRingPainter extends CustomPainter {
  const _OrbRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.patinaTeal.withValues(alpha: 0.72);

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 + 5),
      width: size.width * 0.95,
      height: size.height * 0.34,
    );

    canvas.drawOval(rect, paint);

    final whisper = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.ochre.withValues(alpha: 0.14);
    canvas.drawOval(rect.inflate(3), whisper);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WeavePatternPainter extends CustomPainter {
  final double phase;
  final double intensity;

  const _WeavePatternPainter({
    required this.phase,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const step = 58.0;
    final warm = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.terracotta.withValues(alpha: 0.025);
    final shadow = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: 0.055);

    final drift = Offset(
      math.sin(phase * math.pi * 2) * 8,
      math.cos(phase * math.pi * 2) * 5,
    );

    for (double y = -step; y < size.height + step; y += step) {
      for (double x = -step; x < size.width + step; x += step) {
        final row = (y / step).round();
        final col = (x / step).round();
        final center = Offset(x + (row.isOdd ? step / 2 : 0), y) + drift;
        const radius = step * 0.52;
        final path = Path()
          ..moveTo(center.dx, center.dy - radius)
          ..lineTo(center.dx + radius, center.dy)
          ..lineTo(center.dx, center.dy + radius)
          ..lineTo(center.dx - radius, center.dy)
          ..close();
        canvas.drawPath(path, (row + col).isEven ? warm : shadow);
      }
    }

    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.44),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);

    final noise = Paint()
      ..color = Colors.white.withValues(alpha: 0.012)
      ..strokeWidth = 1;
    for (var i = 0; i < 120; i++) {
      final x =
          (math.sin(i * 17.23 + phase * math.pi * 2) * 0.5 + 0.5) * size.width;
      final y =
          (math.cos(i * 11.91 + phase * math.pi) * 0.5 + 0.5) * size.height;
      canvas.drawPoints(PointMode.points, [Offset(x, y)], noise);
    }

    final atmosphere = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = AppColors.patinaTeal.withValues(alpha: 0.035 * intensity);
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.18 + i * 0.17) +
          math.sin(phase * math.pi * 2 + i) * 18;
      final path = Path()..moveTo(-40, y);
      for (double x = -40; x <= size.width + 40; x += 44) {
        path.lineTo(
          x,
          y + math.sin((x / 120) + phase * math.pi * 2 + i) * 8,
        );
      }
      canvas.drawPath(path, atmosphere);
    }
  }

  @override
  bool shouldRepaint(covariant _WeavePatternPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.intensity != intensity;
  }
}
