import 'package:flutter/material.dart';

class VoiceWaveform extends StatelessWidget {
  final List<double> peaks;
  final double progress; // 0..1 played portion
  final bool interactive;
  final ValueChanged<double>? onSeek;
  final Color? activeColor;
  final Color? inactiveColor;
  final double height;

  const VoiceWaveform({
    super.key,
    required this.peaks,
    this.progress = 0,
    this.interactive = false,
    this.onSeek,
    this.activeColor,
    this.inactiveColor,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = activeColor ?? theme.colorScheme.primary;
    final inactive =
        inactiveColor ?? theme.colorScheme.primary.withValues(alpha: 0.25);

    final data = peaks.isEmpty
        ? List<double>.generate(32, (i) => 0.2 + (i % 5) * 0.08)
        : peaks;

    Widget bars = CustomPaint(
      painter: _WavePainter(
        peaks: data,
        progress: progress,
        active: active,
        inactive: inactive,
      ),
      size: Size(double.infinity, height),
    );

    if (!interactive || onSeek == null) {
      return SizedBox(height: height, width: double.infinity, child: bars);
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          void handle(Offset local) {
            final f = (local.dx / constraints.maxWidth).clamp(0.0, 1.0);
            onSeek!(f);
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => handle(d.localPosition),
            onHorizontalDragUpdate: (d) => handle(d.localPosition),
            child: bars,
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final List<double> peaks;
  final double progress;
  final Color active;
  final Color inactive;

  _WavePainter({
    required this.peaks,
    required this.progress,
    required this.active,
    required this.inactive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = peaks.length;
    if (n == 0) return;

    final barWidth = size.width / (n * 1.6);
    final gap = barWidth * 0.6;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < n; i++) {
      final t = i / n;
      paint.color = t <= progress ? active : inactive;
      final h = (peaks[i].clamp(0.08, 1.0)) * size.height;
      final x = i * (barWidth + gap);
      final y = (size.height - h) / 2;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, h),
        const Radius.circular(2),
      );
      canvas.drawRRect(r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.progress != progress ||
      old.peaks != peaks ||
      old.active != active ||
      old.inactive != inactive;
}
