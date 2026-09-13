import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

/// Soft matte surface — flat color, hairline border, optional soft shadow.
class MatteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;
  final bool elevated;
  final Color? color;

  const MatteCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.radius = AppRadii.md,
    this.elevated = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = color ??
        (isDark ? const Color(0xFF16181D) : const Color(0xFFFBFBFC));
    final border = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    final content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 1),
        boxShadow: elevated ? AppShadows.soft(context) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              )
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(radius),
                splashColor: theme.colorScheme.primary.withValues(alpha: 0.06),
                highlightColor: theme.colorScheme.primary.withValues(alpha: 0.03),
                child: Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: child,
                ),
              ),
      ),
    );

    return content;
  }
}

/// Staggered fade + slide for list children.
extension MatteAnimate on Widget {
  Widget matteEnter({int index = 0, int delayMs = 40}) {
    return animate(delay: (index * delayMs).ms)
        .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.06, end: 0, duration: 380.ms, curve: Curves.easeOutCubic);
  }
}
