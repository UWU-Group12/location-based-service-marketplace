import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'ai_problem_card.dart';

class CustomerSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onAiPressed;

  const CustomerSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onAiPressed,
  });

  @override
  State<CustomerSearchBar> createState() => _CustomerSearchBarState();
}

class _CustomerSearchBarState extends State<CustomerSearchBar> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = math.max(
      56.0,
      MediaQuery.textScalerOf(context).scale(16) * 1.25 + 32,
    );
    return Row(
      children: [
        Expanded(
          child: ListenableBuilder(
            listenable: _focusNode,
            builder: (context, _) {
              final theme = Theme.of(context).inputDecorationTheme;
              final border = _focusNode.hasFocus
                  ? theme.focusedBorder
                  : theme.enabledBorder;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _focusNode.requestFocus,
                child: Container(
                  key: const ValueKey('customer_search_surface'),
                  height: height,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.fillColor ?? AppColors.background,
                    borderRadius: BorderRadius.circular(height / 2),
                    border: Border.all(
                      color:
                          border?.borderSide.color ??
                          (_focusNode.hasFocus
                              ? AppColors.focusedBorder
                              : AppColors.border),
                      width: border?.borderSide.width ?? 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          focusNode: _focusNode,
                          controller: widget.controller,
                          onChanged: widget.onChanged,
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(fontSize: 16, height: 1.25),
                          decoration: const InputDecoration(
                            hintText: 'Search services',
                            hintStyle: TextStyle(
                              fontSize: 16,
                              height: 1.25,
                              color: AppColors.hint,
                            ),
                            isCollapsed: true,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        AiProblemCard(height: height, onPressed: widget.onAiPressed),
      ],
    );
  }
}
