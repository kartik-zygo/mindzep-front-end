import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_shimmer.dart';
import '../../../home/presentation/bloc/psychologist_list_bloc.dart';
import '../../../home/presentation/bloc/psychologist_list_event_state.dart';
import '../../../home/presentation/widgets/filter_bottom_sheet.dart';
import '../../../home/presentation/widgets/psychologist_card.dart';

class ConsultPage extends StatefulWidget {
  const ConsultPage({super.key});

  @override
  State<ConsultPage> createState() => _ConsultPageState();
}

class _ConsultPageState extends State<ConsultPage> {
  final _searchCtrl = TextEditingController();

  static const _specializations = [
    'All', 'Anxiety', 'Depression', 'Relationships',
    'Stress', 'Trauma', 'Sleep', 'Anger',
  ];

  @override
  void initState() {
    super.initState();
    context.read<PsychologistListBloc>().add(const LoadPsychologists());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: BlocBuilder<PsychologistListBloc, PsychologistListState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5E5CE6), Color(0xFF8B7CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Find a Therapist',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Connect with licensed mental health experts',
                            style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          // Search bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, color: Color(0xFF8E8E93), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _searchCtrl,
                                    onChanged: (q) => context.read<PsychologistListBloc>().add(SearchQueryChanged(q)),
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E)),
                                    decoration: const InputDecoration(
                                      hintText: 'Search by name or specialty...',
                                      hintStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                if (state is PsychologistListLoaded)
                                  GestureDetector(
                                    onTap: () => FilterBottomSheet.show(context, state.appliedFilters),
                                    child: Container(
                                      width: 32, height: 32,
                                      decoration: BoxDecoration(
                                        color: state.appliedFilters != FilterParams.empty
                                            ? const Color(0xFF5E5CE6)
                                            : const Color(0xFFF2F2F7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.tune_rounded,
                                        size: 18,
                                        color: state.appliedFilters != FilterParams.empty ? Colors.white : const Color(0xFF8E8E93),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // ── Specialization Chips ──────────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _specializations.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final spec = _specializations[i];
                          final isSelected = state is PsychologistListLoaded
                              ? (spec == 'All' ? state.selectedSpecialization == null : state.selectedSpecialization == spec)
                              : i == 0;
                          return GestureDetector(
                            onTap: state is PsychologistListLoaded
                                ? () => context.read<PsychologistListBloc>().add(SpecializationSelected(spec == 'All' ? null : spec))
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                              ),
                              child: Text(
                                spec,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              // ── Count Header ──────────────────────────────────────────
              if (state is PsychologistListLoaded)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      '${state.filtered.length} therapist${state.filtered.length == 1 ? '' : 's'} found',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                    ),
                  ),
                ),
              // ── Psychologist List ─────────────────────────────────────
              if (state is PsychologistListLoaded) ...[
                if (state.filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      title: 'No Psychologists Found',
                      variant: EmptyStateVariant.psychologists,
                      actionLabel: 'Clear Filters',
                      onAction: () => context.read<PsychologistListBloc>().add(const FilterChanged(FilterParams.empty)),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => PsychologistCard(psychologist: state.filtered[i]),
                        childCount: state.filtered.length,
                      ),
                    ),
                  ),
              ] else if (state is PsychologistListLoading) ...[
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: ShimmerCard(),
                    ),
                    childCount: 6,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
