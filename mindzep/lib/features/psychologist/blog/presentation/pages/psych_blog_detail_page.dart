import 'package:flutter/material.dart';
import '../../../../../core/entities/entities.dart';

class PsychBlogDetailPage extends StatelessWidget {
  final BlogEntity blog;
  const PsychBlogDetailPage({super.key, required this.blog});

  static Color _statusColor(BlogStatus s) {
    switch (s) {
      case BlogStatus.published: return const Color(0xFF34C759);
      case BlogStatus.draft: return const Color(0xFFFF9500);
      case BlogStatus.underReview: return const Color(0xFF30B0C7);
      case BlogStatus.rejected: return const Color(0xFFFF3B30);
    }
  }

  static String _statusLabel(BlogStatus s) {
    switch (s) {
      case BlogStatus.draft: return 'Draft';
      case BlogStatus.underReview: return 'Under Review';
      case BlogStatus.published: return 'Published';
      case BlogStatus.rejected: return 'Rejected';
    }
  }

  static String _categoryEmoji(String? category) {
    const map = {
      'Anxiety': '😟', 'Depression': '💙', 'Relationships': '💑',
      'Stress': '😤', 'Sleep': '😴', 'Trauma': '🧠',
      'Mindfulness': '🧘', 'Burnout': '🔥',
    };
    return map[category ?? ''] ?? '📝';
  }

  int get _readingTime => ((blog.body.split(' ').length) / 200).ceil().clamp(1, 99);

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(blog.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          // ── Pinned hero header ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF30B0C7),
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => _showEditOptions(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.more_horiz_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF30B0C7), Color(0xFF34C7A3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -40, right: -40,
                      child: Container(
                        width: 180, height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20, left: -30,
                      child: Container(
                        width: 130, height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 44),
                          Text(_categoryEmoji(blog.category), style: const TextStyle(fontSize: 64)),
                          const SizedBox(height: 8),
                          if (blog.category != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                blog.category!,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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

          // ── Article content ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status + meta row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(_statusLabel(blog.status), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF8E8E93)),
                            const SizedBox(width: 4),
                            Text('$_readingTime min read', style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                            const Spacer(),
                            if (blog.viewCount != null) ...[
                              const Icon(Icons.visibility_outlined, size: 12, color: Color(0xFF8E8E93)),
                              const SizedBox(width: 4),
                              Text('${blog.viewCount}', style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Title
                        Text(
                          blog.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E), height: 1.3),
                        ),
                        const SizedBox(height: 10),
                        // Author + date
                        Row(
                          children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF30B0C7), Color(0xFF34C7A3)]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text('AK', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Dr. Ananya Krishnan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
                                  Text(
                                    '${blog.createdAt.day} ${_monthName(blog.createdAt.month)} ${blog.createdAt.year}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                                  ),
                                ],
                              ),
                            ),
                            if (blog.category != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F8FB),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(blog.category!, style: const TextStyle(fontSize: 11, color: Color(0xFF30B0C7), fontWeight: FontWeight.w500)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Rejection warning
                  if (blog.status == BlogStatus.rejected)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: Color(0xFFFF3B30), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Article Rejected', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFF3B30))),
                                SizedBox(height: 2),
                                Text('Please revise your content and resubmit for review.', style: TextStyle(fontSize: 12, color: Color(0xFFFF3B30))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Pending info
                  if (blog.status == BlogStatus.underReview)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8FB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF30B0C7).withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.hourglass_empty_rounded, color: Color(0xFF30B0C7), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Under Review', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF30B0C7))),
                                SizedBox(height: 2),
                                Text('Your article is being reviewed by our team. This usually takes 24–48 hours.', style: TextStyle(fontSize: 12, color: Color(0xFF30B0C7))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Article body
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                    ),
                    child: _BlogBody(body: blog.body),
                  ),
                  const SizedBox(height: 16),

                  // Stats row (for published)
                  if (blog.status == BlogStatus.published) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.visibility_outlined,
                            color: const Color(0xFF30B0C7),
                            bg: const Color(0xFFE8F8FB),
                            value: '${blog.viewCount ?? 0}',
                            label: 'Total Views',
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: _StatCard(
                            icon: Icons.favorite_outline_rounded,
                            color: Color(0xFFFF6B8A),
                            bg: Color(0xFFFFF0F4),
                            value: '24',
                            label: 'Likes',
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: _StatCard(
                            icon: Icons.share_outlined,
                            color: Color(0xFF34C759),
                            bg: Color(0xFFE8FFF0),
                            value: '6',
                            label: 'Shares',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showEditOptions(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF30B0C7), Color(0xFF34C7A3)]),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Article', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            _BottomSheetOption(icon: Icons.edit_rounded, color: const Color(0xFF30B0C7), label: 'Edit Article', onTap: () => Navigator.pop(context)),
            _BottomSheetOption(icon: Icons.send_rounded, color: const Color(0xFF34C759), label: 'Resubmit for Review', onTap: () => Navigator.pop(context)),
            _BottomSheetOption(icon: Icons.delete_outline_rounded, color: const Color(0xFFFF3B30), label: 'Delete Article', onTap: () => Navigator.pop(context)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}

// ── Blog body renderer ────────────────────────────────────────────────────────

class _BlogBody extends StatelessWidget {
  final String body;
  const _BlogBody({required this.body});

  @override
  Widget build(BuildContext context) {
    final paragraphs = body.split('\n').where((p) => p.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.asMap().entries.map((entry) {
        final i = entry.key;
        final para = entry.value.trim();
        final isHeading = para.startsWith('**') && para.endsWith('**');
        final isLead = i == 0;
        if (isHeading) {
          final text = para.replaceAll('**', '');
          return Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 8),
            child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            para,
            style: TextStyle(
              fontSize: isLead ? 15 : 14,
              fontWeight: isLead ? FontWeight.w500 : FontWeight.w400,
              color: isLead ? const Color(0xFF3C3C3C) : const Color(0xFF6B6B80),
              height: 1.65,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  final String value, label;
  const _StatCard({required this.icon, required this.color, required this.bg, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93))),
        ],
      ),
    );
  }
}

class _BottomSheetOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _BottomSheetOption({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: color == const Color(0xFFFF3B30) ? const Color(0xFFFF3B30) : const Color(0xFF1C1C1E))),
          ],
        ),
      ),
    );
  }
}
