import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_error_model.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../injection/injection_container.dart';
import '../../../user/data/models/user_models.dart';
import '../../../user/data/repositories/user_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';

/// Shown after a brand-new account is created via Google Sign-Up.
///
/// Google accounts arrive with no phone number on the backend (stored NULL) —
/// collect it here since it's needed for SMS OTP and payment KYC flows. The
/// user may skip and add it later from their profile.
class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  late final UserRepository _userRepository;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _userRepository = sl<UserRepository>();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _goHome() {
    final user = context.read<AuthBloc>().currentUser;
    switch (user?.role) {
      case UserRole.psychologist:
        context.go(RouteNames.psychDashboard);
        break;
      case UserRole.admin:
        context.go(RouteNames.adminDashboard);
        break;
      case UserRole.user:
      default:
        context.go(RouteNames.userHome);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _userRepository.updateMe(
        UserUpdateRequest(phone: _phoneCtrl.text.trim()),
      );
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: 'Phone number saved!',
        type: SnackbarType.success,
      );
      _goHome();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final message = error is ApiErrorModel
          ? error.message
          : 'Could not save your phone number. Please try again.';
      AppSnackbar.show(context, message: message, type: SnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusXL),
                    ),
                    child: const Icon(Icons.phone_iphone_rounded,
                        size: 42, color: Colors.white),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingL),
                Text(
                  'Complete your profile',
                  style:
                      AppTextStyles.title1.copyWith(color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.paddingXS),
                Text(
                  'Add your phone number so we can reach you about '
                  'sessions and account security.',
                  style: AppTextStyles.subheadline
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                AppTextField(
                  controller: _phoneCtrl,
                  hintText: 'Mobile number',
                  labelText: AppStrings.phoneNumber,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  prefixText: '+91 ',
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  validator: AppValidators.phone,
                ),
                const SizedBox(height: AppDimensions.paddingL),
                AppButton(
                  label: AppStrings.save,
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
                const SizedBox(height: AppDimensions.paddingM),
                Center(
                  child: TextButton(
                    onPressed: _isSaving ? null : _goHome,
                    child: Text(
                      'Skip for now',
                      style: AppTextStyles.subheadline
                          .copyWith(color: AppColors.textSecondary),
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
