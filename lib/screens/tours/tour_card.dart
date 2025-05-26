import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants/colors.dart';
import '../../constants/routes.dart'; // Ensure Routes.tourDetail is defined
import '../../models/tour_models.dart';
import '../../widgets/common/glass_card.dart';

class TourCard extends StatelessWidget {
  final Tour tour;

  const TourCard({super.key, required this.tour});

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'en_US', // Adjust locale as needed
      symbol: '\$', // Adjust currency symbol as needed
    );

    return GestureDetector(
      onTap: () {
        // Navigate to Tour Detail Screen, passing the tour ID as an argument
        Navigator.pushNamed(
          context,
          Routes.tourDetail,
          arguments: tour.id, // Pass the tour ID
        );
      },
      child: GlassCard(
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(context),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTourName(),
                  const SizedBox(height: 6),
                  _buildLocationInfo(),
                  const SizedBox(height: 4),
                  _buildDurationAndRating(context),
                ],
              ),
            ),
            const Spacer(), // Pushes price to the bottom
            _buildPriceSection(
              currencyFormatter,
              context,
            ), // Pass context for navigation from details button
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10, // Standard aspect ratio for images
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
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
                          Icons.image_not_supported_outlined,
                          color: AppColors.textSecondary,
                          size: 40,
                        ),
                      ),
                )
                : Container(
                  color: AppColors.surface,
                  child: const Icon(
                    Icons.image_outlined, // Placeholder icon
                    color: AppColors.textSecondary,
                    size: 50,
                  ),
                ),
            if (tour.hasDiscount && tour.discountPercentage != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-${tour.discountPercentage}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: GlassCard(
                padding: const EdgeInsets.all(6),
                borderRadius: 20, // Circular look
                backgroundColor: AppColors.surface.withOpacity(0.3),
                child: Icon(
                  Icons.favorite_border, // TODO: Implement favorite toggle
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTourName() {
    return Text(
      tour.name,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildLocationInfo() {
    return Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          color: AppColors.textSecondary,
          size: 14,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            tour.location,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationAndRating(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.timer_outlined,
              color: AppColors.textSecondary,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              '${tour.durationInDays} Days',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        if (tour.averageRating != null && tour.averageRating! > 0)
          Row(
            children: [
              const Icon(Icons.star, color: AppColors.warning, size: 16),
              const SizedBox(width: 4),
              Text(
                tour.averageRating!.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (tour.reviewCount != null && tour.reviewCount! > 0)
                Text(
                  ' (${tour.reviewCount})',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildPriceSection(
    NumberFormat currencyFormatter,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end, // Align items to the bottom
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Important for vertical alignment
            children: [
              if (tour.hasDiscount && tour.discountedPrice != null)
                Text(
                  currencyFormatter.format(tour.price),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textTertiary.withOpacity(0.8),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.textTertiary.withOpacity(0.8),
                  ),
                ),
              Text(
                currencyFormatter.format(tour.displayPrice),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () {
              // Also navigate to Tour Detail Screen when "Details" button is tapped
              Navigator.pushNamed(
                context,
                Routes.tourDetail,
                arguments: tour.id,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Details',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
