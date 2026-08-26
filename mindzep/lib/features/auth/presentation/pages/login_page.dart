import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/auth_layout.dart';
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
            // Brand-new Google accounts have no phone number — collect it
            // before landing on the home screen.
            if (state.isNewGoogleUser) {
              context.go(RouteNames.completeProfile);
              return;
            }
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
      child: AuthLayout(
        title: 'Welcome Back',
        subtitle: 'Sign in to continue your journey to better mental health.',
        icon: Icons.psychology_rounded,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: AppDimensions.paddingXS),
              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(RouteNames.forgotPassword),
                  child: Text(
                    AppStrings.forgotPassword,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.24,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingS),
              // Login button
              BlocBuilder<AuthBloc, AuthState>(
                builder: (ctx, state) => _GlowButton(
                  child: AppButton(
                    label: AppStrings.login,
                    isLoading: state is AuthLoading,
                    onPressed: _login,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXL),
              // Divider
              const AuthOrDivider(),
              const SizedBox(height: AppDimensions.paddingXL),
              // Google Sign-In
              BlocBuilder<AuthBloc, AuthState>(
                builder: (ctx, state) => AppButton(
                  label: AppStrings.continueWithGoogle,
                  style: AppButtonStyle.outlined,
                  prefixIcon: Icons.g_mobiledata_rounded,
                  onPressed: state is AuthLoading
                      ? null
                      : () => ctx
                          .read<AuthBloc>()
                          .add(const GoogleSignInRequested()),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXL),
              // Register link
              AuthFooterLink(
                leading: "Don't have an account? ",
                action: 'Register',
                onTap: () => context.push(RouteNames.register),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps the primary CTA with a soft brand-colored glow shadow.
class _GlowButton extends StatelessWidget {
  final Widget child;

  const _GlowButton({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
