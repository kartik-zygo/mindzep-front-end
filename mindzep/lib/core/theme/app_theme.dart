import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_dimensions.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          error: AppColors.error,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
            color: AppColors.textPrimary,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          elevation: 0,
          height: AppDimensions.bottomNavHeight,
          indicatorColor: AppColors.primary.withOpacity(0.12),
          labelTextStyle: WidgetStateProperty.all(AppTextStyles.caption1),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primary, size: 24);
            }
            return const IconThemeData(color: AppColors.textSecondary, size: 24);
          }),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: AppDimensions.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingM,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
          labelStyle: AppTextStyles.callout.copyWith(color: AppColors.textSecondary),
          errorStyle: AppTextStyles.caption1.copyWith(color: AppColors.error),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceSecondary,
          selectedColor: AppColors.primary,
          labelStyle: AppTextStyles.subheadline,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingS,
            vertical: AppDimensions.paddingXS,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 0.5,
          space: 0,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusXL),
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
        ),
      );
}
