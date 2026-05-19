import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../injection/injection_container.dart';
import '../../../../user/blog/data/models/blog_models.dart';
import '../../../../user/blog/data/repositories/blog_repository.dart';

class PsychBlogPage extends StatefulWidget {
  const PsychBlogPage({super.key});

  @override
  State<PsychBlogPage> createState() => _PsychBlogPageState();
}

class _PsychBlogPageState extends State<PsychBlogPage> {
  late final BlogRepository _blogRepository;

  bool _showForm = false;
  bool _loading = true;
  bool _submitting = false;
  String? _errorMessage;
  List<BlogEntity> _blogs = const <BlogEntity>[];

  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _selectedCategory = 'Mindfulness';

  static const _categories = ['Mindfulness', 'Anxiety', 'Depression', 'Relationships', 'Burnout', 'Sleep'];

  @override
  void initState() {
    super.initState();
    _blogRepository = sl<BlogRepository>();
    _loadBlogs();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBlogs() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final response = await _blogRepository.listMyBlogs(page: 1, limit: 100);
      if (!mounted) return;
      setState(() {
        _blogs = response.map((item) => item.toEntity()).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
    } catch (e) {
      debugPrint('[MindZep] PsychBlog load error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load blogs right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _createBlog({required bool submitForReview}) async {
    final title = _titleCtrl.text.trim();
    final body = _contentCtrl.text.trim();

    if (title.isEmpty || body.isEmpty) {
      AppSnackbar.show(
        context,
        message: 'Please enter title and content.',
        type: SnackbarType.error,
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final created = await _blogRepository.createBlog(
        CreateBlogRequest(
          title: title,
          body: body,
          category: _selectedCategory,
        ),
      );

      if (submitForReview) {
        await _blogRepository.submitBlog(created.id);
      }

      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: submitForReview ? 'Submitted for review' : 'Saved as draft',
        type: SnackbarType.success,
      );
      setState(() {
        _showForm = false;
        _titleCtrl.clear();
        _contentCtrl.clear();
      });
      await _loadBlogs();
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: 'Unable to save blog right now.',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blogs = _blogs;
    final published = blogs.where((b) => b.status == BlogStatus.published).length;
    final totalViews = blogs.fold<int>(0, (sum, b) => sum + b.viewCount);
    final totalComments = blogs.fold<int>(0, (sum, b) => sum + b.commentCount);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(
        children: [
          // ── Teal Gradient Header ──────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF30B0C7), Color(0xFF34C7A3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'My Blog',
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _showForm = !_showForm),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _showForm ? Icons.close_rounded : Icons.add_rounded,
                              color: Colors.white, size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Stats chips
                    Row(
                      children: [
                        _BlogStat(label: 'Articles', value: '$published'),
                        const SizedBox(width: 8),
                        _BlogStat(label: 'Total Views', value: totalViews > 1000 ? '${(totalViews / 1000).toStringAsFixed(1)}K' : '$totalViews'),
                        const SizedBox(width: 8),
                        _BlogStat(label: 'Comments', value: '$totalComments'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Create Form ────────────────────────────────────────────
          if (_showForm)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Write New Article',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                  ),
                  const SizedBox(height: 12),
                  // Title input
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _titleCtrl,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E)),
                      decoration: const InputDecoration(
                        hintText: 'Article title...',
                        hintStyle: TextStyle(color: Color(0xFFC7C7CC)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Category chips
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: _categories.map((cat) {
                      final isSel = cat == _selectedCategory;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF30B0C7) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500,
                              color: isSel ? Colors.white : const Color(0xFF1C1C1E),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  // Content input
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _contentCtrl,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1C1C1E)),
                      decoration: const InputDecoration(
                        hintText: 'Share your thoughts and insights...',
                        hintStyle: TextStyle(color: Color(0xFFC7C7CC)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _submitting ? null : () => _createBlog(submitForReview: false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text('Save Draft', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF30B0C7))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: _submitting ? null : () => _createBlog(submitForReview: true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF30B0C7), Color(0xFF34C7A3)]),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text('Publish', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // ── Blog List ──────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFF8E8E93)),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _loadBlogs,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : blogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: const BoxDecoration(color: Color(0xFFE6F8FA), shape: BoxShape.circle),
                          child: const Icon(Icons.article_outlined, color: Color(0xFF30B0C7), size: 30),
                        ),
                        const SizedBox(height: 14),
                        const Text('No Articles Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3C3C3C))),
                        const SizedBox(height: 4),
                        const Text('Tap + to write your first article', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: blogs.length,
                    itemBuilder: (ctx, i) => GestureDetector(
                      onTap: () async {
                        final changed = await ctx.push(RouteNames.psychBlogDetail, extra: blogs[i]);
                        if (changed == true && mounted) {
                          _loadBlogs();
                        }
                      },
                      child: _BlogCard(blog: blogs[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BlogStat extends StatelessWidget {
  final String label, value;
  const _BlogStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Color(0xAAFFFFFF), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  final BlogEntity blog;
  const _BlogCard({required this.blog});

  // Blog status badge colors
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

  // Category emoji mapping
  static String _categoryEmoji(String category) {
    const map = {
      'Anxiety': '😟', 'Depression': '💙', 'Relationships': '💑',
      'Stress': '😤', 'Sleep': '😴', 'Trauma': '🧠',
      'Mindfulness': '🧘', 'Burnout': '🔥',
    };
    return map[category] ?? '📝';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(blog.status);
    final emoji = _categoryEmoji(blog.category ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover area
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF30B0C7).withOpacity(0.15), const Color(0xFF34C7A3).withOpacity(0.25)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            ),
            child: Stack(
              children: [
                Center(child: Text(emoji, style: const TextStyle(fontSize: 42))),
                Positioned(
                  top: 10, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_statusLabel(blog.status), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
                if (blog.category != null)
                  Positioned(
                    top: 10, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(blog.category!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF30B0C7))),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blog.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  blog.body.substring(0, blog.body.length.clamp(0, 100)),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93), height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF8E8E93)),
                    const SizedBox(width: 4),
                    Text(
                      '${blog.createdAt.day}/${blog.createdAt.month}/${blog.createdAt.year}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                    ),
                    const Spacer(),
                    if (blog.viewCount != null) ...[
                      const Icon(Icons.visibility_outlined, size: 12, color: Color(0xFF8E8E93)),
                      const SizedBox(width: 4),
                      Text('${blog.viewCount} views', style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                    ],
                  ],
                ),
                if (blog.status == BlogStatus.rejected) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFFF3B30)),
                        SizedBox(width: 6),
                        Expanded(child: Text('Rejected — please revise and resubmit', style: TextStyle(fontSize: 11, color: Color(0xFFFF3B30)))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


