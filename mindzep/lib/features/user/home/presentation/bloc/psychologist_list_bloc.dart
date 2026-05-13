import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/mock/mock_data.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/widgets/app_avatar.dart';
import 'psychologist_list_event_state.dart';

class PsychologistListBloc
    extends Bloc<PsychologistListEvent, PsychologistListState> {
  PsychologistListBloc() : super(const PsychologistListInitial()) {
    on<LoadPsychologists>(_onLoad);
    on<FilterChanged>(_onFilter);
    on<SearchQueryChanged>(_onSearch);
    on<SpecializationSelected>(_onSpecialization);
  }

  Future<void> _onLoad(
      LoadPsychologists event, Emitter<PsychologistListState> emit) async {
    emit(const PsychologistListLoading());
    await Future.delayed(const Duration(milliseconds: 600));
    emit(PsychologistListLoaded(
      all: MockData.psychologists,
      filtered: MockData.psychologists,
      appliedFilters: FilterParams.empty,
    ));
  }

  void _onFilter(FilterChanged event, Emitter<PsychologistListState> emit) {
    if (state is! PsychologistListLoaded) return;
    final current = state as PsychologistListLoaded;
    final filtered = _applyFilters(
      current.all,
      event.params,
      current.searchQuery,
      current.selectedSpecialization,
    );
    emit(PsychologistListLoaded(
      all: current.all,
      filtered: filtered,
      appliedFilters: event.params,
      searchQuery: current.searchQuery,
      selectedSpecialization: current.selectedSpecialization,
    ));
  }

  void _onSearch(SearchQueryChanged event, Emitter<PsychologistListState> emit) {
    if (state is! PsychologistListLoaded) return;
    final current = state as PsychologistListLoaded;
    final filtered = _applyFilters(
      current.all,
      current.appliedFilters,
      event.query,
      current.selectedSpecialization,
    );
    emit(PsychologistListLoaded(
      all: current.all,
      filtered: filtered,
      appliedFilters: current.appliedFilters,
      searchQuery: event.query,
      selectedSpecialization: current.selectedSpecialization,
    ));
  }

  void _onSpecialization(
      SpecializationSelected event, Emitter<PsychologistListState> emit) {
    if (state is! PsychologistListLoaded) return;
    final current = state as PsychologistListLoaded;
    final filtered = _applyFilters(
      current.all,
      current.appliedFilters,
      current.searchQuery,
      event.specialization,
    );
    emit(PsychologistListLoaded(
      all: current.all,
      filtered: filtered,
      appliedFilters: current.appliedFilters,
      searchQuery: current.searchQuery,
      selectedSpecialization: event.specialization,
    ));
  }

  List<PsychologistEntity> _applyFilters(
    List<PsychologistEntity> all,
    FilterParams params,
    String query,
    String? specialization,
  ) {
    return all.where((p) {
      // Search query
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        if (!p.name.toLowerCase().contains(q) &&
            !p.specialization.toLowerCase().contains(q) &&
            !p.specializations.any((s) => s.toLowerCase().contains(q))) {
          return false;
        }
      }
      // Specialization chip
      if (specialization != null &&
          !p.specializations
              .any((s) => s.toLowerCase() == specialization.toLowerCase())) {
        return false;
      }
      // Filter params
      if (p.yearsExperience < params.experienceRange.start ||
          p.yearsExperience > params.experienceRange.end) return false;
      if (p.ratePerMinute < params.priceRange.start ||
          p.ratePerMinute > params.priceRange.end) return false;
      if (params.minRating != null && p.ratingAverage < params.minRating!) {
        return false;
      }
      if (params.availableOnly &&
          p.status != AvailabilityStatus.available) return false;
      return true;
    }).toList();
  }
}

