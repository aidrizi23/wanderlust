import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants/colors.dart';
import '../../constants/routes.dart';
import '../../models/tour_models.dart';
import '../../services/auth_service.dart';
import '../../services/tour_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/common/glass_card.dart';
import 'tour_card.dart';
import 'tour_filters.dart';

class TourListScreen extends StatefulWidget {
  const TourListScreen({Key? key}) : super(key: key);

  @override
  State<TourListScreen> createState() => _TourListScreenState();
}

class _TourListScreenState extends State<TourListScreen> with TickerProviderStateMixin {
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
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
    _loadTours();
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
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
      });
      
      final response = await _tourService.getTours(
        searchTerm: _searchController.text.isNotEmpty ? _searchController.text : null,
        location: _selectedLocation,
        category: _selectedCategory,
        difficultyLevel: _selectedDifficulty,
        activityType: _selectedActivity,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sortBy: _sortBy,
        ascending: _ascending,
        pageIndex: 1,
        pageSize: 10,
      );
      
      setState(() {
        _tours = response.items;
        _currentPage = response.pageIndex;
        _totalPages = response.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreTours() async {
    if (_isLoadingMore) return;
    
    try {
      setState(() {
        _isLoadingMore = true;
      });
      
      final response = await _tourService.getTours(
        searchTerm: _searchController.text.isNotEmpty ? _searchController.text : null,
        location: _selectedLocation,
        category: _selectedCategory,
        difficultyLevel: _selectedDifficulty,
        activityType: _selectedActivity,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sortBy: _sortBy,
        ascending: _ascending,
        pageIndex: _currentPage + 1,
        pageSize: 10,
      );
      
      setState(() {
        _tours.addAll(response.items);
        _currentPage = response.pageIndex;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TourFilters(
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
    final isDesktop = Responsive.isDesktop(context);
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(authService),
              _buildSearchBar(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildContent(isDesktop),
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
            child: const Icon(
              Icons.explore,
              color: Colors.white,
              size: 28,
            ),
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
              }
            },
            itemBuilder: (context) => [
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
                    Icon(Icons.booking_outlined, size: 20),
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
              child: const Icon(
                Icons.more_vert,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final hasFilters = _selectedLocation != null ||
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
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary),
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
            child: InkWell(
              onTap: _showFilters,
              child: Stack(
                children: [
                  Icon(
                    Icons.tune,
                    color: hasFilters ? AppColors.primary : AppColors.textSecondary,
                  ),
                  if (hasFilters)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
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

  Widget _buildContent(bool isDesktop) {
    if (_isLoading) {
      return _buildLoadingState(isDesktop);
    }
    
    if (_error != null) {
      return _buildErrorState();
    }
    
    if (_tours.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildTourGrid(isDesktop);
  }

  Widget _buildLoadingState(bool isDesktop) {
    final crossAxisCount = isDesktop ? 4 : 2;
    
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isDesktop ? 0.8 : 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 8,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Failed to load tours',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadTours,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No tours found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search term',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
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
              });
              _loadTours();
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildTourGrid(bool isDesktop) {
    final crossAxisCount = ResponsiveValue(
      mobile: 1,
      tablet: 2,
      desktop: 4,
    ).get(context);
    
    return RefreshIndicator(
      onRefresh: _loadTours,
      color: AppColors.primary,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: isDesktop ? 0.8 : (Responsive.