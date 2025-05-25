import 'package:flutter/material.dart';
import 'package:wanderlust/widgets/common/gradient_button.dart';
import '../../constants/colors.dart';
import '../../widgets/common/glass_card.dart';

class TourFilters extends StatefulWidget {
  final String? selectedLocation;
  final String? selectedCategory;
  final String? selectedDifficulty;
  final String? selectedActivity;
  final double? minPrice;
  final double? maxPrice;
  final String sortBy;
  final bool ascending;
  final Function(Map<String, dynamic>) onApplyFilters;

  const TourFilters({
    Key? key,
    this.selectedLocation,
    this.selectedCategory,
    this.selectedDifficulty,
    this.selectedActivity,
    this.minPrice,
    this.maxPrice,
    required this.sortBy,
    required this.ascending,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  State<TourFilters> createState() => _TourFiltersState();
}

class _TourFiltersState extends State<TourFilters> {
  late String? _location;
  late String? _category;
  late String? _difficulty;
  late String? _activity;
  late RangeValues _priceRange;
  late String _sortBy;
  late bool _ascending;

  // Dummy data for filter options - replace with actual data source if available
  final List<String> _locations = [
    'Paris',
    'Rome',
    'Tokyo',
    'New York',
    'London',
    'Bali',
  ];
  final List<String> _categories = [
    'Adventure',
    'Cultural',
    'Relaxation',
    'Nature',
    'City Tour',
  ];
  final List<String> _difficulties = [
    'Easy',
    'Moderate',
    'Challenging',
    'Expert',
  ];
  final List<String> _activities = [
    'Hiking',
    'Sightseeing',
    'Water Sports',
    'Culinary',
    'Historical',
  ];
  final Map<String, String> _sortOptions = {
    'name': 'Name',
    'price': 'Price',
    'durationInDays': 'Duration',
    'averageRating': 'Rating',
  };

  final double _minPriceLimit = 0;
  final double _maxPriceLimit = 5000;

  @override
  void initState() {
    super.initState();
    _location = widget.selectedLocation;
    _category = widget.selectedCategory;
    _difficulty = widget.selectedDifficulty;
    _activity = widget.selectedActivity;
    _priceRange = RangeValues(
      widget.minPrice ?? _minPriceLimit,
      widget.maxPrice ?? _maxPriceLimit,
    );
    _sortBy = widget.sortBy;
    _ascending = widget.ascending;
  }

  void _applyFilters() {
    final filters = {
      'location': _location,
      'category': _category,
      'difficulty': _difficulty,
      'activity': _activity,
      'minPrice':
          _priceRange.start == _minPriceLimit ? null : _priceRange.start,
      'maxPrice': _priceRange.end == _maxPriceLimit ? null : _priceRange.end,
      'sortBy': _sortBy,
      'ascending': _ascending,
    };
    widget.onApplyFilters(filters);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _location = null;
      _category = null;
      _difficulty = null;
      _activity = null;
      _priceRange = RangeValues(_minPriceLimit, _maxPriceLimit);
      _sortBy = 'name'; // Default sort
      _ascending = true;
    });
    // Optionally apply immediately or wait for explicit apply
    // _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.85, // Adjust height as needed
      child: GlassCard(
        borderRadius: 16,
        backgroundColor: AppColors.backgroundSecondary.withOpacity(0.95),
        padding: const EdgeInsets.all(0), // No padding on GlassCard itself
        child: ClipRRect(
          // ClipRRect to ensure content respects border radius
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  children: [
                    _buildDropdownFilter(
                      'Location',
                      _locations,
                      _location,
                      (val) => setState(() => _location = val),
                    ),
                    _buildDropdownFilter(
                      'Category',
                      _categories,
                      _category,
                      (val) => setState(() => _category = val),
                    ),
                    _buildDropdownFilter(
                      'Difficulty',
                      _difficulties,
                      _difficulty,
                      (val) => setState(() => _difficulty = val),
                    ),
                    _buildDropdownFilter(
                      'Activity Type',
                      _activities,
                      _activity,
                      (val) => setState(() => _activity = val),
                    ),
                    _buildPriceRangeFilter(),
                    _buildSortFilter(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Filters & Sort',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
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

  Widget _buildDropdownFilter(
    String title,
    List<String> items,
    String? currentValue,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: currentValue,
            items:
                items
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface.withOpacity(0.7),
              hintText: 'Any $title',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: AppColors.textPrimary),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRangeFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Range',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _priceRange,
            min: _minPriceLimit,
            max: _maxPriceLimit,
            divisions: 100, // Adjust for granularity
            labels: RangeLabels(
              '\$${_priceRange.start.round()}',
              '\$${_priceRange.end.round()}',
            ),
            onChanged: (values) {
              setState(() {
                _priceRange = values;
              });
            },
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary.withOpacity(0.3),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${_priceRange.start.round()}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                '\$${_priceRange.end.round()}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sort By',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  items:
                      _sortOptions.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _sortBy = val!),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface.withOpacity(0.7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                  isExpanded: true,
                ),
              ),
              const SizedBox(width: 12),
              GlassCard(
                padding: const EdgeInsets.all(
                  0,
                ), // No padding on GlassCard itself for IconButton
                borderRadius: 10,
                backgroundColor: AppColors.surface.withOpacity(0.7),
                child: IconButton(
                  icon: Icon(
                    _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      _ascending = !_ascending;
                    });
                  },
                  tooltip: _ascending ? 'Ascending' : 'Descending',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.5), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _resetFilters,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: AppColors.border.withOpacity(0.7)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Reset',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GradientButton(
              text: 'Apply Filters',
              onPressed: _applyFilters,
              height: 50, // Match OutlinedButton height
            ),
          ),
        ],
      ),
    );
  }
}
