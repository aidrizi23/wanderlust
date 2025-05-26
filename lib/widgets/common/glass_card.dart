import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? backgroundColor;
  final double blurAmount;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.backgroundColor,
    this.blurAmount = 10,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: AppColors.glassGradient,
              borderRadius: BorderRadius.circular(borderRadius),
              border:
                  border ??
                  Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              color: backgroundColor ?? Colors.white.withOpacity(0.05),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
