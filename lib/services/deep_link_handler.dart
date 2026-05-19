import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Tipo de deep link recebido.
enum DeepLinkType { reset, login, unknown }

class DeepLinkEvent {
  final DeepLinkType type;
  final Uri uri;
  DeepLinkEvent(this.type, this.uri);
}

/// Escuta deep links `bjbank://reset` e `bjbank://login` e expoe-os como stream.
///
/// Para password reset: o link do Supabase tras `#access_token=...&type=recovery`.
/// O Supabase SDK processa automaticamente o token via deep link e estabelece
/// sessao temporaria que permite [updatePassword]. O handler so precisa de
/// fazer routing — navega para o ecra de definir nova password.
class DeepLinkHandler {
  static final DeepLinkHandler instance = DeepLinkHandler._();
  DeepLinkHandler._();

  final AppLinks _appLinks = AppLinks();
  final StreamController<DeepLinkEvent> _controller =
      StreamController<DeepLinkEvent>.broadcast();
  StreamSubscription<Uri>? _sub;

  Stream<DeepLinkEvent> get stream => _controller.stream;

  Future<void> initialize() async {
    // Cold start link.
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _process(initial);
    } catch (e) {
      debugPrint('DeepLink getInitialLink erro: $e');
    }
    // Warm links.
    _sub = _appLinks.uriLinkStream.listen(_process, onError: (e) {
      debugPrint('DeepLink stream erro: $e');
    });
  }

  void _process(Uri uri) {
    debugPrint('DeepLink recebido: $uri');
    if (uri.scheme != 'bjbank') {
      _controller.add(DeepLinkEvent(DeepLinkType.unknown, uri));
      return;
    }
    switch (uri.host) {
      case 'reset':
        _controller.add(DeepLinkEvent(DeepLinkType.reset, uri));
        break;
      case 'login':
        _controller.add(DeepLinkEvent(DeepLinkType.login, uri));
        break;
      default:
        _controller.add(DeepLinkEvent(DeepLinkType.unknown, uri));
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }
}
