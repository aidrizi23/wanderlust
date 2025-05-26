import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback? onGooglePressed;
  final VoidCallback? onApplePressed;
  final VoidCallback? onFacebookPressed;
  final bool isLoading;
  final bool showApple;
  final bool showFacebook;

  const SocialLoginButtons({
    super.key,
    this.onGooglePressed,
    this.onApplePressed,
    this.onFacebookPressed,
    this.isLoading = false,
    this.showApple = false,
    this.showFacebook = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDivider(),
        const SizedBox(height: AppStyles.spacingLG),
        _buildSocialButtons(context),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.border.withOpacity(0.3),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingMD),
          child: Text(
            'OR',
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.border.withOpacity(0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons(BuildContext context) {
    final buttons = <Widget>[];

    // Google Button
    buttons.add(
      _SocialLoginButton(
        onPressed: isLoading ? null : onGooglePressed,
        icon: _buildGoogleIcon(),
        label: 'Continue with Google',
        backgroundColor: Colors.white,
        textColor: Colors.black87,
        borderColor: AppColors.border.withOpacity(0.3),
      ),
    );

    // Apple Button (iOS/macOS)
    if (showApple) {
      buttons.add(const SizedBox(height: AppStyles.spacingMD));
      buttons.add(
        _SocialLoginButton(
          onPressed: isLoading ? null : onApplePressed,
          icon: const Icon(Icons.apple, color: Colors.white, size: 20),
          label: 'Continue with Apple',
          backgroundColor: Colors.black,
          textColor: Colors.white,
        ),
      );
    }

    // Facebook Button
    if (showFacebook) {
      buttons.add(const SizedBox(height: AppStyles.spacingMD));
      buttons.add(
        _SocialLoginButton(
          onPressed: isLoading ? null : onFacebookPressed,
          icon: const Icon(Icons.facebook, color: Colors.white, size: 20),
          label: 'Continue with Facebook',
          backgroundColor: const Color(0xFF1877F2),
          textColor: Colors.white,
        ),
      );
    }

    return Column(children: buttons);
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
          ),
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  const _SocialLoginButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });

  @override
  State<_SocialLoginButton> createState() => __SocialLoginButtonState();
}

class __SocialLoginButtonState extends State<_SocialLoginButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: widget.onPressed,
              onLongPress: null,
              style: OutlinedButton.styleFrom(
                backgroundColor: widget.backgroundColor,
                foregroundColor: widget.textColor,
                side: BorderSide(
                  color: widget.borderColor ?? Colors.transparent,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacingLG,
                  vertical: AppStyles.spacingMD,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.icon,
                  const SizedBox(width: AppStyles.spacingMD),
                  Text(
                    widget.label,
                    style: AppStyles.titleMedium.copyWith(
                      color: widget.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }
}

class QuickSocialLogin extends StatelessWidget {
  final VoidCallback? onGooglePressed;
  final VoidCallback? onApplePressed;
  final bool isLoading;

  const QuickSocialLogin({
    super.key,
    this.onGooglePressed,
    this.onApplePressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickSocialButton(
            onPressed: isLoading ? null : onGooglePressed,
            icon: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                  ),
                ),
              ),
            ),
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: AppStyles.spacingMD),
        Expanded(
          child: _QuickSocialButton(
            onPressed: isLoading ? null : onApplePressed,
            icon: const Icon(Icons.apple, color: Colors.white, size: 24),
            backgroundColor: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _QuickSocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final Color backgroundColor;

  const _QuickSocialButton({
    required this.onPressed,
    required this.icon,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: AppColors.border.withOpacity(0.3), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusMD),
          ),
          padding: EdgeInsets.zero,
        ),
        child: icon,
      ),
    );
  }
}

class SocialLoginDivider extends StatelessWidget {
  final String text;

  const SocialLoginDivider({super.key, this.text = 'OR'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppStyles.spacingLG),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.border.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyles.spacingMD,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingMD,
                vertical: AppStyles.spacingSM,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.border.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                text,
                style: AppStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.border.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
