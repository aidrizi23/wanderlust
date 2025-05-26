import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';

class AuthHeader extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final bool showLogo;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.showLogo = true,
  });

  @override
  State<AuthHeader> createState() => _AuthHeaderState();
}

class _AuthHeaderState extends State<AuthHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            if (widget.showLogo) ...[
              _buildLogo(),
              const SizedBox(height: AppStyles.spacingXL),
            ],
            _buildTitle(),
            const SizedBox(height: AppStyles.spacingSM),
            _buildSubtitle(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Icon(
          widget.icon ?? Icons.explore,
          size: 50,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.title,
      style: AppStyles.headingLarge.copyWith(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    return Text(
      widget.subtitle,
      style: AppStyles.bodyLarge.copyWith(
        color: AppColors.textSecondary,
        fontSize: 16,
        letterSpacing: 0.3,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class AuthHeaderMinimal extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AuthHeaderMinimal({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppStyles.headingMedium.copyWith(color: Colors.white),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppStyles.spacingSM),
          Text(
            subtitle!,
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class AuthWelcomeHeader extends StatefulWidget {
  final String welcomeText;
  final String appName;
  final String tagline;

  const AuthWelcomeHeader({
    super.key,
    this.welcomeText = 'Welcome to',
    this.appName = 'Wanderlust',
    this.tagline = 'Discover Your Next Adventure',
  });

  @override
  State<AuthWelcomeHeader> createState() => _AuthWelcomeHeaderState();
}

class _AuthWelcomeHeaderState extends State<AuthWelcomeHeader>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _logoController;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;

  @override
  void initState() {
    super.initState();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoRotation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _textController.forward();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _logoController,
          builder: (context, child) {
            return Transform.scale(
              scale: _logoScale.value,
              child: Transform.rotate(
                angle: _logoRotation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.explore,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppStyles.spacingLG),
        FadeTransition(
          opacity: _textOpacity,
          child: SlideTransition(
            position: _textSlide,
            child: Column(
              children: [
                Text(
                  widget.welcomeText,
                  style: AppStyles.titleMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppStyles.spacingSM),
                Text(
                  widget.appName,
                  style: AppStyles.headingMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppStyles.spacingSM),
                Text(
                  widget.tagline,
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
