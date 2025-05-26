import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/common/gradient_button.dart';

class ErrorScreen extends StatefulWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final IconData? icon;

  const ErrorScreen({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.retryButtonText,
    this.icon,
  });

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppStyles.animationMedium,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(AppStyles.spacingLG),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildErrorIcon(),
                      const SizedBox(height: AppStyles.spacingXL),
                      _buildErrorTitle(),
                      const SizedBox(height: AppStyles.spacingMD),
                      _buildErrorMessage(),
                      const SizedBox(height: AppStyles.spacingXXL),
                      if (widget.onRetry != null) _buildRetryButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(60),
        border: Border.all(color: AppColors.error.withOpacity(0.2), width: 2),
      ),
      child: Icon(
        widget.icon ?? Icons.error_outline,
        size: 60,
        color: AppColors.error,
      ),
    );
  }

  Widget _buildErrorTitle() {
    return Text(
      widget.title ?? 'Oops! Something went wrong',
      style: AppStyles.headingMedium,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorMessage() {
    return Text(
      widget.message ??
          'We encountered an unexpected error. Please try again or contact support if the problem persists.',
      style: AppStyles.bodyMedium.copyWith(
        color: AppColors.textSecondary,
        height: 1.6,
      ),
      textAlign: TextAlign.center,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildRetryButton() {
    return SizedBox(
      width: double.infinity,
      child: GradientButton(
        text: widget.retryButtonText ?? 'Try Again',
        onPressed: widget.onRetry,
        icon: Icons.refresh,
        height: 56,
      ),
    );
  }
}

class NetworkErrorScreen extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorScreen(
      title: 'No Internet Connection',
      message:
          'Please check your internet connection and try again. Make sure you\'re connected to Wi-Fi or mobile data.',
      icon: Icons.wifi_off_outlined,
      onRetry: onRetry,
      retryButtonText: 'Retry',
    );
  }
}

class NotFoundErrorScreen extends StatelessWidget {
  final VoidCallback? onGoBack;

  const NotFoundErrorScreen({super.key, this.onGoBack});

  @override
  Widget build(BuildContext context) {
    return ErrorScreen(
      title: 'Page Not Found',
      message:
          'The page you\'re looking for doesn\'t exist or has been moved. Let\'s get you back on track.',
      icon: Icons.search_off_outlined,
      onRetry: onGoBack ?? () => Navigator.of(context).pop(),
      retryButtonText: 'Go Back',
    );
  }
}

class ServerErrorScreen extends StatelessWidget {
  final VoidCallback? onRetry;

  const ServerErrorScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorScreen(
      title: 'Server Error',
      message:
          'Our servers are experiencing issues right now. Please wait a moment and try again.',
      icon: Icons.dns_outlined,
      onRetry: onRetry,
      retryButtonText: 'Try Again',
    );
  }
}
