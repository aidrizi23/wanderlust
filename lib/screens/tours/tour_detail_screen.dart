import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../constants/colors.dart';
import '../../models/tour_models.dart';
import '../../services/tour_service.dart';
import '../../widgets/common/gradient_button.dart';
// import '../../widgets/common/glass_card.dart'; // Using standard Card for booking panel

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
  TabController? _tabController;

  // State for booking/availability - shared between modal and sidebar logic
  DateTime? _selectedStartDate;
  int _groupSize = 1;
  Map<String, dynamic>? _availabilityResult;
  bool _isCheckingAvailability = false;

  final int _descriptionMaxLinesCollapsed = 4;
  bool _isDescriptionExpanded = false;

  final GlobalKey _bookingActionsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchTourDetails(widget.tourId);
  }

  void _initTabController() {
    if (_tourDetails != null && mounted) {
      int tabCount = 0;
      if (_tourDetails!.itineraryItems.isNotEmpty) tabCount++;
      if (_tourDetails!.features.isNotEmpty) tabCount++;
      // Gallery tab will show main image if no other images
      if (_tourDetails!.images.isNotEmpty ||
          (_tourDetails!.mainImageUrl != null &&
              _tourDetails!.mainImageUrl!.isNotEmpty))
        tabCount++;

      if (tabCount > 0) {
        _tabController = TabController(length: tabCount, vsync: this);
      } else {
        _tabController = null;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController?.dispose();
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

  Future<void> _handleCheckAvailabilityAndBook(
    StateSetter SSetter, {
    DateTime? selectedDate,
    int? groupSize,
  }) async {
    final dateToUse = selectedDate ?? _selectedStartDate;
    final sizeToUse = groupSize ?? _groupSize;

    if (dateToUse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a start date first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    if (_tourDetails == null || !mounted) return;

    SSetter(() => _isCheckingAvailability = true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      final isSimulatedAvailable =
          sizeToUse <= 10 && _tourDetails!.maxGroupSize >= sizeToUse;
      final result = {
        "isAvailable": isSimulatedAvailable,
        "totalPrice":
            isSimulatedAvailable ? _tourDetails!.displayPrice * sizeToUse : 0.0,
        "message":
            isSimulatedAvailable
                ? "Tour is available!"
                : "Tour not available for selected criteria.",
        "date": dateToUse.toIso8601String(),
        "guests": sizeToUse,
      };

      if (mounted) {
        SSetter(() {
          _availabilityResult = result;
          _isCheckingAvailability = false;
        });
        if (result["isAvailable"] == true) {
          // TODO: Proceed to actual booking screen/flow
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Available! Total: \$${result["totalPrice"]}. Implement booking flow.',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SSetter(() {
          _availabilityResult = {"isAvailable": false, "message": e.toString()};
          _isCheckingAvailability = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: "Back to Tours",
        ),
        title: Text(
          _tourDetails?.name ?? 'Tour Details',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return _buildErrorWidget();
    }
    if (_tourDetails == null) {
      return const Center(
        child: Text(
          'Tour details not available.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double wideLayoutBreakpoint = 1050.0;

        if (constraints.maxWidth > wideLayoutBreakpoint) {
          return _buildWideScreenLayout(_tourDetails!, constraints);
        } else {
          return _buildNarrowScreenLayout(_tourDetails!);
        }
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 50),
            const SizedBox(height: 16),
            Text(
              'Error loading tour details',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? "An unknown error occurred.",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _fetchTourDetails(widget.tourId),
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideScreenLayout(Tour tour, BoxConstraints constraints) {
    final double bookingPanelWidth =
        constraints.maxWidth * 0.28 > 320
            ? (constraints.maxWidth * 0.28 < 380
                ? constraints.maxWidth * 0.28
                : 380)
            : 320;
    final double remainingWidth =
        constraints.maxWidth - bookingPanelWidth - 24 - 24;
    final double imageFlex = 5.5;
    final double contentFlex = 4.5;
    final double totalFlex = imageFlex + contentFlex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: (remainingWidth * (imageFlex / totalFlex)) - 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageCarousel(
                  tour,
                  height: (remainingWidth * (imageFlex / totalFlex) * (9 / 16)),
                ),
                const SizedBox(height: 20),
                _buildTourPrimaryInfo(tour),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                width: (remainingWidth * (contentFlex / totalFlex)) - 12,
                child:
                    _tabController != null
                        ? _buildInfoTabs(tour)
                        : const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: bookingPanelWidth,
            child: _buildBookingActionsCard(tour, isSidebar: true),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowScreenLayout(Tour tour) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildImageCarousel(
          tour,
          height: MediaQuery.of(context).size.width * 0.65,
        ),
        const SizedBox(height: 20),
        _buildTourPrimaryInfo(tour),
        const SizedBox(height: 24),
        if (_tabController != null) _buildInfoTabs(tour),
        const SizedBox(height: 24),
        Padding(
          // key: _bookingActionsKey, // Not strictly needed if not programmatically scrolling to it
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: GradientButton(
            text: "Check Availability & Book",
            onPressed: () => _showBookingModal(context, tour),
            width: double.infinity,
            icon: Icons.calendar_today_outlined,
            height: 50,
          ),
        ),
      ],
    );
  }

  void _showBookingModal(BuildContext context, Tour tour) {
    // Use local state for the modal
    DateTime? modalSelectedDate =
        _selectedStartDate; // Initialize with screen state
    int modalGroupSize = _groupSize; // Initialize with screen state
    Map<String, dynamic>? modalAvailabilityResult =
        _availabilityResult; // Initialize
    bool modalIsCheckingAvailability = _isCheckingAvailability; // Initialize

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.80,
              padding: EdgeInsets.only(
                // REMOVED const here
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Book Your Tour",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border, thickness: 0.5),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildAvailabilityCheckerSection(
                        currencyFormatter: NumberFormat.currency(
                          locale: 'en_US',
                          symbol: '\$',
                        ),
                        isModal: true,
                        modalSetState: modalSetState,
                        currentSelectedDate: modalSelectedDate,
                        currentGroupSize: modalGroupSize,
                        currentAvailabilityResult: modalAvailabilityResult,
                        isCurrentlyChecking: modalIsCheckingAvailability,
                        onDateChanged: (date) {
                          modalSetState(() {
                            modalSelectedDate = date;
                            // Also update the main screen state if you want them to be in sync
                            _selectedStartDate = date;
                            modalAvailabilityResult = null; // Reset on change
                            _availabilityResult = null;
                          });
                        },
                        onGroupSizeChanged: (size) {
                          modalSetState(() {
                            modalGroupSize = size ?? 1;
                            _groupSize = size ?? 1;
                            modalAvailabilityResult = null;
                            _availabilityResult = null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImageCarousel(Tour tour, {double? height}) {
    final images =
        tour.images.isNotEmpty
            ? tour.images
            : (tour.mainImageUrl != null && tour.mainImageUrl!.isNotEmpty
                ? [
                  TourImage(
                    id: 0,
                    imageUrl: tour.mainImageUrl!,
                    displayOrder: 0,
                  ),
                ]
                : [
                  TourImage(
                    id: 0,
                    imageUrl:
                        "https://placehold.co/800x500/1E293B/E0E0E0?text=No+Image+Available",
                    displayOrder: 0,
                  ),
                ]);

    return Container(
      height: height ?? MediaQuery.of(context).size.width * 0.6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) {
                if (mounted) setState(() => _currentImageIndex = index);
              },
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: images[index].imageUrl,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Shimmer.fromColors(
                        baseColor: AppColors.surface.withOpacity(0.8),
                        highlightColor: AppColors.surfaceLight.withOpacity(0.8),
                        child: Container(color: AppColors.surface),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: AppColors.surface,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textSecondary,
                          size: 50,
                        ),
                      ),
                );
              },
            ),
            if (images.length > 1)
              Positioned(
                bottom: 12.0,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      images.map((image) {
                        int idx = images.indexOf(image);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _currentImageIndex == idx ? 10.0 : 7.0,
                          height: _currentImageIndex == idx ? 10.0 : 7.0,
                          margin: const EdgeInsets.symmetric(horizontal: 3.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _currentImageIndex == idx
                                    ? AppColors.primary
                                    : Colors.white.withOpacity(0.7),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            if (tour.hasDiscount && tour.discountPercentage != null)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '-${tour.discountPercentage}% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTourPrimaryInfo(Tour tour) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tour.name,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16.0,
          runSpacing: 8.0,
          children: [
            _buildInfoChip(
              icon: Icons.location_on_outlined,
              text: tour.location,
            ),
            _buildInfoChip(
              icon: Icons.timer_outlined,
              text: "${tour.durationInDays} days",
            ),
            _buildInfoChip(
              icon: Icons.group_outlined,
              text: "Max ${tour.maxGroupSize} people",
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            _buildTagChip(tour.difficultyLevel, AppColors.primary),
            _buildTagChip(tour.category, AppColors.accent),
            _buildTagChip(tour.activityType, AppColors.success),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          tour.description,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary.withOpacity(0.9),
            height: 1.6,
            letterSpacing: 0.1,
          ),
          maxLines:
              _isDescriptionExpanded ? null : _descriptionMaxLinesCollapsed,
          overflow:
              _isDescriptionExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
        ),
        if (!_isDescriptionExpanded &&
            (tour.description.length > 150 ||
                tour.description.split('\n').length >
                    _descriptionMaxLinesCollapsed))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: InkWell(
              onTap:
                  () => setState(
                    () => _isDescriptionExpanded = !_isDescriptionExpanded,
                  ),
              child: Text(
                _isDescriptionExpanded ? "Show less" : "Show more...",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTagChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBookingActionsCard(Tour tour, {bool isSidebar = false}) {
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
    );
    return Card(
      // key: _bookingActionsKey, // No longer strictly needed for scrolling if it's a fixed sidebar
      elevation: isSidebar ? 5 : 2,
      shadowColor: Colors.black.withOpacity(0.2),
      color: AppColors.surfaceSlightlyLighter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin:
          isSidebar
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Book This Tour",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  currencyFormatter.format(tour.displayPrice),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Text(
                  "per person",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              Icons.timer_outlined,
              "Duration:",
              "${tour.durationInDays} days",
            ),
            _buildInfoRow(
              Icons.group_outlined,
              "Max group size:",
              "${tour.maxGroupSize} people",
            ),

            const SizedBox(height: 16),
            const Divider(color: AppColors.border, thickness: 0.5),
            const SizedBox(height: 16),
            _buildAvailabilityCheckerSection(
              currencyFormatter: currencyFormatter,
              modalSetState:
                  setState, // Sidebar uses the main screen's setState
              currentSelectedDate: _selectedStartDate,
              currentGroupSize: _groupSize,
              currentAvailabilityResult: _availabilityResult,
              isCurrentlyChecking: _isCheckingAvailability,
              isModal: false, // Explicitly false for sidebar
              onDateChanged:
                  (date) => setState(() {
                    _selectedStartDate = date;
                    _availabilityResult = null; // Reset on change
                  }),
              onGroupSizeChanged:
                  (size) => setState(() {
                    _groupSize = size ?? 1;
                    _availabilityResult = null; // Reset on change
                  }),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                "Free cancellation up to 24 hours before the tour.",
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityCheckerSection({
    required NumberFormat currencyFormatter,
    bool isModal = false,
    required StateSetter modalSetState,
    DateTime? currentSelectedDate,
    int? currentGroupSize,
    Map<String, dynamic>? currentAvailabilityResult,
    bool? isCurrentlyChecking,
    Function(DateTime?)? onDateChanged,
    Function(int?)? onGroupSizeChanged,
  }) {
    final DateFormat dateFormat = DateFormat('MMM dd, yyyy');
    final DateTime? effectiveSelectedDate = currentSelectedDate;
    final int effectiveGroupSize = currentGroupSize ?? 1;
    final Map<String, dynamic>? effectiveAvailabilityResult =
        currentAvailabilityResult;
    final bool effectiveIsChecking = isCurrentlyChecking ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select Date & Guests",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate:
                  effectiveSelectedDate ??
                  DateTime.now().add(const Duration(days: 1)),
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
            if (picked != null && picked != effectiveSelectedDate) {
              if (onDateChanged != null) {
                onDateChanged(picked);
              }
              modalSetState(() {}); // Trigger rebuild of modal/sidebar
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'Select start date',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
              prefixIcon: const Icon(
                Icons.calendar_today_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              filled: true,
              fillColor: AppColors.background.withOpacity(0.7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.border.withOpacity(0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.border.withOpacity(0.5),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
            ),
            child: Text(
              effectiveSelectedDate != null
                  ? dateFormat.format(effectiveSelectedDate)
                  : 'Select start date',
              style: TextStyle(
                color:
                    effectiveSelectedDate != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary.withOpacity(0.7),
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            hintText: 'Number of guests',
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
            prefixIcon: const Icon(
              Icons.group_add_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            filled: true,
            fillColor: AppColors.background.withOpacity(0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
          ),
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          value: effectiveGroupSize,
          items:
              List.generate(
                    _tourDetails?.maxGroupSize ?? 1,
                    (index) => index + 1,
                  )
                  .map(
                    (size) => DropdownMenuItem(
                      value: size,
                      child: Text('$size Guest${size > 1 ? 's' : ''}'),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            if (value != null) {
              if (onGroupSizeChanged != null) {
                onGroupSizeChanged(value);
              }
              modalSetState(() {}); // Trigger rebuild
            }
          },
        ),
        const SizedBox(height: 20),

        if (effectiveAvailabilityResult != null && !effectiveIsChecking) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (effectiveAvailabilityResult['isAvailable'] == true
                        ? AppColors.success
                        : AppColors.error)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (effectiveAvailabilityResult['isAvailable'] == true
                          ? AppColors.success
                          : AppColors.error)
                      .withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    effectiveAvailabilityResult['isAvailable'] == true
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color:
                        effectiveAvailabilityResult['isAvailable'] == true
                            ? AppColors.success
                            : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          effectiveAvailabilityResult['message'] as String? ??
                              (effectiveAvailabilityResult['isAvailable'] ==
                                      true
                                  ? 'Available!'
                                  : 'Not Available'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                effectiveAvailabilityResult['isAvailable'] ==
                                        true
                                    ? AppColors.success
                                    : AppColors.error,
                          ),
                        ),
                        if (effectiveAvailabilityResult['isAvailable'] ==
                            true) ...[
                          Text(
                            'Total: ${currencyFormatter.format(effectiveAvailabilityResult['totalPrice'])}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        GradientButton(
          text: "Book Now",
          isLoading: effectiveIsChecking,
          onPressed:
              () => _handleCheckAvailabilityAndBook(
                modalSetState,
                selectedDate: effectiveSelectedDate,
                groupSize: effectiveGroupSize,
              ),
          width: double.infinity,
          icon: Icons.payment_outlined,
          height: 48,
        ),
      ],
    );
  }

  Widget _buildInfoTabs(Tour tour) {
    if (_tabController == null || _tabController!.length == 0)
      return const SizedBox.shrink();

    List<Widget> tabViews = [];
    List<Tab> tabs = [];

    if (tour.itineraryItems.isNotEmpty) {
      tabs.add(const Tab(text: 'Itinerary'));
      tabViews.add(_buildItineraryList(tour.itineraryItems));
    }
    if (tour.features.isNotEmpty) {
      tabs.add(const Tab(text: 'Features'));
      tabViews.add(_buildFeaturesList(tour.features));
    }
    final tourImagesForGallery =
        tour.images.isNotEmpty
            ? tour.images
            : (tour.mainImageUrl != null
                ? [
                  TourImage(
                    id: 0,
                    imageUrl: tour.mainImageUrl!,
                    displayOrder: 0,
                  ),
                ]
                : []);
    if (tourImagesForGallery.isNotEmpty) {
      tabs.add(const Tab(text: 'Gallery'));
      tabViews.add(_buildGalleryView(tourImagesForGallery.cast<TourImage>()));
    }

    if (tabs.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: tabs,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children:
                tabViews
                    .map(
                      (view) => Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: view,
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildItineraryList(List<ItineraryItem> itineraryItems) {
    if (itineraryItems.isEmpty)
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No itinerary details available.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ),
      );

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itineraryItems.length,
      separatorBuilder:
          (context, index) => const Divider(
            color: AppColors.border,
            height: 0.5,
            indent: 16,
            endIndent: 16,
          ),
      itemBuilder: (context, index) {
        final item = itineraryItems[index];
        return ExpansionTile(
          key: PageStorageKey('itinerary_day_${item.dayNumber}_${item.id}'),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSecondary,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          title: Text(
            'Day ${item.dayNumber}: ${item.title}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
                top: 4.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                  if (item.location != null ||
                      (item.startTime != null || item.endTime != null)) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (item.location != null) ...[
                          const Icon(
                            Icons.pin_drop_outlined,
                            size: 15,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              item.location!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ],
                        if (item.location != null &&
                            (item.startTime != null || item.endTime != null))
                          const SizedBox(width: 10),
                        if (item.startTime != null || item.endTime != null) ...[
                          const Icon(
                            Icons.access_time_outlined,
                            size: 15,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "${item.startTime ?? ''} - ${item.endTime ?? ''}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
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

  Widget _buildFeaturesList(List<TourFeature> features) {
    if (features.isEmpty)
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No special features listed.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ),
      );
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.name,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (feature.description != null &&
                        feature.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        feature.description!,
                        style: const TextStyle(
                          fontSize: 13,
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
      },
    );
  }

  Widget _buildGalleryView(List<TourImage> images) {
    if (images.isEmpty)
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No images in gallery.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ),
      );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(4.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder:
                  (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(10),
                    child: InteractiveViewer(
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
                    ),
                  ),
            );
          },
          child: Hero(
            tag: "gallery_image_${images[index].id}",
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: images[index].imageUrl,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Shimmer.fromColors(
                      baseColor: AppColors.surface.withOpacity(0.5),
                      highlightColor: AppColors.surfaceLight.withOpacity(0.5),
                      child: Container(color: AppColors.surface),
                    ),
                errorWidget:
                    (context, url, error) => const Icon(
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary.withOpacity(0.8)),
          const SizedBox(width: 10),
          Text(
            '$label ',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Add this to your constants/colors.dart if it's not already there
// class AppColors {
//   ...
//   static const Color surfaceSlightlyLighter = Color(0xFF27344A);
//   ...
// }
