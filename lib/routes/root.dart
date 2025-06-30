import 'package:hydro/bin/htc_node.dart';
import 'package:hydro/bin/request.dart';
import 'package:hydro/bin/response.dart';
import 'package:hydro/bin/route.dart';

import 'dart:convert';

class Root extends Route {
  @override
  String get target => '/';

  @override
  Future<Response?> onRoute(Request request) async {
    // Get MySQL plugin instance using singleton

    // Check if plugin is connected
    return StringResponse('');
  }
}
