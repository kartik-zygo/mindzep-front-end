import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../bloc/psychologist_list_event_state.dart';
import '../bloc/psychologist_list_bloc.dart';

class FilterBottomSheet extends StatefulWidget {
  final FilterParams current;

  const FilterBottomSheet({super.key, required this.current});

  static Future<void> show(BuildContext context, FilterParams current) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<PsychologistListBloc>(),
        child: FilterBottomSheet(current: current),
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final List<String> _allSpecializations = [
    'Anxiety', 'Depression', 'Relationships', 'Stress',
    'Trauma', 'Sleep', 'Anger', 'OCD', 'Addiction', 'Grief',
  ];

  late List<String> _selectedSpecs;
  late RangeValues _experienceRange;
  late RangeValues _priceRange;
  double? _minRating;
  late bool _availableOnly;

  @override
  void initState() {
    super.initState();
    _selectedSpecs = List.from(widget.current.specializations);
    _experienceRange = widget.current.experienceRange;
    _priceRange = widget.current.priceRange;
    _minRating = widget.current.minRating;
    _availableOnly = widget.current.availableOnly;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusXL)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingL,
                  vertical: AppDimensions.paddingM),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filters',
                      style: AppTextStyles.title3
                          .copyWith(color: AppColors.textPrimary)),
                  TextButton(
                    onPressed: _resetFilters,
                    child: Text('Reset',
                        style: AppTextStyles.subheadline
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                children: [
                  // Specializations
                  Text('Specializations',
                      style: AppTextStyles.headline
                          .copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: AppDimensions.paddingS),
                  Wrap(
                    spacing: AppDimensions.paddingS,
                    runSpacing: AppDimensions.paddingS,
                    children: _allSpecializations.map((s) {
                      final selected = _selectedSpecs.contains(s);
                      return FilterChip(
                        label: Text(s),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _selectedSpecs.add(s);
                          } else {
                            _selectedSpecs.remove(s);
                          }
                        }),
                        selectedColor: AppColors.primary.withOpacity(0.15),
                        checkmarkColor: AppColors.primary,
                        labelStyle: AppTextStyles.subheadline.copyWith(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  // Experience
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Experience (years)',
                          style: AppTextStyles.headline
                              .copyWith(color: AppColors.textPrimary)),
                      Text(
                        '${_experienceRange.start.toInt()}–${_experienceRange.end.toInt()} yrs',
                        style: AppTextStyles.subheadline
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(
                        _experienceRange.start, _experienceRange.end),
                    min: 0,
                    max: 30,
                    divisions: 30,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() =>
                        _experienceRange = RangeValues(v.start, v.end)),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rate per Minute',
                          style: AppTextStyles.headline
                              .copyWith(color: AppColors.textPrimary)),
                      Text(
                        '₹${_priceRange.start.toInt()}–₹${_priceRange.end.toInt()}',
                        style: AppTextStyles.subheadline
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(
                        _priceRange.start, _priceRange.end),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(
                        () => _priceRange = RangeValues(v.start, v.end)),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  // Rating
                  Text('Minimum Rating',
                      style: AppTextStyles.headline
                          .copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: AppDimensions.paddingS),
                  Row(
                    children: [null, 3.0, 3.5, 4.0, 4.5].map((r) {
                      final isSelected = _minRating == r;
                      return Padding(
                        padding:
                            const EdgeInsets.only(right: AppDimensions.paddingS),
                        child: ChoiceChip(
                          label: Text(
                              r == null ? 'Any' : '${r}+ ★'),
                          selected: isSelected,
                          onSelected: (v) =>
                              setState(() => _minRating = v ? r : null),
                          selectedColor: AppColors.primary.withOpacity(0.15),
                          labelStyle: AppTextStyles.subheadline.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  // Available only
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Available now',
                        style: AppTextStyles.headline
                            .copyWith(color: AppColors.textPrimary)),
                    subtitle: Text('Show only online psychologists',
                        style: AppTextStyles.subheadline
                            .copyWith(color: AppColors.textSecondary)),
                    value: _availableOnly,
                    onChanged: (v) => setState(() => _availableOnly = v),
                    activeColor: AppColors.primary,
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                ],
              ),
            ),
            // Apply button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                    ),
                  ),
                  child: Text('Apply Filters',
                      style: AppTextStyles.headline
                          .copyWith(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyFilters() {
    context.read<PsychologistListBloc>().add(FilterChanged(FilterParams(
      specializations: _selectedSpecs,
      experienceRange: _experienceRange,
      priceRange: _priceRange,
      minRating: _minRating,
      availableOnly: _availableOnly,
    )));
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      _selectedSpecs = [];
      _experienceRange = const RangeValues(0, 20);
      _priceRange = const RangeValues(5, 50);
      _minRating = null;
      _availableOnly = false;
    });
  }
}

