import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../constants/routes.dart';
import '../../models/tour_models.dart';
import '../../services/auth_service.dart';
import '../../services/tour_service.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/responsive_layout.dart';
import '../../widgets/tours/tour_grid.dart';
import '../../widgets/tours/tour_search_bar.dart';
import 'tour_filters.dart';

class TourListScreen extends StatefulWidget {
  const TourListScreen({super.key});

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

  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _listFadeAnimation;

  @override
  void initState() {
    super.initState();

    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _listFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listAnimationController, curve: Curves.easeOut),
    );

    _headerAnimationController.forward();
    _loadTours();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (!_isLoadingMore && _currentPage < _totalPages) {
          _loadMoreTours();
        }
      }
    });

    // Search debouncing
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Simple debouncing - in production, consider using a proper debouncer
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _searchController.text.length >= 2) {
        _loadTours();
      } else if (mounted && _searchController.text.isEmpty) {
        _loadTours();
      }
    });
  }

  Future<void> _loadTours() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _tours = [];
        _currentPage = 1;
      });

      int pageSize = _calculatePageSize();

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
        _listAnimationController.forward();
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
    if (_isLoadingMore || _isLoading) return;

    try {
      if (mounted) {
        setState(() {
          _isLoadingMore = true;
        });
      }

      int pageSize = _calculatePageSize();

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

  int _calculatePageSize() {
    if (!mounted) return 10;

    final crossAxisCount = context.tourGridCrossAxisCount;
    return crossAxisCount * 4; // Load 4 rows at a time
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

  bool get _hasActiveFilters {
    return _selectedLocation != null ||
        _selectedCategory != null ||
        _selectedDifficulty != null ||
        _selectedActivity != null ||
        _minPrice != null ||
        _maxPrice != null;
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
              _buildHeader(authService),
              _buildSearchSection(),
              if (_hasActiveFilters) _buildActiveFiltersBar(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthService authService) {
    return FadeTransition(
      opacity: _headerFadeAnimation,
      child: SlideTransition(
        position: _headerSlideAnimation,
        child: Container(
          padding: EdgeInsets.all(context.isMobile ? 20 : 24),
          child: Row(
            children: [
              _buildLogo(),
              const SizedBox(width: AppStyles.spacingMD),
              Expanded(child: _buildHeaderText()),
              _buildProfileMenu(authService),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: context.isMobile ? 50 : 60,
      height: context.isMobile ? 50 : 60,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppStyles.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.explore,
        color: Colors.white,
        size: context.isMobile ? 28 : 32,
      ),
    );
  }

  Widget _buildHeaderText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wanderlust',
          style: (context.isMobile
                  ? AppStyles.headingSmall
                  : AppStyles.headingMedium)
              .copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          'Discover Your Next Adventure',
          style: AppStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: context.isMobile ? 12 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMenu(AuthService authService) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'logout':
            await authService.logout();
            if (mounted) {
              Navigator.of(context).pushReplacementNamed(Routes.login);
            }
            break;
          case 'profile':
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Profile clicked')));
            break;
          case 'bookings':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('My Bookings clicked')),
            );
            break;
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
        padding: const EdgeInsets.all(AppStyles.spacingSM),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(AppStyles.radiusMD),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: const Icon(
          Icons.more_vert,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return TourSearchBar(
      controller: _searchController,
      hintText: 'Search destinations, tours, activities...',
      onSearch: _loadTours,
      onFilter: _showFilters,
      hasActiveFilters: _hasActiveFilters,
      isLoading: _isLoading,
    );
  }

  Widget _buildActiveFiltersBar() {
    final activeFilters = <String>[];
    if (_selectedLocation != null) {
      activeFilters.add('Location: $_selectedLocation');
    }
    if (_selectedCategory != null) {
      activeFilters.add('Category: $_selectedCategory');
    }
    if (_selectedDifficulty != null) {
      activeFilters.add('Difficulty: $_selectedDifficulty');
    }
    if (_selectedActivity != null) {
      activeFilters.add('Activity: $_selectedActivity');
    }
    if (_minPrice != null || _maxPrice != null) {
      activeFilters.add(
        'Price: \$${_minPrice?.toInt() ?? 0} - \$${_maxPrice?.toInt() ?? 'Any'}',
      );
    }

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: AppStyles.spacingSM),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingMD),
        itemCount: activeFilters.length + 1,
        separatorBuilder:
            (context, index) => const SizedBox(width: AppStyles.spacingSM),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildClearFiltersChip();
          }
          return _buildFilterChip(activeFilters[index - 1]);
        },
      ),
    );
  }

  Widget _buildClearFiltersChip() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLocation = null;
          _selectedCategory = null;
          _selectedDifficulty = null;
          _selectedActivity = null;
          _minPrice = null;
          _maxPrice = null;
        });
        _loadTours();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacingMD,
          vertical: AppStyles.spacingSM,
        ),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.clear_all, color: AppColors.error, size: 16),
            const SizedBox(width: AppStyles.spacingXS),
            Text(
              'Clear All',
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingMD,
        vertical: AppStyles.spacingSM,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: Text(
        filter,
        style: AppStyles.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
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

    return FadeTransition(
      opacity: _listFadeAnimation,
      child: TourGrid(
        tours: _tours,
        isLoading: false,
        isLoadingMore: _isLoadingMore,
        onRefresh: _loadTours,
        onLoadMore: _loadMoreTours,
        scrollController: _scrollController,
      ),
    );
  }

  Widget _buildLoadingState() {
    return TourGrid(
      tours: const [],
      isLoading: true,
      padding: EdgeInsets.all(context.isMobile ? 16 : 24),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.isMobile ? 20 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppStyles.spacingLG),
            Text(
              'Oops! Something went wrong',
              style: AppStyles.headingSmall.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.spacingSM),
            Text(
              _error ?? 'Failed to load tours. Please check your connection.',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.spacingXL),
            ElevatedButton.icon(
              onPressed: _loadTours,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: AppStyles.primaryButtonStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.isMobile ? 20 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: AppColors.border.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.explore_off_outlined,
                size: 50,
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
            const SizedBox(height: AppStyles.spacingXL),
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
              style: AppStyles.primaryButtonStyle,
            ),
          ],
        ),
      ),
    );
  }
}
