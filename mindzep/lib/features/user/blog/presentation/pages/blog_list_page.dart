import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/network/api_error_model.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../injection/injection_container.dart';
import '../../data/repositories/blog_repository.dart';

class BlogListPage extends StatefulWidget {
  const BlogListPage({super.key});

  @override
  State<BlogListPage> createState() => _BlogListPageState();
}

class _BlogListPageState extends State<BlogListPage> {
  late final BlogRepository _blogRepository;

  String _selectedCategory = 'All';
  String _search = '';
  bool _loading = true;
  String? _errorMessage;
  List<BlogEntity> _allBlogs = const <BlogEntity>[];

  static const _categories = [
    'All', 'Anxiety', 'Depression', 'Relationships', 'Stress', 'Sleep', 'Trauma', 'Mindfulness',
  ];

  @override
  void initState() {
    super.initState();
    _blogRepository = sl<BlogRepository>();
    _loadBlogs();
  }

  Future<void> _loadBlogs() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final models = await _blogRepository.listPublishedBlogs(page: 1, limit: 100);
      if (!mounted) return;
      setState(() {
        _allBlogs = models.map((blog) => blog.toEntity()).toList();
      });
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiErrorModel
          ? error.message
          : 'Unable to load articles.';
      setState(() {
        _errorMessage = message;
      });
      AppSnackbar.show(
        context,
        message: message,
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blogs = _allBlogs
        .where((b) => _selectedCategory == 'All' || b.category == _selectedCategory)
        .where((b) => _search.isEmpty || b.title.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
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
                  child: Column(children: [
                    Row(children: [
                      GestureDetector(
                        onTap: () => context.go(RouteNames.userHome),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(19)),
                          child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Mental Wellness', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, fontWeight: FontWeight.w500)),
                          Text('Expert Articles', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: Text('${blogs.length} articles', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    // Search bar
                    Container(
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search articles...',
                          hintStyle: const TextStyle(color: Color(0x80FFFFFF), fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xB3FFFFFF), size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 13),
                          suffixIcon: _search.isNotEmpty
                              ? GestureDetector(
                                  onTap: () => setState(() => _search = ''),
                                  child: const Icon(Icons.close_rounded, color: Color(0xB3FFFFFF), size: 18))
                              : null,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),

          // ── Category chips ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final active = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFF5E5CE6) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                        ),
                        child: Text(cat, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : const Color(0xFF8E8E93))),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null && _allBlogs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 42, color: Color(0xFF8E8E93)),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF8E8E93)),
                      ),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _loadBlogs, child: const Text('Retry')),
                    ],
                  ),
                ),
              ),
            )
          else ...[

          // ── Featured banner ──────────────────────────────────────────────
          if (blogs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _FeaturedBlogCard(blog: blogs.first, onTap: () => context.push(RouteNames.userBlogDetail, extra: blogs.first)),
              ),
            ),

          // ── Blog grid ────────────────────────────────────────────────────
          if (blogs.length > 1)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final blog = blogs[i + 1];
                    return _BlogCard(blog: blog, onTap: () => context.push(RouteNames.userBlogDetail, extra: blog));
                  },
                  childCount: blogs.length - 1,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
              ),
            ),

          // ── Empty state ──────────────────────────────────────────────────
          if (blogs.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(children: [
                  const Text('📝', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('No articles found', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
                  const SizedBox(height: 6),
                  Text('Try a different search or category', style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
                ]),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ],
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _FeaturedBlogCard extends StatelessWidget {
  final BlogEntity blog;
  final VoidCallback onTap;
  const _FeaturedBlogCard({required this.blog, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF5E5CE6), Color(0xFF8B7CF6)]),
            ),
            child: blog.coverImageUrl != null && blog.coverImageUrl!.isNotEmpty
                ? Image.network(blog.coverImageUrl!, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => const SizedBox())
                : null,
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: 12, left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFD60A)),
                SizedBox(width: 4),
                Text('Featured', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          Positioned(bottom: 16, left: 14, right: 14, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF5E5CE6), borderRadius: BorderRadius.circular(8)),
                child: Text(blog.category, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              Text(blog.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(children: [
                CircleAvatar(radius: 10, backgroundColor: const Color(0xFF8B7CF6), child: Text(blog.psychologistName[0], style: const TextStyle(color: Colors.white, fontSize: 9))),
                const SizedBox(width: 6),
                Expanded(child: Text(blog.psychologistName, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12), overflow: TextOverflow.ellipsis)),
                const Icon(Icons.visibility_outlined, color: Color(0x99FFFFFF), size: 13),
                const SizedBox(width: 3),
                Text('${blog.viewCount}', style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
              ]),
            ],
          )),
        ]),
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  final BlogEntity blog;
  final VoidCallback onTap;
  const _BlogCard({required this.blog, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Container(
              height: 100,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF30B0C7), Color(0xFF34C7A3)]),
              ),
              child: blog.coverImageUrl != null && blog.coverImageUrl!.isNotEmpty
                  ? Image.network(blog.coverImageUrl!, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => const SizedBox())
                  : Center(child: Text(_categoryEmoji(blog.category), style: const TextStyle(fontSize: 32))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(6)),
                child: Text(blog.category, style: const TextStyle(color: Color(0xFF5E5CE6), fontSize: 9, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 5),
              Text(blog.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: Text(blog.psychologistName, style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93)), overflow: TextOverflow.ellipsis)),
                const Icon(Icons.visibility_outlined, size: 11, color: Color(0xFFCECED6)),
                const SizedBox(width: 2),
                Text('${blog.viewCount}', style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93))),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  String _categoryEmoji(String cat) {
    const map = {'Anxiety': '😰', 'Depression': '💙', 'Stress': '🧘', 'Sleep': '😴', 'Relationships': '💞', 'Trauma': '🌱', 'Mindfulness': '🌿'};
    return map[cat] ?? '📖';
  }
}
