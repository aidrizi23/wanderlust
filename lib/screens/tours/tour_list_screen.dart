import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:cached_network_image/cached_network_image.dart'; // Not used directly in this file
import 'package:shimmer/shimmer.dart';
import '../../constants/colors.dart';
import '../../constants/routes.dart';
import '../../models/tour_models.dart';
import '../../services/auth_service.dart';
import '../../services/tour_service.dart';
// import '../../utils/responsive.dart'; // Using MediaQuery directly for more granular control
import '../../widgets/common/glass_card.dart';
import 'tour_card.dart';
import 'tour_filters.dart';

class TourListScreen extends StatefulWidget {
  const TourListScreen({Key? key}) : super(key: key);

  @override
  State<TourListScreen> createState() => _TourListScreenState();
}

class _TourListScreenState extends State<TourListScreen>
    with TickerProviderStateMixin {
  final TourService _tourService = TourService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Tour> _tours = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;

  // Filters
  String? _selectedLocation;
  String? _selectedCategory;
  String? _selectedDifficulty;
  String? _selectedActivity;
  double? _minPrice;
  double? _maxPrice;
  String _sortBy = 'name';
  bool _ascending = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
    _loadTours();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (!_isLoadingMore && _currentPage < _totalPages) {
          _loadMoreTours();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTours() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _tours = []; // Clear previous tours before new load
        _currentPage = 1; // Reset current page
      });

      // Determine pageSize based on typical columns to fetch enough items
      // This ensures a smoother initial load that fills the screen better.
      // Needs to be called within a context-aware part or passed if called from initState.
      // For initState, we might use a default or estimate.
      // Let's use a default for now in initState, and adjust if context is available (e.g. in build or didChangeDependencies)
      // However, since _loadTours can be called from various places, we get context here if possible.
      int pageSize = 10; // Default
      if (mounted) {
        // Check if the widget is mounted to safely access context
        final screenWidth = MediaQuery.of(context).size.width;
        if (screenWidth >= 1600)
          pageSize = 18; // 6 columns * 3 rows
        else if (screenWidth >= 1200)
          pageSize = 15; // 5 columns * 3 rows
        else if (screenWidth >= 800)
          pageSize = 12; // 4 columns * 3 rows
        else if (screenWidth >= 600)
          pageSize = 9; // 3 columns * 3 rows
        else
          pageSize = 8; // 2 columns * 4 rows
      }

      final response = await _tourService.getTours(
        searchTerm:
            _searchController.text.isNotEmpty ? _searchController.text : null,
        location: _selectedLocation,
        category: _selectedCategory,
        difficultyLevel: _selectedDifficulty,
        activityType: _selectedActivity,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sortBy: _sortBy,
        ascending: _ascending,
        pageIndex: 1,
        pageSize: pageSize,
      );

      if (mounted) {
        setState(() {
          _tours = response.items;
          _currentPage = response.pageIndex;
          _totalPages = response.totalPages;
          _isLoading = false;
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

  Future<void> _loadMoreTours() async {
    if (_isLoadingMore || _isLoading) return; // Prevent multiple calls

    try {
      if (mounted) {
        setState(() {
          _isLoadingMore = true;
        });
      }

      int pageSize = 10; // Default
      if (mounted) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (screenWidth >= 1600)
          pageSize = 12;
        else if (screenWidth >= 1200)
          pageSize = 10;
        else if (screenWidth >= 800)
          pageSize = 8;
        else if (screenWidth >= 600)
          pageSize = 6;
        else
          pageSize = 6;
      }

      final response = await _tourService.getTours(
        searchTerm:
            _searchController.text.isNotEmpty ? _searchController.text : null,
        location: _selectedLocation,
        category: _selectedCategory,
        difficultyLevel: _selectedDifficulty,
        activityType: _selectedActivity,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sortBy: _sortBy,
        ascending: _ascending,
        pageIndex: _currentPage + 1,
        pageSize: pageSize,
      );

      if (mounted) {
        setState(() {
          _tours.addAll(response.items);
          _currentPage = response.pageIndex;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => TourFilters(
            selectedLocation: _selectedLocation,
            selectedCategory: _selectedCategory,
            selectedDifficulty: _selectedDifficulty,
            selectedActivity: _selectedActivity,
            minPrice: _minPrice,
            maxPrice: _maxPrice,
            sortBy: _sortBy,
            ascending: _ascending,
            onApplyFilters: (filters) {
              setState(() {
                _selectedLocation = filters['location'];
                _selectedCategory = filters['category'];
                _selectedDifficulty = filters['difficulty'];
                _selectedActivity = filters['activity'];
                _minPrice = filters['minPrice'];
                _maxPrice = filters['maxPrice'];
                _sortBy = filters['sortBy'] ?? 'name';
                _ascending = filters['ascending'] ?? true;
              });
              _loadTours();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(authService),
              _buildSearchBar(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(AuthService authService) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.explore, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wanderlust',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Discover Your Next Adventure',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await authService.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed(Routes.login);
                }
              } else if (value == 'profile') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile clicked')),
                );
              } else if (value == 'bookings') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('My Bookings clicked')),
                );
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 20),
                        SizedBox(width: 12),
                        Text('Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'bookings',
                    child: Row(
                      children: [
                        Icon(Icons.event_note_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('My Bookings'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20),
                        SizedBox(width: 12),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final hasFilters =
        _selectedLocation != null ||
        _selectedCategory != null ||
        _selectedDifficulty != null ||
        _selectedActivity != null ||
        _minPrice != null ||
        _maxPrice != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search tours...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.surface.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _loadTours();
                          },
                        )
                        : null,
              ),
              onSubmitted: (_) => _loadTours(),
            ),
          ),
          const SizedBox(width: 12),
          GlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 12,
            child: InkWell(
              onTap: _showFilters,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.tune_outlined,
                    color:
                        hasFilters
                            ? AppColors.primary
                            : AppColors.textSecondary,
                  ),
                  if (hasFilters)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _tours.isEmpty) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_tours.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return _buildTourGrid();
  }

  Widget _buildLoadingState() {
    final screenWidth = MediaQuery.of(context).size.width;
    int determinedCrossAxisCount;
    double determinedChildAspectRatio;

    if (screenWidth >= 1600) {
      // Very Large Desktop
      determinedCrossAxisCount = 6;
      determinedChildAspectRatio = 0.60;
    } else if (screenWidth >= 1200) {
      // Large Desktop
      determinedCrossAxisCount = 5;
      determinedChildAspectRatio = 0.65;
    } else if (screenWidth >= 900) {
      // Medium Desktop / Large Tablet
      determinedCrossAxisCount = 4;
      determinedChildAspectRatio = 0.68;
    } else if (screenWidth >= 600) {
      // Tablet
      determinedCrossAxisCount = 3;
      determinedChildAspectRatio = 0.75;
    } else {
      // Mobile
      determinedCrossAxisCount = 2;
      determinedChildAspectRatio = 0.75;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: determinedCrossAxisCount,
        childAspectRatio: determinedChildAspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: determinedCrossAxisCount * 2,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.surface,
          highlightColor: AppColors.surfaceLight,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Failed to load tours. Please check your connection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTours,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No tours found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search term.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedLocation = null;
                  _selectedCategory = null;
                  _selectedDifficulty = null;
                  _selectedActivity = null;
                  _minPrice = null;
                  _maxPrice = null;
                  _sortBy = 'name';
                  _ascending = true;
                });
                _loadTours();
              },
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTourGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    int determinedCrossAxisCount;
    double determinedChildAspectRatio;

    if (screenWidth >= 1600) {
      // Very Large Desktop
      determinedCrossAxisCount = 6;
      determinedChildAspectRatio = 0.60;
    } else if (screenWidth >= 1200) {
      // Large Desktop
      determinedCrossAxisCount = 5;
      determinedChildAspectRatio = 0.65;
    } else if (screenWidth >= 900) {
      // Medium Desktop / Large Tablet
      determinedCrossAxisCount = 4;
      determinedChildAspectRatio = 0.68;
    } else if (screenWidth >= 600) {
      // Tablet
      determinedCrossAxisCount = 3;
      determinedChildAspectRatio = 0.75;
    } else {
      // Mobile
      determinedCrossAxisCount = 2;
      determinedChildAspectRatio = 0.75;
    }

    return RefreshIndicator(
      onRefresh: _loadTours,
      color: AppColors.primary,
      backgroundColor: AppColors.backgroundSecondary,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: determinedCrossAxisCount,
          childAspectRatio: determinedChildAspectRatio,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount:
            _isLoadingMore
                ? _tours.length + determinedCrossAxisCount
                : _tours.length,
        itemBuilder: (context, index) {
          if (index >= _tours.length) {
            return Shimmer.fromColors(
              baseColor: AppColors.surface,
              highlightColor: AppColors.surfaceLight,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          }
          return TourCard(tour: _tours[index]);
        },
      ),
    );
  }
}
