import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/provider_model.dart';
import 'featured_provider_card.dart';

class FeaturedProviderCarousel extends StatefulWidget {
  final List<ProviderModel> providers;
  final ValueChanged<ProviderModel> onViewDetails;
  final Duration interval;

  const FeaturedProviderCarousel({
    super.key,
    required this.providers,
    required this.onViewDetails,
    this.interval = const Duration(seconds: 4),
  });

  @override
  State<FeaturedProviderCarousel> createState() =>
      _FeaturedProviderCarouselState();
}

class _FeaturedProviderCarouselState extends State<FeaturedProviderCarousel> {
  static const double _cardRadius = 24;
  static const double _shadowRoom = 44;

  final math.Random _random = math.Random();

  late PageController _pageController;
  List<ProviderModel> _orderedProviders = [];
  List<String> _sourceIds = [];
  Timer? _timer;
  ScrollableState? _scrollable;
  ScrollPosition? _position;
  var _index = 0;
  var _tickersEnabled = true;
  var _inViewport = true;
  var _reduceMotion = false;
  var _visibilityCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _syncProviders(resetPage: false);
  }

  @override
  void didUpdateWidget(FeaturedProviderCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncProviders();
    if (oldWidget.interval != widget.interval) {
      _timer?.cancel();
      _timer = null;
      _updateTimer();
    }
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
    _scheduleVisibilityCheck();
    _updateTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _position?.removeListener(_scheduleVisibilityCheck);
    _pageController.dispose();
    super.dispose();
  }

  void _syncProviders({bool resetPage = true}) {
    final nextIds = widget.providers
        .map((provider) => provider.providerId)
        .toList(growable: false);
    if (!listEquals(nextIds, _sourceIds)) {
      _sourceIds = nextIds;
      _orderedProviders = List<ProviderModel>.of(widget.providers)
        ..shuffle(_random);
      _index = 0;
      if (resetPage) _resetPageController();
      _updateTimer();
      return;
    }

    if (_orderedProviders.isEmpty) return;
    final providersById = {
      for (final provider in widget.providers) provider.providerId: provider,
    };
    _orderedProviders = [
      for (final provider in _orderedProviders)
        providersById[provider.providerId] ?? provider,
    ];
  }

  void _resetPageController() {
    final oldController = _pageController;
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldController.dispose();
    });
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
    final carousel = context.findRenderObject();
    final viewport = _scrollable?.context.findRenderObject();
    if (carousel is RenderBox &&
        carousel.hasSize &&
        viewport is RenderBox &&
        viewport.hasSize) {
      final origin = carousel.localToGlobal(Offset.zero, ancestor: viewport);
      _inViewport =
          origin.dy + carousel.size.height > 0 &&
          origin.dy < viewport.size.height;
    }
    _updateTimer();
  }

  void _updateTimer() {
    final shouldRun =
        _orderedProviders.length > 1 && _tickersEnabled && _inViewport;
    if (!shouldRun) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(widget.interval, (_) => _advance());
  }

  void _advance() {
    if (!mounted ||
        _orderedProviders.length <= 1 ||
        !_tickersEnabled ||
        !_inViewport ||
        !_pageController.hasClients) {
      return;
    }

    _index = (_index + 1) % _orderedProviders.length;
    if (_reduceMotion) {
      _pageController.jumpToPage(_index);
      return;
    }

    _pageController.animateToPage(
      _index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  double _height(BuildContext context, double width) {
    if (_orderedProviders.isEmpty) return 0;
    final tallestCard = _orderedProviders
        .map(
          (provider) => FeaturedProviderCard.preferredHeight(
            context,
            width: width,
            provider: provider,
          ),
        )
        .reduce(math.max);
    return tallestCard + _shadowRoom;
  }

  BoxDecoration _frameDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_cardRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 28,
          spreadRadius: 2,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_orderedProviders.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = _height(context, constraints.maxWidth) - _shadowRoom;
        return SizedBox(
          height: _height(context, constraints.maxWidth),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              key: const ValueKey('featured-provider-frame'),
              height: cardHeight,
              decoration: _frameDecoration(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_cardRadius),
                child: PageView.builder(
                  key: ValueKey(_sourceIds.join('|')),
                  controller: _pageController,
                  itemCount: _orderedProviders.length,
                  onPageChanged: (index) {
                    _index = index;
                  },
                  itemBuilder: (context, index) {
                    final provider = _orderedProviders[index];
                    return FeaturedProviderCard(
                      provider: provider,
                      onViewDetails: () => widget.onViewDetails(provider),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
