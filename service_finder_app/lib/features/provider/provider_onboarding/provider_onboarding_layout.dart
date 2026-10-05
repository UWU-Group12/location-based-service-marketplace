import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

/// Centers short steps within the viewport resized by the Scaffold for the
/// keyboard. Long steps scroll naturally, without adding the keyboard inset twice.
class ProviderOnboardingBody extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const ProviderOnboardingBody({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: padding + const EdgeInsets.symmetric(vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - padding.vertical - 48).clamp(
                0.0,
                double.infinity,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [child],
            ),
          ),
        ),
      ),
    );
  }
}

class ProviderOnboardingHeroText extends StatelessWidget {
  final List<ProviderOnboardingHeroSegment> segments;

  const ProviderOnboardingHeroText({super.key, required this.segments});

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        for (var index = 0; index < segments.length; index++)
          TextSpan(
            text: '${index == 0 ? '' : ' '}${segments[index].text}',
            style: TextStyle(
              color: segments[index].muted
                  ? AppColors.textPrimary.withValues(alpha: 0.34)
                  : AppColors.primary,
            ),
          ),
      ],
    ),
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: AppColors.primary,
      fontSize: 34,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
      height: 1.08,
    ),
  );
}

class ProviderOnboardingHeroSegment {
  final String text;
  final bool muted;

  const ProviderOnboardingHeroSegment(this.text, {this.muted = false});
}
