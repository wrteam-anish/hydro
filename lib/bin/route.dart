// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:async';

import 'package:hydro/bin/request.dart';
import 'package:hydro/bin/response.dart';

abstract class Route {
  String get target;

  FutureOr<Response?> onRoute(Request request);
}
