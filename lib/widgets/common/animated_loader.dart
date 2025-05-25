import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class AnimatedLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final AnimatedLoaderType type;
  final Duration duration;

  const AnimatedLoader({
    Key? key,
    this.size = 40,
    this.color,
    this.type = AnimatedLoaderType.dots,
    this.duration = const Duration(milliseconds: 1200),
  }) : super(key: key);

  @override
  State<AnimatedLoader> createState() => _AnimatedLoaderState();
}

class _AnimatedLoaderState extends State<AnimatedLoader>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;

    switch (widget.type) {
      case AnimatedLoaderType.dots:
        return _DotsLoader(
          controller: _controller,
          size: widget.size,
          color: color,
        );
      case AnimatedLoaderType.pulse:
        return _PulseLoader(
          controller: _controller,
          size: widget.size,
          color: color,
        );
      case AnimatedLoaderType.wave:
        return _WaveLoader(
          controller: _controller,
          size: widget.size,
          color: color,
        );
      case AnimatedLoaderType.spinner:
        return _SpinnerLoader(
          controller: _controller,
          size: widget.size,
          color: color,
        );
      case AnimatedLoaderType.bounce:
        return _BounceLoader(
          controller: _controller,
          size: widget.size,
          color: color,
        );
    }
  }
}

enum AnimatedLoaderType { dots, pulse, wave, spinner, bounce }

class _DotsLoader extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final Color color;

  const _DotsLoader({
    required this.controller,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final double delay = index * 0.2;
              final double animationValue = (controller.value - delay) % 1.0;
              final double scale =
                  animationValue < 0.5
                      ? 1.0 - (animationValue * 2)
                      : (animationValue - 0.5) * 2;

              return Transform.scale(
                scale: 0.5 + (scale * 0.5),
                child: Container(
                  width: size * 0.2,
                  height: size * 0.2,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.5 + (scale * 0.5)),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _PulseLoader extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final Color color;

  const _PulseLoader({
    required this.controller,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double scale = 0.5 + (controller.value * 0.5);
        final double opacity = 1.0 - controller.value;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(opacity), width: 2),
          ),
          child: Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(opacity * 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveLoader extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final Color color;

  const _WaveLoader({
    required this.controller,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.6,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (index) {
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final double delay = index * 0.2;
              final double animationValue = (controller.value - delay) % 1.0;
              final double height =
                  (1.0 - (animationValue - 0.5).abs() * 2) * size * 0.6;

              return Container(
                width: size * 0.15,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(size * 0.075),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _SpinnerLoader extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final Color color;

  const _SpinnerLoader({
    required this.controller,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: controller.value * 2 * 3.14159,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [color.withOpacity(0.1), color],
                stops: const [0.0, 1.0],
              ),
            ),
            child: Container(
              margin: EdgeInsets.all(size * 0.1),
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BounceLoader extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final Color color;

  const _BounceLoader({
    required this.controller,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(2, (index) {
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final double delay = index * 0.5;
              final double animationValue = (controller.value - delay) % 1.0;
              final double bounceValue =
                  animationValue < 0.5
                      ? animationValue * 2
                      : 2 - (animationValue * 2);

              return Transform.translate(
                offset: Offset(0, -bounceValue * size * 0.3),
                child: Container(
                  width: size * 0.35,
                  height: size * 0.35,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class LoadingDots extends StatefulWidget {
  final int count;
  final double dotSize;
  final Color color;
  final Duration duration;

  const LoadingDots({
    Key? key,
    this.count = 3,
    this.dotSize = 8,
    this.color = AppColors.primary,
    this.duration = const Duration(milliseconds: 1000),
  }) : super(key: key);

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.count, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double delay = index / widget.count;
            final double animationValue = (_controller.value - delay) % 1.0;
            final double opacity =
                animationValue < 0.5
                    ? animationValue * 2
                    : 2 - (animationValue * 2);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.dotSize * 0.25),
              width: widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.3 + (opacity * 0.7)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

class CircularLoader extends StatefulWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const CircularLoader({
    Key? key,
    this.size = 24,
    this.color = AppColors.primary,
    this.strokeWidth = 2.5,
  }) : super(key: key);

  @override
  State<CircularLoader> createState() => _CircularLoaderState();
}

class _CircularLoaderState extends State<CircularLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CircularProgressIndicator(
        strokeWidth: widget.strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(widget.color),
      ),
    );
  }
}
