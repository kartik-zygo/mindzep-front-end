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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  String _selectedRole = 'user';
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  void _register() {
    if (!_agreedToTerms) {
      AppSnackbar.show(context,
          message: 'Please accept the terms & conditions',
          type: SnackbarType.warning);
      return;
    }
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(RegisterRequested(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            password: _passwordCtrl.text,
            role: _selectedRole,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpSent && state.purpose == 'registration') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.push(
              RouteNames.verifyOtp,
              extra: {
                'identifier': state.identifier,
                'purpose': state.purpose,
              },
            );
          });
        } else if (state is AuthAuthenticated) {
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
        appBar: AppBar(
          title: const Text('Create Account'),
          backgroundColor: AppColors.background,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _nameCtrl,
                  hintText: 'Your full name',
                  labelText: AppStrings.fullName,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: AppValidators.fullName,
                ),
                const SizedBox(height: AppDimensions.paddingM),
                AppTextField(
                  controller: _emailCtrl,
                  hintText: 'Email address',
                  labelText: AppStrings.email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: AppValidators.email,
                ),
                const SizedBox(height: AppDimensions.paddingM),
                AppTextField(
                  controller: _phoneCtrl,
                  hintText: 'Mobile number',
                  labelText: AppStrings.phoneNumber,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  prefixText: '+91 ',
                  validator: AppValidators.phone,
                ),
                const SizedBox(height: AppDimensions.paddingM),
                AppTextField(
                  controller: _passwordCtrl,
                  hintText: 'Create a password',
                  labelText: AppStrings.password,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: AppValidators.password,
                ),
                const SizedBox(height: AppDimensions.paddingM),
                AppTextField(
                  controller: _confirmPwCtrl,
                  hintText: 'Confirm password',
                  labelText: AppStrings.confirmPassword,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      AppValidators.confirmPassword(v, _passwordCtrl.text),
                ),
                const SizedBox(height: AppDimensions.paddingL),
                // Role selector
                Text('I am a',
                    style: AppTextStyles.subheadline
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppDimensions.paddingS),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        label: 'User',
                        icon: Icons.person_rounded,
                        isSelected: _selectedRole == 'user',
                        onTap: () => setState(() => _selectedRole = 'user'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingM),
                    Expanded(
                      child: _RoleCard(
                        label: 'Psychologist',
                        icon: Icons.psychology_rounded,
                        isSelected: _selectedRole == 'psychologist',
                        onTap: () =>
                            setState(() => _selectedRole = 'psychologist'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingL),
                // T&C
                CheckboxListTile(
                  value: _agreedToTerms,
                  onChanged: (v) => setState(() => _agreedToTerms = v!),
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusS)),
                  title: RichText(
                    text: TextSpan(
                      style: AppTextStyles.subheadline
                          .copyWith(color: AppColors.textSecondary),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: AppTextStyles.subheadline
                              .copyWith(color: AppColors.primary),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: AppTextStyles.subheadline
                              .copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingL),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (ctx, state) => AppButton(
                    label: 'Create Account',
                    isLoading: state is AuthLoading,
                    onPressed: _register,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingL),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.subheadline
                            .copyWith(color: AppColors.textSecondary),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Login',
                            style: AppTextStyles.subheadline
                                .copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color:
                    isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 32),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              label,
              style: AppTextStyles.subheadline.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
