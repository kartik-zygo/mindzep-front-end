import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/network/api_error_model.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_badge.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../injection/injection_container.dart';
import '../../../../user/blog/data/models/blog_models.dart';
import '../../../../user/blog/data/repositories/blog_repository.dart';

class AdminBlogManagementPage extends StatefulWidget {
  const AdminBlogManagementPage({super.key});

  @override
  State<AdminBlogManagementPage> createState() =>
      _AdminBlogManagementPageState();
}

class _AdminBlogManagementPageState extends State<AdminBlogManagementPage>
    with SingleTickerProviderStateMixin {
  late final BlogRepository _blogRepository;
  late TabController _tabCtrl;

  bool _loading = true;
  String? _loadError;
  List<BlogEntity> _blogs = const [];

  static const _adminGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _blogRepository = sl<BlogRepository>();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadBlogs();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBlogs() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final results = await _blogRepository.listAdminAllBlogs(page: 1, limit: 100);
      if (!mounted) return;
      setState(() {
        _blogs = results.map((m) => m.toEntity()).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadError = e is ApiErrorModel ? e.message : 'Failed to load blogs.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  List<BlogEntity> _filtered(String filter) {
    return switch (filter) {
      'Under Review' => _blogs.where((b) => b.status == BlogStatus.underReview).toList(),
      'Published'    => _blogs.where((b) => b.status == BlogStatus.published).toList(),
      'Rejected'     => _blogs.where((b) => b.status == BlogStatus.rejected).toList(),
      _              => _blogs,
    };
  }

  Future<void> _approve(BlogEntity blog) async {
    try {
      await _blogRepository.approveBlog(blog.id, const BlogReviewRequest());
      if (!mounted) return;
      AppSnackbar.show(context, message: '"${blog.title}" approved and published.', type: SnackbarType.success);
      _loadBlogs();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiErrorModel ? e.message : 'Failed to approve blog.';
      AppSnackbar.show(context, message: msg, type: SnackbarType.error);
    }
  }

  void _reject(BlogEntity blog) {
    _showRejectDialog(blog);
  }

  void _showRejectDialog(BlogEntity blog) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        title: const Text('Reject Blog Post', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${blog.title}"',
              style: AppTextStyles.footnote.copyWith(color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Text('Reason for rejection', style: AppTextStyles.caption1.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., Needs clinical references, inappropriate language...',
                hintStyle: AppTextStyles.caption1.copyWith(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final reason = reasonCtrl.text.trim().isNotEmpty
                  ? reasonCtrl.text.trim()
                  : 'Blog rejected by admin.';
              try {
                await _blogRepository.rejectBlog(
                  blog.id,
                  BlogRejectionRequest(rejectionReason: reason),
                );
                if (!mounted) return;
                AppSnackbar.show(context, message: '"${blog.title}" rejected.', type: SnackbarType.warning);
                _loadBlogs();
              } catch (e) {
                if (!mounted) return;
                final msg = e is ApiErrorModel ? e.message : 'Failed to reject blog.';
                AppSnackbar.show(context, message: msg, type: SnackbarType.error);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final underReviewCount =
        _blogs.where((b) => b.status == BlogStatus.underReview).length;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(_loadError!, textAlign: TextAlign.center, style: AppTextStyles.body),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadBlogs, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: _adminGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Blog Management',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (underReviewCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusFull),
                              ),
                              child: Text(
                                '$underReviewCount pending',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review and approve blog submissions',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TabBar(
                        controller: _tabCtrl,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorColor: Colors.white,
                        labelColor: Colors.white,
                        unselectedLabelColor:
                            Colors.white.withOpacity(0.6),
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.label,
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: 'All (${_blogs.length})'),
                          Tab(text: 'Under Review ($underReviewCount)'),
                          Tab(
                              text:
                                  'Published (${_blogs.where((b) => b.status == BlogStatus.published).length})'),
                          Tab(
                              text:
                                  'Rejected (${_blogs.where((b) => b.status == BlogStatus.rejected).length})'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _BlogList(
              blogs: _filtered('All'),
              onApprove: _approve,
              onReject: _reject,
            ),
            _BlogList(
              blogs: _filtered('Under Review'),
              onApprove: _approve,
              onReject: _reject,
            ),
            _BlogList(
              blogs: _filtered('Published'),
              onApprove: _approve,
              onReject: _reject,
            ),
            _BlogList(
              blogs: _filtered('Rejected'),
              onApprove: _approve,
              onReject: _reject,
            ),
          ],
        ),
      ),
    );
  }
}

class _BlogList extends StatelessWidget {
  final List<BlogEntity> blogs;
  final void Function(BlogEntity) onApprove;
  final void Function(BlogEntity) onReject;

  const _BlogList({
    required this.blogs,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (blogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'No blogs here',
              style: AppTextStyles.subheadline
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: blogs.length,
      itemBuilder: (_, i) => _BlogCard(
        blog: blogs[i],
        onApprove: onApprove,
        onReject: onReject,
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  final BlogEntity blog;
  final void Function(BlogEntity) onApprove;
  final void Function(BlogEntity) onReject;

  const _BlogCard({
    required this.blog,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isUnderReview = blog.status == BlogStatus.underReview;

    return AppCard(
      margin:
          const EdgeInsets.only(bottom: AppDimensions.paddingM),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pending banner
          if (isUnderReview)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.warning.withOpacity(0.15),
                    AppColors.warning.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radiusL),
                  topRight: Radius.circular(AppDimensions.radiusL),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Awaiting Review',
                    style: AppTextStyles.caption1.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          // Cover image
          if (blog.coverImageUrl != null)
            ClipRRect(
              borderRadius: isUnderReview
                  ? BorderRadius.zero
                  : const BorderRadius.only(
                      topLeft: Radius.circular(AppDimensions.radiusL),
                      topRight: Radius.circular(AppDimensions.radiusL),
                    ),
              child: Image.network(
                blog.coverImageUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  color: AppColors.surfaceSecondary,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: AppColors.textTertiary),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category + Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull),
                      ),
                      child: Text(
                        blog.category,
                        style: AppTextStyles.caption2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    StatusBadge(status: _statusLabel(blog.status)),
                  ],
                ),
                const SizedBox(height: 10),
                // Title
                Text(
                  blog.title,
                  style: AppTextStyles.subheadline
                      .copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Body preview
                Text(
                  blog.body,
                  style: AppTextStyles.caption1
                      .copyWith(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Author row
                Row(
                  children: [
                    AppAvatar(
                      imageUrl: blog.psychologistAvatar,
                      radius: 14,
                      initials: blog.psychologistName[0],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            blog.psychologistName,
                            style: AppTextStyles.caption1
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _dateLabel(blog.createdAt),
                            style: AppTextStyles.caption2
                                .copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    if (blog.status == BlogStatus.published) ...[
                      const Icon(Icons.visibility_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${blog.viewCount}',
                        style: AppTextStyles.caption1
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
                // Tags
                if (blog.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: blog.tags
                        .take(4)
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusFull),
                            ),
                            child: Text(
                              '#$tag',
                              style: AppTextStyles.caption2
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                // Action buttons (only for underReview)
                if (isUnderReview) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onReject(blog),
                          icon: const Icon(Icons.close_rounded,
                              size: 16, color: AppColors.error),
                          label: const Text(
                            'Reject',
                            style: TextStyle(color: AppColors.error),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM),
                            ),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => onApprove(blog),
                          icon: const Icon(Icons.check_rounded,
                              size: 16, color: Colors.white),
                          label: const Text(
                            'Approve',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM),
                            ),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(BlogStatus s) => switch (s) {
        BlogStatus.published => 'Published',
        BlogStatus.underReview => 'Under Review',
        BlogStatus.rejected => 'Rejected',
        BlogStatus.draft => 'Draft',
      };

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}
