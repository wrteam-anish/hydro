import 'dart:io';

import 'package:hydro/bin/entry_point.dart';
import 'package:hydro/bin/middleware.dart';
import 'package:hydro/bin/route.dart';
import 'package:hydro/hydro.dart';

void main(List<String> arguments) {
  startServer(ServerConfiguration());
}

class ServerConfiguration extends EntryPoint {
  @override
  Configuration get configuration =>
      Configuration(ip: InternetAddress.loopbackIPv4, port: 4545);
  @override
  List<Route> get routes => [Root()];

  @override
  List<Middleware> get middlewares => [RejectionMiddleware()];
}

class RejectionMiddleware extends Middleware {
  @override
  bool handle(MiddlewareContext context) {
    var x = context.request.get('id');
    if (x == '2') {
      context.reject('Rejected');
      return false;
    }

    return true;
  }
}
