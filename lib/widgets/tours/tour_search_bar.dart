import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/common/glass_card.dart';

class TourSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final VoidCallback? onSearch;
  final VoidCallback? onFilter;
  final ValueChanged<String>? onChanged;
  final bool hasActiveFilters;
  final bool isLoading;

  const TourSearchBar({
    Key? key,
    this.controller,
    this.hintText,
    this.onSearch,
    this.onFilter,
    this.onChanged,
    this.hasActiveFilters = false,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<TourSearchBar> createState() => _TourSearchBarState();
}

class _TourSearchBarState extends State<TourSearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.hasActiveFilters) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TourSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasActiveFilters != oldWidget.hasActiveFilters) {
      if (widget.hasActiveFilters) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingMD,
        vertical: AppStyles.spacingSM,
      ),
      child: Row(
        children: [
          Expanded(child: _buildSearchField()),
          const SizedBox(width: AppStyles.spacingMD),
          _buildFilterButton(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return AnimatedContainer(
      duration: AppStyles.animationMedium,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
        boxShadow:
            _isFocused
                ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                : [],
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        onSubmitted: (_) => widget.onSearch?.call(),
        style: AppStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Search destinations, tours...',
          hintStyle: AppStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary.withOpacity(0.7),
          ),
          prefixIcon:
              widget.isLoading
                  ? Container(
                    width: 20,
                    height: 20,
                    padding: const EdgeInsets.all(AppStyles.spacingMD),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.textSecondary,
                      ),
                    ),
                  )
                  : Icon(
                    Icons.search,
                    color:
                        _isFocused
                            ? AppColors.primary
                            : AppColors.textSecondary,
                    size: 20,
                  ),
          suffixIcon:
              _controller.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged?.call('');
                      widget.onSearch?.call();
                    },
                  )
                  : null,
          filled: true,
          fillColor: AppColors.surface.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusMD),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusMD),
            borderSide: BorderSide(
              color: AppColors.border.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusMD),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppStyles.spacingMD,
            vertical: AppStyles.spacingMD,
          ),
        ),
        onTap: () {
          setState(() => _isFocused = true);
        },
        onTapOutside: (_) {
          setState(() => _isFocused = false);
        },
      ),
    );
  }

  Widget _buildFilterButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.hasActiveFilters ? _pulseAnimation.value : 1.0,
          child: GlassCard(
            padding: const EdgeInsets.all(AppStyles.spacingMD),
            borderRadius: AppStyles.radiusMD,
            backgroundColor:
                widget.hasActiveFilters
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.surface.withOpacity(0.8),
            child: InkWell(
              onTap: widget.onFilter,
              borderRadius: BorderRadius.circular(AppStyles.radiusMD),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.tune,
                    color:
                        widget.hasActiveFilters
                            ? AppColors.primary
                            : AppColors.textSecondary,
                    size: 24,
                  ),
                  if (widget.hasActiveFilters)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class TourSearchBarCompact extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final VoidCallback? onTap;
  final bool readOnly;

  const TourSearchBarCompact({
    Key? key,
    this.controller,
    this.hintText,
    this.onTap,
    this.readOnly = false,
  }) : super(key: key);

  @override
  State<TourSearchBarCompact> createState() => _TourSearchBarCompactState();
}

class _TourSearchBarCompactState extends State<TourSearchBarCompact> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.readOnly ? widget.onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacingMD,
          vertical: AppStyles.spacingMD,
        ),
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
            Icon(Icons.search, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: AppStyles.spacingMD),
            Expanded(
              child:
                  widget.readOnly
                      ? Text(
                        widget.hintText ?? 'Search tours...',
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )
                      : TextField(
                        controller: _controller,
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.hintText ?? 'Search tours...',
                          hintStyle: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickSearchChips extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String>? onChipTap;

  const QuickSearchChips({Key? key, required this.suggestions, this.onChipTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingMD),
        itemCount: suggestions.length,
        separatorBuilder:
            (context, index) => const SizedBox(width: AppStyles.spacingSM),
        itemBuilder: (context, index) {
          return _buildSearchChip(suggestions[index]);
        },
      ),
    );
  }

  Widget _buildSearchChip(String text) {
    return GestureDetector(
      onTap: () => onChipTap?.call(text),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacingMD,
          vertical: AppStyles.spacingSM,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.border.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: AppStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class SearchSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String>? onSuggestionTap;
  final VoidCallback? onClear;

  const SearchSuggestions({
    Key? key,
    required this.suggestions,
    this.onSuggestionTap,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: AppStyles.spacingMD),
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onClear != null)
            ListTile(
              leading: Icon(
                Icons.clear_all,
                color: AppColors.textSecondary,
                size: 20,
              ),
              title: Text(
                'Clear search history',
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: onClear,
              dense: true,
            ),
          if (onClear != null)
            Divider(color: AppColors.border.withOpacity(0.3), height: 1),
          ...suggestions.map((suggestion) {
            return ListTile(
              leading: Icon(
                Icons.history,
                color: AppColors.textSecondary,
                size: 20,
              ),
              title: Text(
                suggestion,
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              trailing: Icon(
                Icons.north_west,
                color: AppColors.textSecondary,
                size: 16,
              ),
              onTap: () => onSuggestionTap?.call(suggestion),
              dense: true,
            );
          }).toList(),
        ],
      ),
    );
  }
}

class SearchFiltersBar extends StatelessWidget {
  final List<String> activeFilters;
  final ValueChanged<String>? onFilterRemove;
  final VoidCallback? onClearAll;

  const SearchFiltersBar({
    Key? key,
    required this.activeFilters,
    this.onFilterRemove,
    this.onClearAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: AppStyles.spacingSM),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingMD),
        itemCount: activeFilters.length + 1, // +1 for clear all button
        separatorBuilder:
            (context, index) => const SizedBox(width: AppStyles.spacingSM),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildClearAllChip();
          }
          return _buildFilterChip(activeFilters[index - 1]);
        },
      ),
    );
  }

  Widget _buildClearAllChip() {
    return GestureDetector(
      onTap: onClearAll,
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
    return GestureDetector(
      onTap: () => onFilterRemove?.call(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacingMD,
          vertical: AppStyles.spacingSM,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              filter,
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: AppStyles.spacingXS),
            Icon(Icons.close, color: AppColors.primary, size: 16),
          ],
        ),
      ),
    );
  }
}
