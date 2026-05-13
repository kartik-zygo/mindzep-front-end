import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
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

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = [
    _OnboardingData(
      title: AppStrings.onboardingTitle1,
      body: AppStrings.onboardingBody1,
      icon: Icons.person_search_rounded,
      color: const Color(0xFF6C63FF),
    ),
    _OnboardingData(
      title: AppStrings.onboardingTitle2,
      body: AppStrings.onboardingBody2,
      icon: Icons.calendar_month_rounded,
      color: const Color(0xFF9D97FF),
    ),
    _OnboardingData(
      title: AppStrings.onboardingTitle3,
      body: AppStrings.onboardingBody3,
      icon: Icons.favorite_rounded,
      color: const Color(0xFF6C63FF),
    ),
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) context.go(RouteNames.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: _currentPage < 2
                    ? TextButton(
                        onPressed: _complete,
                        child: Text(
                          AppStrings.skip,
                          style: AppTextStyles.subheadline
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    : const SizedBox(height: 40),
              ),
            ),
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (ctx, i) => _OnboardingPageView(data: _pages[i]),
              ),
            ),
            // Indicator + button
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingXL),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      dotColor: AppColors.primaryLight,
                      activeDotColor: AppColors.primary,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                  AppButton(
                    label: _currentPage == _pages.length - 1
                        ? AppStrings.getStarted
                        : 'Next',
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        _complete();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  const _OnboardingData(
      {required this.title,
      required this.body,
      required this.icon,
      required this.color});
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingPageView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [data.color, data.color.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 90, color: Colors.white),
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            style: AppTextStyles.title1
                .copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            data.body,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
