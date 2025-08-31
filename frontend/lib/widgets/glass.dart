// lib/widgets/glass.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;                 // 12~20 권장
  final double opacity;              // 0.10~0.18 권장
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.16,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final br = borderRadius ?? BorderRadius.circular(16);
    final pad = padding ?? const EdgeInsets.all(12);

    Widget body = ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: pad,
          decoration: BoxDecoration(
            borderRadius: br,
            // 은은한 유리 테두리
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.10 : 0.22),
            ),
            // 유리 틴트
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity((isDark ? opacity * 0.6 : opacity) + 0.02),
                Colors.white.withOpacity(isDark ? opacity * 0.6 : opacity),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      body = Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: br, onTap: onTap, child: body),
      );
    }

    return (margin != null) ? Padding(padding: margin!, child: body) : body;
  }
}
