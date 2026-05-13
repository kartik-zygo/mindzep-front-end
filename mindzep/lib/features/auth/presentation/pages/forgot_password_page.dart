import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  int _step = 0; // 0: email, 1: OTP, 2: new password
  String _sentEmail = '';

  final _emailCtrl = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();
  final _pwFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpSent) {
          setState(() {
            _sentEmail = state.email;
            _step = 1;
          });
        } else if (state is AuthOtpVerified) {
          setState(() => _step = 2);
        } else if (state is AuthPasswordResetSuccess) {
          AppSnackbar.show(context,
              message: 'Password reset successfully!',
              type: SnackbarType.success);
          context.go(RouteNames.login);
        } else if (state is AuthError) {
          AppSnackbar.show(context,
              message: state.message, type: SnackbarType.error);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Reset Password'),
            backgroundColor: AppColors.background,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingXL),
            child: [
              _buildEmailStep(state),
              _buildOtpStep(state),
              _buildNewPasswordStep(state),
            ][_step],
          ),
        );
      },
    );
  }

  Widget _buildEmailStep(AuthState state) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          const Icon(Icons.lock_reset_rounded,
              size: 64, color: AppColors.primary),
          const SizedBox(height: AppDimensions.paddingL),
          Text('Forgot your password?',
              style:
                  AppTextStyles.title2.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
              'Enter your registered email and we\'ll send you a verification code.',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 40),
          AppTextField(
            controller: _emailCtrl,
            hintText: 'Email address',
            labelText: 'Email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: AppValidators.email,
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          AppButton(
            label: 'Send OTP',
            isLoading: state is AuthLoading,
            onPressed: () {
              if (_emailFormKey.currentState!.validate()) {
                context.read<AuthBloc>().add(
                    ForgotPasswordRequested(email: _emailCtrl.text.trim()));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep(AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        const Icon(Icons.message_outlined, size: 64, color: AppColors.primary),
        const SizedBox(height: AppDimensions.paddingL),
        Text('Verify OTP',
            style: AppTextStyles.title2.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center),
        const SizedBox(height: AppDimensions.paddingS),
        Text('Enter the 6-digit code sent to $_sentEmail',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center),
        const SizedBox(height: 40),
        // 6 OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            6,
            (i) => SizedBox(
              width: 46,
              child: TextFormField(
                controller: _otpControllers[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: AppTextStyles.title3
                    .copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusM),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                onChanged: (v) {
                  if (v.isNotEmpty && i < 5) {
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
          onPressed: () {
            final otp =
                _otpControllers.map((c) => c.text).join();
            context.read<AuthBloc>().add(OtpVerified(otp: otp));
          },
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Center(
          child: TextButton(
            onPressed: () => context.read<AuthBloc>().add(
                ForgotPasswordRequested(email: _sentEmail)),
            child: Text('Resend OTP',
                style: AppTextStyles.subheadline
                    .copyWith(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep(AuthState state) {
    return Form(
      key: _pwFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          const Icon(Icons.lock_open_rounded,
              size: 64, color: AppColors.primary),
          const SizedBox(height: AppDimensions.paddingL),
          Text('Set New Password',
              style:
                  AppTextStyles.title2.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 40),
          AppTextField(
            controller: _newPwCtrl,
            hintText: 'New password',
            labelText: 'New Password',
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
            validator: AppValidators.password,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          AppTextField(
            controller: _confirmPwCtrl,
            hintText: 'Confirm new password',
            labelText: 'Confirm Password',
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.done,
            validator: (v) =>
                AppValidators.confirmPassword(v, _newPwCtrl.text),
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          AppButton(
            label: 'Reset Password',
            isLoading: state is AuthLoading,
            onPressed: () {
              if (_pwFormKey.currentState!.validate()) {
                context
                    .read<AuthBloc>()
                    .add(PasswordResetRequested(
                        newPassword: _newPwCtrl.text));
              }
            },
          ),
        ],
      ),
    );
  }
}
