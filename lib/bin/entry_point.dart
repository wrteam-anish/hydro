// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:hydro/bin/middleware.dart';
import 'package:hydro/bin/request.dart';
import 'package:hydro/bin/route.dart';

bool isDevMode = true;

abstract class EntryPoint {
  List<String> args;
  EntryPoint(this.args);
  Configuration get configuration;
  List<Route> routes = [];
  List<Request> requestTypes = [Post(), Get(), Put(), Patch(), Delete()];
  List<Middleware> middlewares = [];
}

class Configuration {
  final InternetAddress ip;
  final int port;
  Configuration({required this.ip, required this.port});
}
