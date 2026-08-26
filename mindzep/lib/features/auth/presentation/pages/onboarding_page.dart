import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final _controller = PageController();
  late final AnimationController _entranceController;
  double _pageValue = 0;

  final _pages = [
    _OnboardingData(
      title: AppStrings.onboardingTitle1,
      body: AppStrings.onboardingBody1,
      animationPath: AppAssets.onboardingCareAnimation,
      icon: Icons.favorite_rounded,
      color: const Color(0xFF8E97FD),
    ),
    _OnboardingData(
      title: AppStrings.onboardingTitle2,
      body: AppStrings.onboardingBody2,
      animationPath: AppAssets.onboardingSearchAnimation,
      icon: Icons.person_search_rounded,
      color: const Color(0xFF6C63FF),
    ),
    _OnboardingData(
      title: AppStrings.onboardingTitle3,
      body: AppStrings.onboardingBody3,
      animationPath: AppAssets.onboardingBookingAnimation,
      icon: Icons.calendar_month_rounded,
      color: const Color(0xFF9D97FF),
    ),
    _OnboardingData(
      title: AppStrings.onboardingTitle4,
      body: AppStrings.onboardingBody4,
      animationPath: AppAssets.onboardingHealingAnimation,
      icon: Icons.spa_rounded,
      color: const Color(0xFF6FA8FF),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onPageScroll);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  void _onPageScroll() {
    setState(() => _pageValue = _controller.page ?? 0);
  }

  int get _currentPage => _pageValue.round();

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) context.go(RouteNames.login);
  }

  Future<void> _goToPage(int index) async {
    await _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _goToNextPage() async {
    if (_currentPage < _pages.length - 1) {
      await _goToPage(_currentPage + 1);
    }
  }

  Future<void> _goToPreviousPage() async {
    if (_currentPage > 0) {
      await _goToPage(_currentPage - 1);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onPageScroll);
    _controller.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Color _backgroundTint() {
    final clamped = _pageValue.clamp(0, _pages.length - 1).toDouble();
    final index = clamped.floor();
    final nextIndex = (index + 1).clamp(0, _pages.length - 1);
    final t = clamped - index;
    return Color.lerp(_pages[index].color, _pages[nextIndex].color, t) ??
        _pages[index].color;
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entranceController,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _backgroundTint().withOpacity(0.16),
                        AppColors.background,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.6],
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  // Skip button
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: isLastPage ? 0 : 1,
                        child: IgnorePointer(
                          ignoring: isLastPage,
                          child: TextButton(
                            onPressed: _complete,
                            child: Text(
                              AppStrings.skip,
                              style: AppTextStyles.subheadline
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // PageView
                  Expanded(
                    child: GestureDetector(
                      // Explicit horizontal swipe support between onboarding pages.
                      onHorizontalDragEnd: (details) {
                        final velocity = details.primaryVelocity ?? 0;
                        if (velocity < -150) {
                          _goToNextPage();
                        } else if (velocity > 150) {
                          _goToPreviousPage();
                        }
                      },
                      child: PageView.builder(
                        controller: _controller,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _pages.length,
                        itemBuilder: (ctx, i) {
                          final offset = (_pageValue - i).clamp(-1.0, 1.0);
                          return _OnboardingPageView(
                            data: _pages[i],
                            pageOffset: offset,
                          );
                        },
                      ),
                    ),
                  ),
                  // Indicator + button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.paddingXL,
                      AppDimensions.paddingM,
                      AppDimensions.paddingXL,
                      AppDimensions.paddingXL,
                    ),
                    child: Column(
                      children: [
                        SmoothPageIndicator(
                          controller: _controller,
                          count: _pages.length,
                          effect: ExpandingDotsEffect(
                            dotColor: AppColors.primaryLight.withOpacity(0.35),
                            activeDotColor: _backgroundTint(),
                            dotHeight: 8,
                            dotWidth: 8,
                            spacing: 6,
                            expansionFactor: 3,
                          ),
                          onDotClicked: (index) => _goToPage(index),
                        ),
                        const SizedBox(height: AppDimensions.paddingXL),
                        AppButton(
                          label: isLastPage
                              ? AppStrings.getStarted
                              : 'Next',
                          onPressed: isLastPage ? _complete : _goToNextPage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String body;
  final String animationPath;
  final IconData icon;
  final Color color;
  const _OnboardingData({
    required this.title,
    required this.body,
    required this.animationPath,
    required this.icon,
    required this.color,
  });
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingData data;

  /// -1 (entering from the right) .. 0 (centered) .. 1 (exiting to the left)
  final double pageOffset;

  const _OnboardingPageView({required this.data, required this.pageOffset});

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - pageOffset.abs()).clamp(0.0, 1.0);
    final scale = 1 - pageOffset.abs() * 0.25;

    return LayoutBuilder(
      builder: (context, constraints) {
        final animationSize = constraints.maxHeight * 0.42;
        final clampedSize = animationSize.clamp(160.0, 300.0);

        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppDimensions.paddingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.translate(
                offset: Offset(0, pageOffset * 40),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: _AnimationBubble(
                      data: data,
                      size: clampedSize.toDouble(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXL),
              Transform.translate(
                offset: Offset(0, pageOffset * 60),
                child: Opacity(
                  opacity: opacity,
                  child: Column(
                    children: [
                      Text(
                        data.title,
                        style: AppTextStyles.title1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      Text(
                        data.body,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimationBubble extends StatelessWidget {
  final _OnboardingData data;
  final double size;

  const _AnimationBubble({required this.data, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            data.color.withOpacity(0.18),
            data.color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Lottie.asset(
        data.animationPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          data.icon,
          size: size * 0.45,
          color: data.color,
        ),
      ),
    );
  }
}
