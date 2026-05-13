import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show RangeValues;
import '../../../../../core/entities/entities.dart';
import '../../../../../core/widgets/app_avatar.dart';

abstract class PsychologistListEvent extends Equatable {
  const PsychologistListEvent();
  @override
  List<Object?> get props => [];
}

class LoadPsychologists extends PsychologistListEvent {
  const LoadPsychologists();
}

class FilterChanged extends PsychologistListEvent {
  final FilterParams params;
  const FilterChanged(this.params);
  @override
  List<Object?> get props => [params];
}

class SearchQueryChanged extends PsychologistListEvent {
  final String query;
  const SearchQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class SpecializationSelected extends PsychologistListEvent {
  final String? specialization; // null = All
  const SpecializationSelected(this.specialization);
  @override
  List<Object?> get props => [specialization];
}

// ─── State ────────────────────────────────────────────────────────────────────

abstract class PsychologistListState extends Equatable {
  const PsychologistListState();
  @override
  List<Object?> get props => [];
}

class PsychologistListInitial extends PsychologistListState {
  const PsychologistListInitial();
}

class PsychologistListLoading extends PsychologistListState {
  const PsychologistListLoading();
}

class PsychologistListLoaded extends PsychologistListState {
  final List<PsychologistEntity> all;
  final List<PsychologistEntity> filtered;
  final FilterParams appliedFilters;
  final String searchQuery;
  final String? selectedSpecialization;

  const PsychologistListLoaded({
    required this.all,
    required this.filtered,
    required this.appliedFilters,
    this.searchQuery = '',
    this.selectedSpecialization,
  });

  @override
  List<Object?> get props =>
      [filtered, appliedFilters, searchQuery, selectedSpecialization];
}

class PsychologistListError extends PsychologistListState {
  final String message;
  const PsychologistListError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Filter Params ────────────────────────────────────────────────────────────

class FilterParams extends Equatable {
  final List<String> specializations;
  final RangeValues experienceRange;
  final RangeValues priceRange;
  final double? minRating;
  final bool availableOnly;

  const FilterParams({
    this.specializations = const [],
    this.experienceRange = const RangeValues(0, 20),
    this.priceRange = const RangeValues(5, 50),
    this.minRating,
    this.availableOnly = false,
  });

  static const FilterParams empty = FilterParams();

  @override
  List<Object?> get props =>
      [specializations, experienceRange, priceRange, minRating, availableOnly];
}

