import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wanderlust/screens/tours/tour_card.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../models/tour_models.dart';
import '../../widgets/common/responsive_layout.dart';

class TourGrid extends StatefulWidget {
  final List<Tour> tours;
  final bool isLoading;
  final bool isLoadingMore;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoadMore;
  final ScrollController? scrollController;
  final EdgeInsets? padding;

  const TourGrid({
    super.key,
    required this.tours,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.onRefresh,
    this.onLoadMore,
    this.scrollController,
    this.padding,
  });

  @override
  State<TourGrid> createState() => _TourGridState();
}

class _TourGridState extends State<TourGrid> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (widget.onLoadMore != null && !widget.isLoadingMore) {
        widget.onLoadMore!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.tours.isEmpty) {
      return _buildLoadingGrid(context);
    }

    if (widget.tours.isEmpty && !widget.isLoading) {
      return _buildEmptyState(context);
    }

    return _buildTourGrid(context);
  }

  Widget _buildTourGrid(BuildContext context) {
    final crossAxisCount = context.tourGridCrossAxisCount;
    final aspectRatio = context.tourCardAspectRatio;

    Widget gridView = GridView.builder(
      controller: _scrollController,
      padding: widget.padding ?? EdgeInsets.all(context.isMobile ? 16 : 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: context.isMobile ? 12 : 16,
        mainAxisSpacing: context.isMobile ? 16 : 20,
      ),
      itemCount:
          widget.tours.length + (widget.isLoadingMore ? crossAxisCount : 0),
      itemBuilder: (context, index) {
        if (index >= widget.tours.length) {
          return _buildLoadingCard();
        }
        return TourCard(tour: widget.tours[index]);
      },
    );

    if (widget.onRefresh != null) {
      gridView = RefreshIndicator(
        onRefresh: () async {
          widget.onRefresh!();
        },
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: gridView,
      );
    }

    return gridView;
  }

  Widget _buildLoadingGrid(BuildContext context) {
    final crossAxisCount = context.tourGridCrossAxisCount;
    final aspectRatio = context.tourCardAspectRatio;

    return GridView.builder(
      padding: widget.padding ?? EdgeInsets.all(context.isMobile ? 16 : 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: context.isMobile ? 12 : 16,
        mainAxisSpacing: context.isMobile ? 16 : 20,
      ),
      itemCount: crossAxisCount * 3, // Show 3 rows of loading cards
      itemBuilder: (context, index) => _buildLoadingCard(),
    );
  }

  Widget _buildLoadingCard() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceLight,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyles.radiusLG),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: AppColors.border.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.explore_off_outlined,
                size: 60,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppStyles.spacingXL),
            Text(
              'No tours found',
              style: AppStyles.headingSmall.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.spacingSM),
            Text(
              'Try adjusting your search criteria or explore different destinations.',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class TourGridCompact extends StatelessWidget {
  final List<Tour> tours;
  final int maxItems;
  final VoidCallback? onSeeAll;
  final EdgeInsets? padding;

  const TourGridCompact({
    super.key,
    required this.tours,
    this.maxItems = 6,
    this.onSeeAll,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final displayTours = tours.take(maxItems).toList();
    final crossAxisCount = context.tourGridCrossAxisCount;
    final aspectRatio = context.tourCardAspectRatio;

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: padding ?? EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: context.isMobile ? 12 : 16,
            mainAxisSpacing: context.isMobile ? 16 : 20,
          ),
          itemCount: displayTours.length,
          itemBuilder: (context, index) {
            return TourCard(tour: displayTours[index]);
          },
        ),
        if (tours.length > maxItems && onSeeAll != null) ...[
          const SizedBox(height: AppStyles.spacingLG),
          TextButton(
            onPressed: onSeeAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See All ${tours.length} Tours',
                  style: AppStyles.titleMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppStyles.spacingSM),
                const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class TourGridStaggered extends StatelessWidget {
  final List<Tour> tours;
  final EdgeInsets? padding;

  const TourGridStaggered({super.key, required this.tours, this.padding});

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      // Use regular grid on mobile
      return TourGrid(tours: tours, padding: padding);
    }

    // Staggered layout for larger screens
    return Padding(
      padding: padding ?? const EdgeInsets.all(24),
      child: _buildStaggeredGrid(context),
    );
  }

  Widget _buildStaggeredGrid(BuildContext context) {
    final crossAxisCount = context.tourGridCrossAxisCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - ((crossAxisCount - 1) * 16)) /
            crossAxisCount;

        return Wrap(
          spacing: 16,
          runSpacing: 20,
          children:
              tours.map((tour) {
                return SizedBox(width: itemWidth, child: TourCard(tour: tour));
              }).toList(),
        );
      },
    );
  }
}

class TourGridSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Tour> tours;
  final bool isLoading;
  final VoidCallback? onSeeAll;
  final int maxItems;

  const TourGridSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.tours,
    this.isLoading = false,
    this.onSeeAll,
    this.maxItems = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.isMobile ? 16 : 24,
            vertical: AppStyles.spacingMD,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppStyles.headingSmall),
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
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: Text(
                    'See All',
                    style: AppStyles.titleSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (isLoading)
          _buildLoadingSection(context)
        else if (tours.isNotEmpty)
          TourGridCompact(
            tours: tours,
            maxItems: maxItems,
            onSeeAll: onSeeAll,
            padding: EdgeInsets.symmetric(
              horizontal: context.isMobile ? 16 : 24,
            ),
          )
        else
          _buildEmptySection(context),
        const SizedBox(height: AppStyles.spacingXXL),
      ],
    );
  }

  Widget _buildLoadingSection(BuildContext context) {
    final crossAxisCount = context.tourGridCrossAxisCount;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.isMobile ? 16 : 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: context.tourCardAspectRatio,
          crossAxisSpacing: context.isMobile ? 12 : 16,
          mainAxisSpacing: context.isMobile ? 16 : 20,
        ),
        itemCount: maxItems.clamp(0, crossAxisCount * 2),
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: AppColors.surface,
            highlightColor: AppColors.surfaceLight,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppStyles.radiusLG),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptySection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.isMobile ? 16 : 24,
        vertical: AppStyles.spacingXL,
      ),
      child: Center(
        child: Text(
          'No tours available at the moment',
          style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
