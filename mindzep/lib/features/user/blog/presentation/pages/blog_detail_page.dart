import 'package:flutter/material.dart';
import '../../../../../core/entities/entities.dart';

class BlogDetailPage extends StatelessWidget {
  final BlogEntity blog;
  const BlogDetailPage({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF5E5CE6),
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(children: [
                // Cover image / gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF5E5CE6), Color(0xFF8B7CF6)]),
                  ),
                  child: blog.coverImageUrl != null && blog.coverImageUrl!.isNotEmpty
                      ? Image.network(blog.coverImageUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (_, __, ___) => const SizedBox())
                      : Center(child: Text(_categoryEmoji(blog.category), style: const TextStyle(fontSize: 72))),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),

          // ── Title card ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Category + reading time
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(10)),
                    child: Text(blog.category, style: const TextStyle(color: Color(0xFF5E5CE6), fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF8E8E93)),
                      const SizedBox(width: 4),
                      Text('${_readingTime(blog.body)} min read', style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
                    ]),
                  ),
                  const Spacer(),
                  Row(children: [
                    const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF8E8E93)),
                    const SizedBox(width: 4),
                    Text('${blog.viewCount}', style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                  ]),
                ]),
                const SizedBox(height: 12),
                Text(blog.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E), height: 1.3)),
                const SizedBox(height: 14),

                // Author row
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF5E5CE6), Color(0xFF8B7CF6)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(child: Text(blog.psychologistName[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(blog.psychologistName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
                    const Text('Licensed Psychologist · MindZep Expert', style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                  ])),
                  if (blog.publishedAt != null)
                    Text(_formatDate(blog.publishedAt!), style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                ]),
              ]),
            ),
          ),

          // ── Tags ─────────────────────────────────────────────────────────
          if (blog.tags.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Wrap(spacing: 8, runSpacing: 6, children: blog.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(20)),
                  child: Text('#$tag', style: const TextStyle(fontSize: 11, color: Color(0xFF5E5CE6), fontWeight: FontWeight.w500)),
                )).toList()),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Body content ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: _BlogBody(body: blog.body),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── More from author ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('More from this author', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0FF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF5E5CE6), Color(0xFF8B7CF6)]),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(child: Text(blog.psychologistName[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(blog.psychologistName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E))),
                      const Text('Expert in mental health & wellness', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF5E5CE6), borderRadius: BorderRadius.circular(12)),
                      child: const Text('Follow', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
              ]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  int _readingTime(String text) {
    final words = text.trim().split(RegExp(r'\s+')).length;
    return (words / 200).ceil().clamp(1, 60);
  }

  String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  String _categoryEmoji(String cat) {
    const map = {'Anxiety': '😰', 'Depression': '💙', 'Stress': '🧘', 'Sleep': '😴', 'Relationships': '💞', 'Trauma': '🌱', 'Mindfulness': '🌿'};
    return map[cat] ?? '📖';
  }
}

// ── Blog body renderer ─────────────────────────────────────────────────────────

class _BlogBody extends StatelessWidget {
  final String body;
  const _BlogBody({required this.body});

  @override
  Widget build(BuildContext context) {
    final paragraphs = body.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.asMap().entries.map((entry) {
        final i = entry.key;
        final para = entry.value.trim();
        // Treat first paragraph as a lead/intro
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(para, style: const TextStyle(fontSize: 16, color: Color(0xFF3C3C3C), height: 1.7, fontWeight: FontWeight.w500)),
          );
        }
        // Headings: lines starting with **
        if (para.startsWith('**') && para.endsWith('**')) {
          final text = para.replaceAll('**', '');
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(para, style: const TextStyle(fontSize: 15, color: Color(0xFF3C3C3C), height: 1.7)),
        );
      }).toList(),
    );
  }
}
