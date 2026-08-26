import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../data/faq_data.dart';

/// Dedicated, searchable FAQ library.
///
/// Reached from Settings, the drawer and Help & Support; also accepts an
/// optional [initialCategory] so a caller can deep-link into one section.
class FaqPage extends StatefulWidget {
  const FaqPage({super.key, this.initialCategory, this.initialQuery});

  final FaqCategory? initialCategory;
  final String? initialQuery;

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  static const _accent = Color(0xFF5E5CE6);
  static const _secondary = Color(0xFF8B7CF6);

  late final TextEditingController _searchController;
  FaqCategory? _category;
  String _query = '';

  /// Question text of the entry currently expanded — only one opens at a time,
  /// which keeps a long list scannable.
  String? _openQuestion;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _query = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FaqEntry> get _results =>
      FaqLibrary.search(_query, category: _category);

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
      // A result list that just changed shape should not keep a stale card open.
      _openQuestion = null;
    });
  }

  void _selectCategory(FaqCategory? category) {
    setState(() {
      _category = category;
      _openQuestion = null;
    });
  }

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: FaqLibrary.supportEmail,
      queryParameters: const {'subject': 'MindZep — Help request'},
    );
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (launched || !mounted) return;

    // No mail client on the device — leave the address on the clipboard.
    await Clipboard.setData(const ClipboardData(text: FaqLibrary.supportEmail));
    if (!mounted) return;
    AppSnackbar.show(
      context,
      message: 'Support email copied: ${FaqLibrary.supportEmail}',
      type: SnackbarType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(
        children: [
          _buildHeader(results.length),
          Expanded(
            child: results.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: results.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      if (index == results.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: _ContactSupportCard(onTap: _emailSupport),
                        );
                      }
                      final entry = results[index];
                      return _FaqCard(
                        entry: entry,
                        query: _query,
                        expanded: _openQuestion == entry.question,
                        showCategory: _category == null,
                        onToggle: () => setState(
                          () => _openQuestion = _openQuestion == entry.question
                              ? null
                              : entry.question,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Header: title, search, category chips ──────────────────────────────────

  Widget _buildHeader(int resultCount) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent, _secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go(RouteNames.userHome);
                      }
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FAQs',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Answers to the questions we hear most',
                          style: TextStyle(
                            color: Color(0xCCFFFFFF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onQueryChanged,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: Color(0xFF1C1C1E),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search booking, payments, privacy…',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFAEAEB2),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: Color(0xFF8E8E93),
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _onQueryChanged('');
                              FocusScope.of(context).unfocus();
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Category chips
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryChip(
                      label: 'All',
                      icon: Icons.apps_rounded,
                      selected: _category == null,
                      onTap: () => _selectCategory(null),
                    ),
                    ...FaqLibrary.categories.map(
                      (category) => _CategoryChip(
                        label: category.label,
                        icon: category.icon,
                        selected: _category == category,
                        onTap: () => _selectCategory(category),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _query.isEmpty && _category == null
                    ? '${FaqLibrary.all.length} questions answered'
                    : '$resultCount ${resultCount == 1 ? 'result' : 'results'}',
                style: const TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 34,
              color: _accent,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No answer for that yet',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try a different word, or clear the filters and browse every '
            'category. Our team is happy to answer directly too.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 22),
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              _onQueryChanged('');
              _selectCategory(null);
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Clear search and filters'),
            style: TextButton.styleFrom(foregroundColor: _accent),
          ),
          const SizedBox(height: 16),
          _ContactSupportCard(onTap: _emailSupport),
        ],
      ),
    );
  }
}

// ── Category chip ────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: selected ? 1 : 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? const Color(0xFF5E5CE6) : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? const Color(0xFF5E5CE6) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── FAQ card ─────────────────────────────────────────────────────────────────

class _FaqCard extends StatelessWidget {
  const _FaqCard({
    required this.entry,
    required this.query,
    required this.expanded,
    required this.showCategory,
    required this.onToggle,
  });

  final FaqEntry entry;
  final String query;
  final bool expanded;
  final bool showCategory;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: expanded
                ? const Color(0xFF5E5CE6).withValues(alpha: 0.35)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: expanded ? 0.07 : 0.04),
              blurRadius: expanded ? 14 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0FF),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    entry.category.icon,
                    size: 15,
                    color: const Color(0xFF5E5CE6),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HighlightedText(
                        text: entry.question,
                        query: query,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      if (showCategory) ...[
                        const SizedBox(height: 3),
                        Text(
                          entry.category.label,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9A9AA0),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: expanded ? 0.5 : 0,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: Color(0xFFB0B0B8),
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12, left: 41, right: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 1,
                      color: const Color(0xFFF0F0F5),
                      margin: const EdgeInsets.only(bottom: 10),
                    ),
                    _HighlightedText(
                      text: entry.answer,
                      query: query,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.55,
                        color: Color(0xFF56565A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders [text] with every occurrence of [query] tinted, so a searcher can
/// see why a result matched.
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.style,
  });

  final String text;
  final String query;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return Text(text, style: style);

    final haystack = text.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final index = haystack.indexOf(needle, start);
      if (index < 0) break;
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + needle.length),
          style: const TextStyle(
            backgroundColor: Color(0x335E5CE6),
            fontWeight: FontWeight.w700,
            color: Color(0xFF3F3DBF),
          ),
        ),
      );
      start = index + needle.length;
    }

    if (spans.isEmpty) return Text(text, style: style);
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return Text.rich(TextSpan(style: style, children: spans));
  }
}

// ── Contact support footer ───────────────────────────────────────────────────

class _ContactSupportCard extends StatelessWidget {
  const _ContactSupportCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5E5CE6), Color(0xFF8B7CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5E5CE6).withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Still need help?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Write to our support team — we reply within 24 hours.',
                    style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
