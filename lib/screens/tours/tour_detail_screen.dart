import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../models/tour_models.dart';
import '../../services/tour_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/responsive_layout.dart';

class TourDetailScreen extends StatefulWidget {
  final int tourId;

  const TourDetailScreen({Key? key, required this.tourId}) : super(key: key);

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen>
    with TickerProviderStateMixin {
  final TourService _tourService = TourService();
  Tour? _tourDetails;
  bool _isLoading = true;
  String? _error;

  late PageController _pageController;
  int _currentImageIndex = 0;
  late TabController _tabController;

  // Booking state
  DateTime? _selectedStartDate;
  int _groupSize = 1;
  Map<String, dynamic>? _availabilityResult;
  bool _isCheckingAvailability = false;

  // Animation controllers
  late AnimationController _imageAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _fabAnimationController;

  late Animation<double> _imageScaleAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;
  late Animation<double> _fabScaleAnimation;

  bool _showBookingFab = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Initialize animations
    _imageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _contentAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: AppStyles.animationMedium,
    );

    _imageScaleAnimation = Tween<double>(begin: 1.2, end: 1.0).animate(
      CurvedAnimation(parent: _imageAnimationController, curve: Curves.easeOut),
    );

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _scrollController.addListener(_onScroll);
    _fetchTourDetails(widget.tourId);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final shouldShow = offset < 100; // Show FAB when near top

    if (shouldShow != _showBookingFab) {
      setState(() => _showBookingFab = shouldShow);
      if (shouldShow) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    }
  }

  void _initTabController() {
    if (_tourDetails != null && mounted) {
      int tabCount = 0;
      if (_tourDetails!.itineraryItems.isNotEmpty) tabCount++;
      if (_tourDetails!.features.isNotEmpty) tabCount++;
      if (_tourDetails!.images.isNotEmpty || _tourDetails!.mainImageUrl != null)
        tabCount++;

      if (tabCount > 0) {
        _tabController = TabController(length: tabCount, vsync: this);
      }
    }
  }

  @override
  void dispose() {
    _imageAnimationController.dispose();
    _contentAnimationController.dispose();
    _fabAnimationController.dispose();
    _pageController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchTourDetails(int id) async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final tour = await _tourService.getTourById(id);

      if (mounted) {
        setState(() {
          _tourDetails = tour;
          _isLoading = false;
          _initTabController();
        });

        // Start animations
        _imageAnimationController.forward();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _contentAnimationController.forward();
            _fabAnimationController.forward();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCheckAvailabilityAndBook() async {
    if (_selectedStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a start date first.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_tourDetails == null || !mounted) return;

    setState(() => _isCheckingAvailability = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      final isSimulatedAvailable =
          _groupSize <= 10 && _tourDetails!.maxGroupSize >= _groupSize;
      final result = {
        "isAvailable": isSimulatedAvailable,
        "totalPrice":
            isSimulatedAvailable
                ? _tourDetails!.displayPrice * _groupSize
                : 0.0,
        "message":
            isSimulatedAvailable
                ? "Tour is available!"
                : "Tour not available for selected criteria.",
        "date": _selectedStartDate!.toIso8601String(),
        "guests": _groupSize,
      };

      if (mounted) {
        setState(() {
          _availabilityResult = result;
          _isCheckingAvailability = false;
        });

        if (result["isAvailable"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Available! Total: ${Formatters.currency(result["totalPrice"] as double)}. Booking flow would continue here.',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availabilityResult = {"isAvailable": false, "message": e.toString()};
          _isCheckingAvailability = false;
        });
      }
    }
  }

  void _showBookingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBookingModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBodyContent(),
      floatingActionButton: _tourDetails != null ? _buildBookingFAB() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_tourDetails == null) {
      return _buildNotFoundWidget();
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _contentFadeAnimation,
            child: SlideTransition(
              position: _contentSlideAnimation,
              child: Column(
                children: [
                  _buildTourInfo(),
                  _buildTabs(),
                  const SizedBox(height: 100), // Padding for FAB
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    final images = _getDisplayImages();

    return SliverAppBar(
      expandedHeight: context.isMobile ? 300 : 400,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {
              // TODO: Implement favorite functionality
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedBuilder(
          animation: _imageScaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _imageScaleAnimation.value,
              child: _buildImageCarousel(images),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<TourImage> images) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (index) {
            if (mounted) setState(() => _currentImageIndex = index);
          },
          itemBuilder: (context, index) {
            return _buildImage(images[index].imageUrl);
          },
        ),
        _buildImageOverlay(),
        if (_tourDetails!.hasDiscount) _buildDiscountBadge(),
        if (images.length > 1) _buildImageIndicators(images.length),
      ],
    );
  }

  Widget _buildImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
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

  Widget _buildImageOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
          stops: const [0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildDiscountBadge() {
    return Positioned(
      top: 60,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacingMD,
          vertical: AppStyles.spacingSM,
        ),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppStyles.radiusSM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          '-${_tourDetails!.discountPercentage}% OFF',
          style: AppStyles.titleSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildImageIndicators(int count) {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          return AnimatedContainer(
            duration: AppStyles.animationFast,
            width: _currentImageIndex == index ? 12 : 8,
            height: _currentImageIndex == index ? 12 : 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  _currentImageIndex == index
                      ? AppColors.primary
                      : Colors.white.withOpacity(0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTourInfo() {
    return ResponsiveContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppStyles.spacingLG),
          _buildTourHeader(),
          const SizedBox(height: AppStyles.spacingMD),
          _buildTourMeta(),
          const SizedBox(height: AppStyles.spacingMD),
          _buildTourTags(),
          const SizedBox(height: AppStyles.spacingLG),
          _buildDescription(),
          const SizedBox(height: AppStyles.spacingLG),
        ],
      ),
    );
  }

  Widget _buildTourHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tourDetails!.name,
          style: (context.isMobile
                  ? AppStyles.headingMedium
                  : AppStyles.headingLarge)
              .copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppStyles.spacingSM),
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppStyles.spacingXS),
            Expanded(
              child: Text(
                _tourDetails!.location,
                style: AppStyles.titleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (_tourDetails!.averageRating != null &&
                _tourDetails!.averageRating! > 0)
              _buildRatingChip(),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingMD,
        vertical: AppStyles.spacingSM,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: AppColors.warning, size: 16),
          const SizedBox(width: AppStyles.spacingXS),
          Text(
            Formatters.rating(_tourDetails!.averageRating!),
            style: AppStyles.titleSmall.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_tourDetails!.reviewCount != null &&
              _tourDetails!.reviewCount! > 0) ...[
            const SizedBox(width: AppStyles.spacingXS),
            Text(
              '(${_tourDetails!.reviewCount})',
              style: AppStyles.bodySmall.copyWith(color: AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTourMeta() {
    return Wrap(
      spacing: AppStyles.spacingLG,
      runSpacing: AppStyles.spacingMD,
      children: [
        _buildMetaItem(
          Icons.schedule_outlined,
          Formatters.duration(_tourDetails!.durationInDays),
        ),
        _buildMetaItem(
          Icons.group_outlined,
          'Max ${_tourDetails!.maxGroupSize} people',
        ),
        _buildPriceDisplay(),
      ],
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: AppStyles.spacingSM),
        Text(
          text,
          style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPriceDisplay() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.payment_outlined, color: AppColors.primary, size: 18),
        const SizedBox(width: AppStyles.spacingSM),
        if (_tourDetails!.hasDiscount &&
            _tourDetails!.price != _tourDetails!.displayPrice) ...[
          Text(
            Formatters.currency(_tourDetails!.price),
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: AppStyles.spacingSM),
        ],
        Text(
          Formatters.currency(_tourDetails!.displayPrice),
          style: AppStyles.titleLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: AppStyles.spacingXS),
        Text(
          'per person',
          style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTourTags() {
    return Wrap(
      spacing: AppStyles.spacingSM,
      runSpacing: AppStyles.spacingSM,
      children: [
        _buildTag(_tourDetails!.difficultyLevel, AppColors.primary),
        _buildTag(_tourDetails!.category, AppColors.accent),
        _buildTag(_tourDetails!.activityType, AppColors.success),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingMD,
        vertical: AppStyles.spacingSM,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: AppStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this tour',
          style: AppStyles.headingSmall.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppStyles.spacingMD),
        Text(
          _tourDetails!.description,
          style: AppStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    if (_tabController.length == 0) return const SizedBox.shrink();

    List<Widget> tabs = [];
    List<Widget> tabViews = [];

    if (_tourDetails!.itineraryItems.isNotEmpty) {
      tabs.add(const Tab(text: 'Itinerary'));
      tabViews.add(_buildItineraryTab());
    }

    if (_tourDetails!.features.isNotEmpty) {
      tabs.add(const Tab(text: 'Features'));
      tabViews.add(_buildFeaturesTab());
    }

    if (_getDisplayImages().isNotEmpty) {
      tabs.add(const Tab(text: 'Gallery'));
      tabViews.add(_buildGalleryTab());
    }

    return ResponsiveContainer(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppStyles.radiusMD),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                color: AppColors.primary,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: tabs,
            ),
          ),
          const SizedBox(height: AppStyles.spacingLG),
          SizedBox(
            height: 400,
            child: TabBarView(controller: _tabController, children: tabViews),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryTab() {
    return ListView.separated(
      itemCount: _tourDetails!.itineraryItems.length,
      separatorBuilder:
          (context, index) => const Divider(color: AppColors.border, height: 1),
      itemBuilder: (context, index) {
        final item = _tourDetails!.itineraryItems[index];
        return ExpansionTile(
          title: Text(
            'Day ${item.dayNumber}: ${item.title}',
            style: AppStyles.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(AppStyles.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  if (item.location != null || item.startTime != null) ...[
                    const SizedBox(height: AppStyles.spacingMD),
                    Wrap(
                      spacing: AppStyles.spacingLG,
                      children: [
                        if (item.location != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pin_drop_outlined,
                                size: 16,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: AppStyles.spacingXS),
                              Text(
                                item.location!,
                                style: AppStyles.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        if (item.startTime != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_outlined,
                                size: 16,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: AppStyles.spacingXS),
                              Text(
                                '${item.startTime} - ${item.endTime}',
                                style: AppStyles.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturesTab() {
    return ListView.builder(
      itemCount: _tourDetails!.features.length,
      itemBuilder: (context, index) {
        final feature = _tourDetails!.features[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(AppStyles.spacingSM),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: AppColors.success, size: 16),
          ),
          title: Text(
            feature.name,
            style: AppStyles.titleMedium.copyWith(fontWeight: FontWeight.w500),
          ),
          subtitle:
              feature.description != null
                  ? Text(
                    feature.description!,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                  : null,
        );
      },
    );
  }

  Widget _buildGalleryTab() {
    final images = _getDisplayImages();

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.isMobile ? 2 : 3,
        crossAxisSpacing: AppStyles.spacingSM,
        mainAxisSpacing: AppStyles.spacingSM,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showImageViewer(images, index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppStyles.radiusSM),
            child: CachedNetworkImage(
              imageUrl: images[index].imageUrl,
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
                    ),
                  ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingFAB() {
    return AnimatedBuilder(
      animation: _fabScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabScaleAnimation.value,
          child: Container(
            width:
                context.isMobile
                    ? MediaQuery.of(context).size.width * 0.9
                    : 400,
            height: 56,
            child: GradientButton(
              text:
                  'Book Now - ${Formatters.currency(_tourDetails!.displayPrice)}',
              onPressed: _showBookingModal,
              icon: Icons.calendar_today_outlined,
              height: 56,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingModal() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildModalHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppStyles.spacingLG),
                  child: _buildBookingForm(setState),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalHeader() {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingLG),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Book Your Tour',
            style: AppStyles.headingSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingForm(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date & Guests',
          style: AppStyles.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppStyles.spacingLG),
        _buildDateSelector(setState),
        const SizedBox(height: AppStyles.spacingLG),
        _buildGuestSelector(setState),
        const SizedBox(height: AppStyles.spacingLG),
        if (_availabilityResult != null) _buildAvailabilityResult(),
        const SizedBox(height: AppStyles.spacingXL),
        _buildBookingButton(setState),
      ],
    );
  }

  Widget _buildDateSelector(StateSetter setState) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate:
              _selectedStartDate ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now().add(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.primary,
                  surface: AppColors.surface,
                  onSurface: AppColors.textPrimary,
                ),
                dialogBackgroundColor: AppColors.backgroundSecondary,
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          setState(() {
            _selectedStartDate = picked;
            _availabilityResult = null;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppStyles.spacingMD),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppStyles.radiusMD),
          border: Border.all(
            color: AppColors.border.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppStyles.spacingMD),
            Expanded(
              child: Text(
                _selectedStartDate != null
                    ? Formatters.date(_selectedStartDate!)
                    : 'Select start date',
                style: AppStyles.bodyMedium.copyWith(
                  color:
                      _selectedStartDate != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestSelector(StateSetter setState) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
        border: Border.all(color: AppColors.border.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.group_outlined, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: AppStyles.spacingMD),
          Expanded(
            child: Text(
              '$_groupSize Guest${_groupSize > 1 ? 's' : ''}',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed:
                    _groupSize > 1
                        ? () {
                          setState(() {
                            _groupSize--;
                            _availabilityResult = null;
                          });
                        }
                        : null,
                icon: Icon(
                  Icons.remove_circle_outline,
                  color:
                      _groupSize > 1
                          ? AppColors.primary
                          : AppColors.textTertiary,
                ),
              ),
              Text(
                _groupSize.toString(),
                style: AppStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed:
                    _groupSize < _tourDetails!.maxGroupSize
                        ? () {
                          setState(() {
                            _groupSize++;
                            _availabilityResult = null;
                          });
                        }
                        : null,
                icon: Icon(
                  Icons.add_circle_outline,
                  color:
                      _groupSize < _tourDetails!.maxGroupSize
                          ? AppColors.primary
                          : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityResult() {
    if (_availabilityResult == null) return const SizedBox.shrink();

    final isAvailable = _availabilityResult!['isAvailable'] as bool;
    final color = isAvailable ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingMD),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.check_circle_outline : Icons.error_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: AppStyles.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _availabilityResult!['message'] as String,
                  style: AppStyles.titleSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isAvailable) ...[
                  const SizedBox(height: AppStyles.spacingXS),
                  Text(
                    'Total: ${Formatters.currency(_availabilityResult!['totalPrice'] as double)}',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton(StateSetter setState) {
    return GradientButton(
      text:
          _isCheckingAvailability ? 'Checking...' : 'Check Availability & Book',
      isLoading: _isCheckingAvailability,
      onPressed: _handleCheckAvailabilityAndBook,
      width: double.infinity,
      icon: Icons.payment_outlined,
      height: 56,
    );
  }

  List<TourImage> _getDisplayImages() {
    if (_tourDetails!.images.isNotEmpty) {
      return _tourDetails!.images;
    } else if (_tourDetails!.mainImageUrl != null &&
        _tourDetails!.mainImageUrl!.isNotEmpty) {
      return [
        TourImage(
          id: 0,
          imageUrl: _tourDetails!.mainImageUrl!,
          displayOrder: 0,
        ),
      ];
    }
    return [];
  }

  void _showImageViewer(List<TourImage> images, int initialIndex) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(10),
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: images.length,
                  controller: PageController(initialPage: initialIndex),
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: images[index].imageUrl,
                        fit: BoxFit.contain,
                        placeholder:
                            (context, url) => const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textSecondary,
                              size: 50,
                            ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spacingLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 60),
            const SizedBox(height: AppStyles.spacingLG),
            Text(
              'Error loading tour details',
              style: AppStyles.headingSmall.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.spacingSM),
            Text(
              _error ?? "An unknown error occurred.",
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.spacingLG),
            ElevatedButton.icon(
              onPressed: () => _fetchTourDetails(widget.tourId),
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: AppStyles.primaryButtonStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spacingLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              color: AppColors.textSecondary,
              size: 60,
            ),
            const SizedBox(height: AppStyles.spacingLG),
            Text(
              'Tour not found',
              style: AppStyles.headingSmall.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.spacingSM),
            Text(
              'The tour you\'re looking for doesn\'t exist or has been removed.',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.spacingLG),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text("Go Back"),
              style: AppStyles.primaryButtonStyle,
            ),
          ],
        ),
      ),
    );
  }
}
