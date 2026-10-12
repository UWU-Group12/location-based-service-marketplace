import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_router.dart';

class AiProblemCard extends StatefulWidget {
  final VoidCallback? onPressed;
  final double? height;
  const AiProblemCard({super.key, this.onPressed, this.height});

  @override
  State<AiProblemCard> createState() => _AiProblemCardState();
}

class _AiProblemCardState extends State<AiProblemCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _colors;
  ScrollableState? _scrollable;
  ScrollPosition? _position;
  bool _isPressed = false;
  bool _reduceMotion = false;
  bool _tickersEnabled = true;
  bool _inViewport = true;
  bool _visibilityCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    _colors = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _tickersEnabled = TickerMode.valuesOf(context).enabled;
    _scrollable = Scrollable.maybeOf(context);
    final position = _scrollable?.position;
    if (position != _position) {
      _position?.removeListener(_scheduleVisibilityCheck);
      _position = position;
      _position?.addListener(_scheduleVisibilityCheck);
    }
    _syncAnimation();
    _scheduleVisibilityCheck();
  }

  void _scheduleVisibilityCheck() {
    if (_visibilityCheckScheduled) return;
    _visibilityCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityCheckScheduled = false;
      _updateVisibility();
    });
  }

  void _updateVisibility() {
    if (!mounted) return;
    final button = context.findRenderObject();
    final viewport = _scrollable?.context.findRenderObject();
    if (button is RenderBox &&
        button.hasSize &&
        viewport is RenderBox &&
        viewport.hasSize) {
      final origin = button.localToGlobal(Offset.zero, ancestor: viewport);
      _inViewport =
          origin.dy + button.size.height > 0 &&
          origin.dy < viewport.size.height;
    }
    _syncAnimation();
  }

  void _syncAnimation() {
    if (!_reduceMotion && _tickersEnabled && _inViewport) {
      if (!_colors.isAnimating) _colors.repeat();
    } else {
      _colors.stop();
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_scheduleVisibilityCheck);
    _colors.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textSize = MediaQuery.textScalerOf(context).scale(14);
    final onTap = widget.onPressed ?? () => AppRouter.goToAiCategory(context);
    return SizedBox(
      width: math.max(64, 40 + textSize * 1.15),
      height: widget.height ?? math.max(56, textSize * 1.3 + 24),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1,
        duration: _reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 120),
        child: CustomPaint(
          painter: _AiGlowPainter(_colors),
          child: Semantics(
            button: true,
            label: 'Describe your problem',
            excludeSemantics: true,
            onTap: onTap,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                splashColor: Colors.white.withValues(alpha: 0.3),
                highlightColor: Colors.white.withValues(alpha: 0.12),
                onHighlightChanged: (pressed) =>
                    setState(() => _isPressed = pressed),
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: Color(0xFF29233F),
                          ),
                          const SizedBox(width: 5),
                          const Flexible(
                            child: Text(
                              'AI',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF29233F),
                                height: 1.3,
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
        ),
      ),
    );
  }
}

/// Animate the background without rebuilding the label or changing layout.
class _AiGlowPainter extends CustomPainter {
  final Animation<double> animation;
  _AiGlowPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final pill = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.height / 2),
    );
    final phase = animation.value * 2 * math.pi;
    canvas.save();
    canvas.clipRRect(pill);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFE7DDFF), Color(0xFFCDE7FF), Color(0xFFC4F2E3)],
          stops: [0, 0.5, 1],
        ).createShader(rect),
    );
    _glow(
      canvas,
      Offset(size.width * (0.13 + 0.06 * math.sin(phase)), size.height * 0.25),
      size.width * 0.44,
      const Color(0xFFC9B5FA),
      0.55,
    );
    _glow(
      canvas,
      Offset(size.width * (0.50 + 0.09 * math.sin(phase)), size.height * 1.05),
      size.width * 0.39,
      const Color(0xFFB6D9FA),
      0.55,
    );
    _glow(
      canvas,
      Offset(size.width * (0.93 - 0.06 * math.cos(phase)), size.height * 0.4),
      size.width * 0.36,
      const Color(0xFFA8E3C9),
      0.65,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.24),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
    canvas.restore();
    canvas.drawRRect(
      pill.deflate(0.75),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _glow(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double opacity,
  ) {
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(_AiGlowPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
