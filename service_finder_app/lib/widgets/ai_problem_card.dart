import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_router.dart';

class AiProblemCard extends StatefulWidget {
  const AiProblemCard({super.key});

  @override
  State<AiProblemCard> createState() => _AiProblemCardState();
}

class _AiProblemCardState extends State<AiProblemCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },

      onTapUp: (_) async {
        setState(() {
          _isPressed = true;
        });

        await Future.delayed(const Duration(milliseconds: 85));

        if (!context.mounted) return;

        setState(() {
          _isPressed = false;
        });

        AppRouter.goToAiCategory(context);
      },

      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },

      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),

        child: Container(
          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            color: _isPressed
                ? AppColors.categoryTintRosePressed
                : AppColors.categoryTintRose,

            borderRadius: BorderRadius.circular(25),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isPressed ? 0.05 : 0.0),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),

          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),

                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),

              const SizedBox(width: 15),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Describe your problem',

                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onTintPrimary,
                      ),
                    ),

                    SizedBox(height: 2),

                    Text(
                      'Get an AI-assisted suggestion',

                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onTintPrimaryMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
