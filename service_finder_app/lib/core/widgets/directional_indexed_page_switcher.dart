import 'package:flutter/material.dart';

class DirectionalIndexedPageSwitcher extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;
  final Curve curve;

  const DirectionalIndexedPageSwitcher({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 320),
    this.curve = Curves.easeOutCubic,
  }) : assert(children.length > 0),
       assert(index >= 0 && index < children.length);

  @override
  State<DirectionalIndexedPageSwitcher> createState() =>
      _DirectionalIndexedPageSwitcherState();
}

class _DirectionalIndexedPageSwitcherState
    extends State<DirectionalIndexedPageSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  int? _previousIndex;
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      value: 1,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
  }

  @override
  void didUpdateWidget(DirectionalIndexedPageSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.curve != widget.curve) {
      _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    }
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.index != widget.index) {
      _previousIndex = oldWidget.index;
      _direction = widget.index > oldWidget.index ? 1 : -1;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      return Stack(
        children: List.generate(widget.children.length, (index) {
          return _positionedPage(
            index,
            Offset.zero,
            visible: index == widget.index,
            interactive: index == widget.index,
          );
        }),
      );
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final progress = _animation.value;
        return Stack(
          children: List.generate(widget.children.length, (index) {
            final selected = index == widget.index;
            final outgoing = index == _previousIndex && progress < 1;

            if (!selected && !outgoing) {
              return _positionedPage(index, Offset.zero, visible: false);
            }

            final offset = selected
                ? Offset(_direction * (1 - progress), 0)
                : Offset(-_direction * progress, 0);

            return _positionedPage(index, offset, interactive: selected);
          }),
        );
      },
    );
  }

  Widget _positionedPage(
    int index,
    Offset offset, {
    bool visible = true,
    bool interactive = true,
  }) {
    return Positioned.fill(
      child: Offstage(
        offstage: !visible,
        child: IgnorePointer(
          ignoring: !interactive,
          child: TickerMode(
            enabled: index == widget.index,
            child: FractionalTranslation(
              translation: offset,
              child: widget.children[index],
            ),
          ),
        ),
      ),
    );
  }
}
