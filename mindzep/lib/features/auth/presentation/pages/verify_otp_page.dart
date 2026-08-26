import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({
    super.key,
    required this.identifier,
    required this.purpose,
  });

  final String identifier;
  final String purpose;

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
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
          return;
        }

        if (state is AuthOperationSuccess) {
          AppSnackbar.show(
            context,
            message: state.message,
            type: SnackbarType.success,
          );
          return;
        }

        if (state is AuthError) {
          AppSnackbar.show(
            context,
            message: state.message,
            type: SnackbarType.error,
          );
          return;
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Verify OTP'),
            backgroundColor: AppColors.background,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Icon(
                  Icons.verified_user_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppDimensions.paddingL),
                Text(
                  'Enter Verification Code',
                  style: AppTextStyles.title2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.paddingS),
                Text(
                  'We sent a 6-digit OTP to ${widget.identifier}',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 44,
                      child: TextField(
                        controller: _otpControllers[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: AppTextStyles.title3,
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusM,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusM,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            FocusScope.of(context).nextFocus();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingXL),
                AppButton(
                  label: 'Verify OTP',
                  isLoading: state is AuthLoading,
                  onPressed: _verifyOtp,
                ),
                const SizedBox(height: AppDimensions.paddingM),
                TextButton(
                  onPressed: state is AuthLoading ? null : _resendOtp,
                  child: Text(
                    'Resend OTP',
                    style: AppTextStyles.subheadline.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _verifyOtp() {
    final otp = _otpControllers.map((controller) => controller.text).join();
    if (otp.length != 6) {
      AppSnackbar.show(
        context,
        message: 'Please enter a valid 6-digit OTP.',
        type: SnackbarType.warning,
      );
      return;
    }

    context.read<AuthBloc>().add(
          OtpVerified(
            identifier: widget.identifier,
            otp: otp,
            purpose: widget.purpose,
          ),
        );
  }

  void _resendOtp() {
    context.read<AuthBloc>().add(
          ResendOtpRequested(
            identifier: widget.identifier,
            purpose: widget.purpose,
          ),
        );
  }
}
