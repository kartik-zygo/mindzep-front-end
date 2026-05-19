import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../domain/entities/user_entity.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(LoginRequested(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            switch (state.user.role) {
              case UserRole.user:
                context.go(RouteNames.userHome);
                break;
              case UserRole.psychologist:
                context.go(RouteNames.psychDashboard);
                break;
              case UserRole.admin:
                context.go(RouteNames.adminDashboard);
                break;
            }
          });
        } else if (state is AuthError) {
          AppSnackbar.show(context,
              message: state.message, type: SnackbarType.error);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingXL),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  // Logo
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusXL),
                      ),
                      child: const Icon(Icons.psychology_rounded,
                          size: 46, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  Text(
                    AppStrings.appName,
                    style:
                        AppTextStyles.title1.copyWith(color: AppColors.primary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.paddingXS),
                  Text(
                    AppStrings.appTagline,
                    style: AppTextStyles.subheadline
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Email
                  AppTextField(
                    controller: _emailCtrl,
                    hintText: 'Email address',
                    labelText: AppStrings.email,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: AppValidators.email,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  // Password
                  AppTextField(
                    controller: _passwordCtrl,
                    hintText: 'Enter password',
                    labelText: AppStrings.password,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline_rounded,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Password is required' : null,
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(RouteNames.forgotPassword),
                      child: Text(
                        AppStrings.forgotPassword,
                        style: AppTextStyles.subheadline
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  // Login button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (ctx, state) => AppButton(
                      label: AppStrings.login,
                      isLoading: state is AuthLoading,
                      onPressed: _login,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingM),
                        child: Text(
                          AppStrings.orDivider,
                          style: AppTextStyles.subheadline
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  // Google Sign-In
                  AppButton(
                    label: AppStrings.continueWithGoogle,
                    style: AppButtonStyle.outlined,
                    prefixIcon: Icons.g_mobiledata_rounded,
                    onPressed: () => context
                        .read<AuthBloc>()
                        .add(const GoogleSignInRequested()),
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                  // Register link
                  Center(
                    child: TextButton(
                      onPressed: () => context.push(RouteNames.register),
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.subheadline
                              .copyWith(color: AppColors.textSecondary),
                          children: [
                            const TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: 'Register',
                              style: AppTextStyles.subheadline
                                  .copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  // Integration hint
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Backend Authentication Enabled',
                            style: AppTextStyles.footnote.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Text('Use credentials created through Register + OTP verification.',
                            style: AppTextStyles.caption1
                                .copyWith(color: AppColors.textSecondary)),
                        Text('For Google login, wire a real idToken provider before production release.',
                            style: AppTextStyles.caption1
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
