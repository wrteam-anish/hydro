import 'dart:async';
import 'dart:io';

import 'package:hydro/bin/entry_point.dart';
import 'package:hydro/bin/middleware.dart';
import 'package:hydro/bin/request.dart';
import 'package:hydro/bin/route.dart';
import 'package:hydro/hydro_server.dart';
import 'package:hydro/routes/root.dart';

void main(List<String> arguments) {
  startServer(ServerConfiguration(arguments));
}

class ServerConfiguration extends EntryPoint {
  ServerConfiguration(super.args);
  @override
  Configuration get configuration =>
      Configuration(ip: InternetAddress.loopbackIPv4, port: 4545);
  @override
  List<Route> get routes => [Root()];

  @override
  List<Middleware> get middlewares => [DemoMiddleware()];
}

class DemoMiddleware extends Middleware {
  @override
  FutureOr<void> handle(Request request) {
    //
    next();
  }
}
