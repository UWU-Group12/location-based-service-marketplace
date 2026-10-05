import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class ProviderVerificationStatusScreen extends StatelessWidget {
  final String verificationStatus;

  const ProviderVerificationStatusScreen({
    super.key,
    required this.verificationStatus,
  });

  bool get _isRejected => verificationStatus.trim().toLowerCase() == 'rejected';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accentColor = _isRejected ? AppColors.error : AppColors.primary;
    final icon = _isRejected ? Icons.close_rounded : Icons.schedule_rounded;
    final title = _isRejected
        ? 'Your request was rejected'
        : 'Your documents are being reviewed';
    final message = _isRejected
        ? 'Your provider verification documents were rejected. Please contact support for the next steps.'
        : 'We are checking your submitted documents. Your provider dashboard will open automatically after approval.';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 66, color: accentColor),
                ),
                const SizedBox(height: 34),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
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
