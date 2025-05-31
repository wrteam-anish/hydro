import 'package:hydro/bin/request.dart';
import 'package:hydro/bin/response.dart';
import 'package:hydro/bin/route.dart';
import 'package:hydro/plugins/plugin_manager.dart';
import 'package:hydro/plugins/mysql_plugin.dart';
import 'dart:convert';

class Root extends Route {
  @override
  String get target => '/';

  @override
  Future<Response?> onRoute(Request request) async {
    // Get MySQL plugin instance using singleton
    final mysqlPlugin = PluginManager().getPlugin('mysql') as MysqlPlugin;

    // Check if plugin is connected
    if (!mysqlPlugin.isConnected) {
      return Json(
        jsonEncode({
          'status': 'error',
          'message': 'MySQL connection not established',
        }),
      );
    }

    // Handle different request types
    if (request is Get) {
      // For GET requests, return connection status
      return Json(
        jsonEncode({
          'status': 'success',
          'message': 'MySQL connection is working',
          'connection_status': mysqlPlugin.isConnected,
        }),
      );
    } else if (request is Post) {
      // For POST requests, try to execute a test query
      try {
        // Execute a simple query to check connection
        final result = await mysqlPlugin.query('SELECT 1 as connection_test');

        return Json(
          jsonEncode({
            'status': 'success',
            'message': 'MySQL query executed successfully',
            'data': result,
          }),
        );
      } catch (e) {
        return Json(
          jsonEncode({
            'status': 'error',
            'message': 'Failed to execute MySQL query: $e',
          }),
        );
      }
    }

    // For other request types, return method not allowed
    return Json(
      jsonEncode({'status': 'error', 'message': 'Method not allowed'}),
    );
  }
}
