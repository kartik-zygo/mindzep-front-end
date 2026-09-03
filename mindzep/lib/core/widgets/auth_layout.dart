import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';

/// Responsive shell shared by the auth screens (login, register, ...).
///
/// Narrow screens (phones/small tablets) get a single scrollable column with
/// a compact branded header above the form and soft decorative blobs in the
/// background. Wide screens (large tablets/desktop/web) split into a
/// branding panel on the left and a centered form panel on the right.
class AuthLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool showBackButton;
  final VoidCallback? onBack;

  const AuthLayout({
    super.key,
    required this.child,
    required this.title,
    required this.subtitle,
    this.icon = Icons.psychology_rounded,
    this.showBackButton = false,
    this.onBack,
  });

  static const double wideBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= wideBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: _BrandPanel(title: title, subtitle: subtitle, icon: icon),
                  ),
                  Expanded(
                    flex: 6,
                    child: _FormPanel(
                      showHeader: false,
                      showBackButton: showBackButton,
                      onBack: onBack,
                      title: title,
                      subtitle: subtitle,
                      icon: icon,
                      child: child,
                    ),
                  ),
                ],
              )
            : _FormPanel(
                showHeader: true,
                showBackButton: showBackButton,
                onBack: onBack,
                title: title,
                subtitle: subtitle,
                icon: icon,
                child: child,
              ),
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  final Widget child;
  final bool showHeader;
  final bool showBackButton;
  final VoidCallback? onBack;
  final String title;
  final String subtitle;
  final IconData icon;

  const _FormPanel({
    required this.child,
    required this.showHeader,
    required this.showBackButton,
    required this.onBack,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 360
        ? AppDimensions.paddingM
        : width < 600
            ? AppDimensions.paddingL
            : AppDimensions.paddingXL;
    final verticalPadding = width < 360 ? AppDimensions.paddingM : AppDimensions.paddingL;

    return Stack(
      children: [
        if (showHeader) const Positioned.fill(child: _AuroraBackground()),
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _AnimatedEntrance(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showBackButton)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _CircleIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: onBack ?? () => Navigator.of(context).maybePop(),
                          ),
                        ),
                      ),
                    if (showHeader) _MobileHeader(title: title, subtitle: subtitle, icon: icon),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _MobileHeader({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingXL),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(icon, size: 36, color: Colors.white),
          ),
          const SizedBox(height: AppDimensions.paddingL),
          Text(
            AppStrings.appName,
            style: AppTextStyles.title3.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            title,
            style: AppTextStyles.title1.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingXS),
          Text(
            subtitle,
            style: AppTextStyles.subheadline.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _BrandPanel({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -70,
            child: _blob(240, Colors.white.withOpacity(0.08)),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: _blob(280, Colors.white.withOpacity(0.06)),
          ),
          Positioned(
            top: 140,
            left: -40,
            child: _blob(140, Colors.white.withOpacity(0.05)),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingXL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: Icon(icon, color: Colors.white, size: 38),
                    ),
                    const SizedBox(height: AppDimensions.paddingXL),
                    Text(
                      AppStrings.appName,
                      style: AppTextStyles.largeTitle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    Text(
                      title,
                      style: AppTextStyles.title2.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppDimensions.paddingS),
                    Text(
                      subtitle,
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withOpacity(0.85),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingXL * 1.25),
                    const _FeatureRow(
                      icon: Icons.verified_user_rounded,
                      text: 'Licensed & verified psychologists',
                    ),
                    const _FeatureRow(
                      icon: Icons.lock_rounded,
                      text: 'Private & confidential sessions',
                    ),
                    const _FeatureRow(
                      icon: Icons.bolt_rounded,
                      text: 'Connect within minutes, anytime',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.subheadline.copyWith(color: Colors.white.withOpacity(0.9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -80,
            child: _blob(260, AppColors.primary.withOpacity(0.10)),
          ),
          Positioned(
            top: 60,
            left: -100,
            child: _blob(200, AppColors.primaryLight.withOpacity(0.12)),
          ),
          Positioned(
            bottom: -120,
            right: -60,
            child: _blob(220, AppColors.primaryLight.withOpacity(0.08)),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _AnimatedEntrance extends StatelessWidget {
  final Widget child;

  const _AnimatedEntrance({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 28),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.15),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

/// Footer link used for "Don't have an account? Register" style prompts.
class AuthFooterLink extends StatelessWidget {
  final String leading;
  final String action;
  final VoidCallback onTap;

  const AuthFooterLink({
    super.key,
    required this.leading,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onTap,
        child: RichText(
          text: TextSpan(
            style: AppTextStyles.subheadline.copyWith(color: AppColors.textSecondary),
            children: [
              TextSpan(text: leading),
              TextSpan(
                text: action,
                style: AppTextStyles.subheadline.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section heading used to group fields within a form (e.g. "Personal details").
class AuthSectionLabel extends StatelessWidget {
  final String label;

  const AuthSectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: Text(
        label,
        style: AppTextStyles.footnote.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
