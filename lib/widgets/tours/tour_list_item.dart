import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../constants/routes.dart';
import '../../models/tour_models.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/glass_card.dart';

class TourListItem extends StatefulWidget {
  final Tour tour;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final bool showDescription;

  const TourListItem({
    Key? key,
    required this.tour,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.showDescription = true,
  }) : super(key: key);

  @override
  State<TourListItem> createState() => _TourListItemState();
}

class _TourListItemState extends State<TourListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppStyles.animationFast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: () {
              widget.onTap?.call();
              Navigator.pushNamed(
                context,
                Routes.tourDetail,
                arguments: widget.tour.id,
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: AppStyles.spacingMD),
              child: GlassCard(
                borderRadius: AppStyles.radiusLG,
                child: Column(
                  children: [_buildImageSection(), _buildContentSection()],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 200,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppStyles.radiusLG),
          topRight: Radius.circular(AppStyles.radiusLG),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(),
            _buildImageOverlay(),
            _buildDiscountBadge(),
            _buildFavoriteButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.tour.mainImageUrl != null &&
        widget.tour.mainImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.tour.mainImageUrl!,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Shimmer.fromColors(
              baseColor: AppColors.surface,
              highlightColor: AppColors.surfaceLight,
              child: Container(color: AppColors.surface),
            ),
        errorWidget:
            (context, url, error) => Container(
              color: AppColors.surface,
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.textSecondary,
                size: 50,
              ),
            ),
      );
    }

    return Container(
      color: AppColors.surface,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.textSecondary,
        size: 50,
      ),
    );
  }

  Widget _buildImageOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
          stops: const [0.6, 1.0],
        ),
      ),
    );
  }

  Widget _buildDiscountBadge() {
    if (!widget.tour.hasDiscount || widget.tour.discountPercentage == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: AppStyles.spacingMD,
      left: AppStyles.spacingMD,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacingSM,
          vertical: AppStyles.spacingXS,
        ),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppStyles.radiusSM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '-${widget.tour.discountPercentage}% OFF',
          style: AppStyles.caption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Positioned(
      top: AppStyles.spacingMD,
      right: AppStyles.spacingMD,
      child: GestureDetector(
        onTap: widget.onFavorite,
        child: Container(
          padding: const EdgeInsets.all(AppStyles.spacingSM),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Icon(
            widget.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: widget.isFavorite ? AppColors.error : Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(AppStyles.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleAndRating(),
          const SizedBox(height: AppStyles.spacingSM),
          _buildLocationAndDuration(),
          const SizedBox(height: AppStyles.spacingSM),
          _buildTags(),
          if (widget.showDescription) ...[
            const SizedBox(height: AppStyles.spacingSM),
            _buildDescription(),
          ],
          const SizedBox(height: AppStyles.spacingMD),
          _buildPriceAndAction(),
        ],
      ),
    );
  }

  Widget _buildTitleAndRating() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            widget.tour.name,
            style: AppStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppStyles.spacingSM),
        if (widget.tour.averageRating != null && widget.tour.averageRating! > 0)
          _buildRatingChip(),
      ],
    );
  }

  Widget _buildRatingChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingSM,
        vertical: AppStyles.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusSM),
        border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: AppColors.warning, size: 14),
          const SizedBox(width: 2),
          Text(
            Formatters.rating(widget.tour.averageRating!),
            style: AppStyles.caption.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationAndDuration() {
    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          color: AppColors.textSecondary,
          size: 16,
        ),
        const SizedBox(width: AppStyles.spacingXS),
        Expanded(
          child: Text(
            widget.tour.location,
            style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppStyles.spacingMD),
        Icon(Icons.schedule_outlined, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: AppStyles.spacingXS),
        Text(
          Formatters.duration(widget.tour.durationInDays),
          style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: AppStyles.spacingSM,
      runSpacing: AppStyles.spacingXS,
      children: [
        _buildTag(widget.tour.difficultyLevel, AppColors.primary),
        _buildTag(widget.tour.category, AppColors.accent),
        _buildTag(widget.tour.activityType, AppColors.success),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingSM,
        vertical: AppStyles.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusSM),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: AppStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.tour.description,
      style: AppStyles.bodySmall.copyWith(
        color: AppColors.textSecondary,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPriceAndAction() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [_buildPriceSection(), _buildActionButton()],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tour.hasDiscount &&
            widget.tour.price != widget.tour.displayPrice)
          Text(
            Formatters.currency(widget.tour.price),
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              Formatters.currency(widget.tour.displayPrice),
              style: AppStyles.titleLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppStyles.spacingXS),
            Text(
              'per person',
              style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingMD,
        vertical: AppStyles.spacingSM,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppStyles.radiusSM),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        'View Details',
        style: AppStyles.titleSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class TourListItemCompact extends StatelessWidget {
  final Tour tour;
  final VoidCallback? onTap;

  const TourListItemCompact({Key? key, required this.tour, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap?.call();
        Navigator.pushNamed(context, Routes.tourDetail, arguments: tour.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppStyles.spacingSM),
        padding: const EdgeInsets.all(AppStyles.spacingMD),
        decoration: AppStyles.cardDecoration,
        child: Row(
          children: [
            _buildCompactImage(),
            const SizedBox(width: AppStyles.spacingMD),
            Expanded(child: _buildCompactContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppStyles.radiusSM),
      child: SizedBox(
        width: 80,
        height: 80,
        child:
            tour.mainImageUrl != null && tour.mainImageUrl!.isNotEmpty
                ? CachedNetworkImage(
                  imageUrl: tour.mainImageUrl!,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Shimmer.fromColors(
                        baseColor: AppColors.surface,
                        highlightColor: AppColors.surfaceLight,
                        child: Container(color: AppColors.surface),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: AppColors.surface,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                )
                : Container(
                  color: AppColors.surface,
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ),
      ),
    );
  }

  Widget _buildCompactContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tour.name,
          style: AppStyles.titleMedium.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppStyles.spacingXS),
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: AppColors.textSecondary,
              size: 14,
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                tour.location,
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppStyles.spacingXS),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Formatters.currency(tour.displayPrice),
              style: AppStyles.titleMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (tour.averageRating != null && tour.averageRating! > 0)
              Row(
                children: [
                  Icon(Icons.star, color: AppColors.warning, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    Formatters.rating(tour.averageRating!),
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
