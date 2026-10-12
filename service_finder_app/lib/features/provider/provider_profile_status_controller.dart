import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/provider_model.dart';

/// Owned by the profile screen, never by a lazily built status row.
class ProviderProfileStatusController extends ChangeNotifier {
  final Stream<ProviderModel?>? _stream;
  StreamSubscription<ProviderModel?>? _subscription;
  ProviderModel? _profile;
  bool _receivedLiveValue = false;
  bool _hasError = false;
  bool _disposed = false;

  ProviderProfileStatusController(Stream<ProviderModel?>? stream)
    : _stream = stream {
    _listen();
  }

  ProviderModel? get profile => _profile;
  bool get hasError => _hasError;

  void seed(ProviderModel? profile) {
    // A snapshot received during the initial fetch is newer than its result.
    if (_disposed || _receivedLiveValue) return;
    _profile = profile;
    notifyListeners();
  }

  void _listen() {
    _subscription = _stream?.listen(
      (profile) {
        if (_disposed) return;
        _receivedLiveValue = true;
        _profile = profile;
        _hasError = false;
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        if (_disposed) return;
        _hasError = true;
        // Keep the last known status visible while refresh is unavailable.
        notifyListeners();
      },
      onDone: () {
        if (_disposed) return;
        _hasError = true;
        notifyListeners();
      },
    );
  }

  Future<void> retry() async {
    if (_disposed) return;
    await _subscription?.cancel();
    if (_disposed) return;
    _hasError = false;
    notifyListeners();
    _listen();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
