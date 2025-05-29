import 'dart:async';

import 'package:hydro/bin/request.dart';

abstract class Middleware {
  bool _success = false;
  Middleware? _next;
  void next() {
    _success = true;
    if (_next == null) return;
  }

  void reject() {
    _success = false;
  }

  void _nextMiddleware(Middleware? handler, Request request) {
    _next = handler;
    handler?.handle(request);
  }

  bool get didPassed => _success;

  FutureOr<void> handle(Request request);
}

Future<bool> runMiddlewares(
  List<Middleware> middlewares,
  Request request,
) async {
  for (int i = 0; i < middlewares.length; i++) {
    Middleware middleware = middlewares[i];
    Middleware? nextMiddleWare =
        middlewares.length > i + 1 ? middlewares[i + 1] : null;

    middleware._nextMiddleware(nextMiddleWare, request);
    await middleware.handle(request);

    if (!middleware.didPassed) return false;
  }
  return true;
}
