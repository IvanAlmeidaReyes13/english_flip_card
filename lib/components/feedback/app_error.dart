import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../buttons/app_button.dart';

class AppError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppError({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: AppButton(
                  text: 'Reintentar',
                  onPressed: onRetry,
                  icon: Icons.refresh,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
