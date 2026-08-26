import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../injection/injection_container.dart';
import '../../../../../core/network/api_error_model.dart';
import '../../../../user/blog/data/models/blog_models.dart';
import '../../../../user/blog/data/repositories/blog_repository.dart';
import '../../../shared/psych_ui.dart';

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
  String _selectedCategory = 'mindfulness';

  // Backend DB enum values — mental_health & self_care omitted because the
  // PostgreSQL enum rejects them despite Joi allowing them (backend mismatch).
  static const _categories = [
    'anxiety', 'depression', 'relationships',
    'mindfulness', 'trauma', 'addiction', 'parenting', 'career',
  ];

  static String _categoryLabel(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');

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
      setState(() => _errorMessage = 'Unable to load blogs right now.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createBlog({required bool submitForReview}) async {
    final title = _titleCtrl.text.trim();
    final body = _contentCtrl.text.trim();

    if (title.isEmpty || body.isEmpty) {
      AppSnackbar.show(context,
          message: 'Please enter title and content.',
          type: SnackbarType.error);
      return;
    }
    if (body.length < 100) {
      AppSnackbar.show(context,
          message:
              'Content must be at least 100 characters (currently ${body.length}).',
          type: SnackbarType.error);
      return;
    }

    setState(() => _submitting = true);

    try {
      final created = await _blogRepository.createBlog(
        CreateBlogRequest(title: title, body: body, category: _selectedCategory),
      );
      if (submitForReview) {
        await _blogRepository.submitBlog(created.id);
      }

      if (!mounted) return;
      AppSnackbar.show(context,
          message: submitForReview ? 'Submitted for review' : 'Saved as draft',
          type: SnackbarType.success);
      setState(() {
        _showForm = false;
        _titleCtrl.clear();
        _contentCtrl.clear();
      });
      await _loadBlogs();
    } catch (e) {
      if (!mounted) return;
      String errorMsg = 'Unable to save blog right now.';
      if (e is ApiErrorModel) {
        final errors = e.details?['errors'];
        if (errors is List && errors.isNotEmpty) {
          errorMsg = errors.map((err) {
            final field = err['field']?.toString() ?? '';
            final msg = err['message']?.toString() ?? '';
            return field.isNotEmpty ? '$field: $msg' : msg;
          }).join('\n');
        } else {
          errorMsg = e.message;
        }
      }
      AppSnackbar.show(context, message: errorMsg, type: SnackbarType.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blogs = _blogs;
    final published =
        blogs.where((b) => b.status == BlogStatus.published).length;
    final totalViews = blogs.fold<int>(0, (sum, b) => sum + b.viewCount);
    final totalComments =
        blogs.fold<int>(0, (sum, b) => sum + b.commentCount);

    return PsychScaffold(
      body: Column(
        children: [
          PsychGradientHeader(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'My Blog',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    PsychGlassIconButton(
                      icon: _showForm ? Icons.close_rounded : Icons.add_rounded,
                      size: 42,
                      onTap: () => setState(() => _showForm = !_showForm),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    PsychGlassStat(value: '$published', label: 'Published'),
                    const SizedBox(width: 10),
                    PsychGlassStat(
                      value: totalViews > 1000
                          ? '${(totalViews / 1000).toStringAsFixed(1)}K'
                          : '$totalViews',
                      label: 'Total Views',
                    ),
                    const SizedBox(width: 10),
                    PsychGlassStat(value: '$totalComments', label: 'Comments'),
                  ],
                ),
              ],
            ),
          ),
          if (_showForm) _buildForm(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: PsychPalette.teal))
                : _errorMessage != null
                    ? _ErrorView(message: _errorMessage!, onRetry: _loadBlogs)
                    : blogs.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 50),
                              PsychEmptyState(
                                icon: Icons.article_outlined,
                                title: 'No articles yet',
                                subtitle:
                                    'Tap + to write and share your first article.',
                              ),
                            ],
                          )
                        : RefreshIndicator(
                            color: PsychPalette.teal,
                            onRefresh: _loadBlogs,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: blogs.length,
                              itemBuilder: (ctx, i) => PsychFadeIn(
                                delayMs: (i * 40).clamp(0, 240),
                                child: _BlogCard(
                                  blog: blogs[i],
                                  onTap: () async {
                                    final changed = await ctx.push(
                                        RouteNames.psychBlogDetail,
                                        extra: blogs[i]);
                                    if (changed == true && mounted) {
                                      _loadBlogs();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Write New Article',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: PsychPalette.ink)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: PsychPalette.scaffold,
                borderRadius: BorderRadius.circular(14)),
            child: TextField(
              controller: _titleCtrl,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: PsychPalette.ink),
              decoration: const InputDecoration(
                hintText: 'Article title...',
                hintStyle: TextStyle(color: Color(0xFFB6BFC5)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _categories.map((cat) {
              final isSel = cat == _selectedCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: isSel ? PsychPalette.brandGradient : null,
                    color: isSel ? null : PsychPalette.scaffold,
                    borderRadius: BorderRadius.circular(PsychRadii.pill),
                  ),
                  child: Text(
                    _categoryLabel(cat),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSel ? Colors.white : PsychPalette.inkSoft,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: PsychPalette.scaffold,
                borderRadius: BorderRadius.circular(14)),
            child: TextField(
              controller: _contentCtrl,
              maxLines: 4,
              style: const TextStyle(fontSize: 13.5, color: PsychPalette.ink),
              decoration: const InputDecoration(
                hintText:
                    'Share your thoughts and insights... (min 100 characters)',
                hintStyle: TextStyle(color: Color(0xFFB6BFC5)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _submitting
                      ? null
                      : () => _createBlog(submitForReview: false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                        color: PsychPalette.tealMist,
                        borderRadius: BorderRadius.circular(PsychRadii.pill)),
                    child: const Text('Save Draft',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: PsychPalette.tealDeep)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PsychPrimaryButton(
                  label: 'Submit',
                  isLoading: _submitting,
                  onPressed: _submitting
                      ? null
                      : () => _createBlog(submitForReview: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: PsychPalette.inkFaint, size: 44),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: PsychPalette.inkSoft)),
            const SizedBox(height: 16),
            PsychPrimaryButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              expand: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  final BlogEntity blog;
  final VoidCallback onTap;
  const _BlogCard({required this.blog, required this.onTap});

  static (Color, String) _status(BlogStatus s) {
    switch (s) {
      case BlogStatus.published:
        return (PsychPalette.success, 'Published');
      case BlogStatus.draft:
        return (PsychPalette.warning, 'Draft');
      case BlogStatus.underReview:
        return (PsychPalette.teal, 'Under Review');
      case BlogStatus.rejected:
        return (PsychPalette.danger, 'Rejected');
    }
  }

  static String _categoryEmoji(String category) {
    const map = {
      'anxiety': '😟', 'depression': '💙',
      'relationships': '💑', 'mindfulness': '🧘',
      'trauma': '💔', 'addiction': '🔗', 'parenting': '👨‍👩‍👧', 'career': '💼',
    };
    return map[category.toLowerCase()] ?? '📝';
  }

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = _status(blog.status);
    final hasCategory = blog.category.trim().isNotEmpty;
    final excerpt = blog.body.length > 110
        ? '${blog.body.substring(0, 110).trim()}…'
        : blog.body;

    return PsychCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PsychRadii.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 96,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    PsychPalette.teal.withValues(alpha: 0.16),
                    PsychPalette.tealLight.withValues(alpha: 0.26),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(_categoryEmoji(blog.category),
                        style: const TextStyle(fontSize: 40)),
                  ),
                  Positioned(
                    top: 10,
                    left: 12,
                    child: PsychStatusPill(
                        label: statusLabel, color: statusColor),
                  ),
                  if (hasCategory)
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(PsychRadii.pill),
                        ),
                        child: Text(_categoryLabelStatic(blog.category),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: PsychPalette.tealDeep)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blog.title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: PsychPalette.ink),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    excerpt,
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: PsychPalette.inkSoft,
                        height: 1.45),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 12, color: PsychPalette.inkFaint),
                      const SizedBox(width: 4),
                      Text(
                        '${blog.createdAt.day}/${blog.createdAt.month}/${blog.createdAt.year}',
                        style: const TextStyle(
                            fontSize: 11.5, color: PsychPalette.inkFaint),
                      ),
                      const Spacer(),
                      const Icon(Icons.visibility_outlined,
                          size: 13, color: PsychPalette.inkFaint),
                      const SizedBox(width: 4),
                      Text('${blog.viewCount}',
                          style: const TextStyle(
                              fontSize: 11.5, color: PsychPalette.inkFaint)),
                      const SizedBox(width: 12),
                      const Icon(Icons.mode_comment_outlined,
                          size: 13, color: PsychPalette.inkFaint),
                      const SizedBox(width: 4),
                      Text('${blog.commentCount}',
                          style: const TextStyle(
                              fontSize: 11.5, color: PsychPalette.inkFaint)),
                    ],
                  ),
                  if (blog.status == BlogStatus.rejected) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: PsychPalette.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: PsychPalette.danger),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                                'Rejected — please revise and resubmit',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: PsychPalette.danger)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _categoryLabelStatic(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
