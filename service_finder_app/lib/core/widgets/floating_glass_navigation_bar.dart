import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_colors.dart';

class FloatingGlassNavigationBar extends StatefulWidget {
  const FloatingGlassNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : assert(items.length > 1),
       assert(currentIndex >= 0 && currentIndex < items.length);

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  @override
  State<FloatingGlassNavigationBar> createState() =>
      _FloatingGlassNavigationBarState();
}

class _FloatingGlassNavigationBarState
    extends State<FloatingGlassNavigationBar> {
  // Fractional tab position keeps the glass directly beneath the finger.
  double? _dragPosition;
  int? _lastDragIndex;

  int get currentIndex => widget.currentIndex;
  List<BottomNavigationBarItem> get items => widget.items;

  void onTap(int index) => widget.onTap(index);

  void _finishDrag() {
    final position = _dragPosition;
    if (position == null) return;
    final index = position.round().clamp(0, items.length - 1);
    setState(() {
      _dragPosition = null;
      _lastDragIndex = null;
    });
    if (index != currentIndex) onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = Duration(milliseconds: reduceMotion ? 0 : 280);

    return SafeArea(
      top: false,
      maintainBottomViewPadding: true,
      minimum: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.viewPaddingOf(context).bottom + 15,
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF35282C), Color(0xFF201E25)]
                : const [Color(0xFFFFF0F0), Color(0xFFF5F1FA)],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: dark ? 0.15 : 0.9),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: dark ? 0.18 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / items.length;
            final labelHeight =
                MediaQuery.textScalerOf(context).scale(11) * 1.3;
            final height = 46 + labelHeight;

            void selectAt(Offset position) {
              if (itemWidth <= 0) return;
              final physicalPosition = (position.dx / itemWidth - 0.5).clamp(
                0.0,
                items.length - 1.0,
              );
              final tabPosition =
                  Directionality.of(context) == TextDirection.rtl
                  ? items.length - 1 - physicalPosition
                  : physicalPosition;
              final index = tabPosition.round();
              final previousIndex = _lastDragIndex ?? currentIndex;
              setState(() {
                _dragPosition = tabPosition;
                _lastDragIndex = index;
              });
              if (index != previousIndex) onTap(index);
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (details) =>
                  selectAt(details.localPosition),
              onHorizontalDragUpdate: (details) =>
                  selectAt(details.localPosition),
              onHorizontalDragEnd: (_) => _finishDrag(),
              onHorizontalDragCancel: _finishDrag,
              child: SizedBox(
                height: height,
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: _dragPosition == null
                          ? duration
                          : Duration.zero,
                      curve: Curves.easeOutCubic,
                      alignment: AlignmentDirectional(
                        -1 +
                            2 *
                                (_dragPosition ?? currentIndex.toDouble()) /
                                (items.length - 1),
                        -1,
                      ),
                      child: SizedBox(
                        width: itemWidth,
                        height: height - 2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(
                                        alpha: dark ? 0.25 : 0.85,
                                      ),
                                      Colors.white.withValues(
                                        alpha: dark ? 0.08 : 0.35,
                                      ),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(
                                      alpha: dark ? 0.4 : 0.95,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(items.length, (index) {
                        final item = items[index];
                        final selected = index == currentIndex;
                        final color = selected
                            ? (dark
                                  ? const Color(0xFFFFB4BC)
                                  : AppColors.primary)
                            : Theme.of(context).colorScheme.onSurfaceVariant;

                        return Expanded(
                          child: Semantics(
                            selected: selected,
                            button: true,
                            label: item.label,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => onTap(index),
                                child: ExcludeSemantics(
                                  child: AnimatedSlide(
                                    duration: duration,
                                    offset: Offset(0, selected ? -0.04 : 0),
                                    child: SizedBox(
                                      height: height,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconTheme(
                                            data: IconThemeData(
                                              color: color,
                                              size: 24,
                                            ),
                                            child: selected
                                                ? item.activeIcon
                                                : item.icon,
                                          ),
                                          const SizedBox(height: 4),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 3,
                                            ),
                                            child: Text(
                                              item.label ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: color,
                                                fontSize: 11,
                                                height: 1.3,
                                                fontWeight: selected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
