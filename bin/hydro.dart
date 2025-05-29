import 'dart:io';
import 'dart:math';

import 'package:hydro/bin/entry_point.dart';
import 'package:hydro/bin/middleware.dart';
import 'package:hydro/bin/request.dart';
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
  List<Middleware> get middlewares => [RejectionMiddleware(), AlwaysReject()];
}

class RejectionMiddleware extends Middleware {
  @override
  void handle(Request req) {
    next();
  }
}

class AlwaysReject extends Middleware {
  @override
  void handle(Request req) {
    next();
  }
}
