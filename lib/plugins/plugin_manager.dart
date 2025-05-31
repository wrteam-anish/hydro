import 'dart:async';
import 'package:hydro/bin/request.dart';
import 'package:hydro/bin/response.dart';
import 'package:hydro/plugins/mysql_plugin.dart';
import 'package:hydro/plugins/plugin.dart';

/// Manages the lifecycle and execution of plugins
class PluginManager {
  static final PluginManager _instance = PluginManager._internal();
  factory PluginManager() => _instance;
  PluginManager._internal();

  final Map<String, Plugin> _plugins = {};
  final Map<String, Map<String, dynamic>> _configs = {};

  /// Register a plugin with its configuration
  void registerPlugin(Plugin plugin, Map<String, dynamic> config) {
    _plugins[plugin.name] = plugin;
    _configs[plugin.name] = config;
  }

  /// Initialize all registered plugins
  Future<void> initializePlugins() async {
    for (final plugin in _plugins.values) {
      try {
        await plugin.initialize();
        print('✅ Plugin ${plugin.name} initialized');
      } catch (e) {
        print('❌ Failed to initialize plugin ${plugin.name}: $e');
      }
    }
  }

  /// Start all registered plugins
  Future<void> startPlugins() async {
    for (final plugin in _plugins.values) {
      try {
        await plugin.start();
        print('✅ Plugin ${plugin.name} started');
      } catch (e) {
        print('❌ Failed to start plugin ${plugin.name}: $e');
      }
    }
  }

  /// Stop all registered plugins
  Future<void> stopPlugins() async {
    for (final plugin in _plugins.values) {
      try {
        await plugin.stop();
        print('✅ Plugin ${plugin.name} stopped');
      } catch (e) {
        print('❌ Failed to stop plugin ${plugin.name}: $e');
      }
    }
  }

  /// Execute beforeRequest hooks for all plugins
  Future<void> beforeRequest(Request request) async {
    for (final plugin in _plugins.values) {
      try {
        await plugin.beforeRequest(request);
      } catch (e) {
        print('❌ Error in beforeRequest for plugin ${plugin.name}: $e');
        await plugin.onError(request, e);
      }
    }
  }

  /// Execute afterRequest hooks for all plugins
  Future<void> afterRequest(Request request, Response response) async {
    for (final plugin in _plugins.values) {
      try {
        await plugin.afterRequest(request, response);
      } catch (e) {
        print('❌ Error in afterRequest for plugin ${plugin.name}: $e');
        await plugin.onError(request, e);
      }
    }
  }

  /// Handle errors through plugins
  Future<void> handleError(
    Request request,
    Response response,
    dynamic error,
  ) async {
    for (final plugin in _plugins.values) {
      try {
        await plugin.onError(request, error);
      } catch (e) {
        print('Error in plugin ${plugin.name} error handler: $e');
      }
    }
  }

  /// Get a plugin by name
  Plugin? getPlugin(String name) => _plugins[name];

  /// Get all registered plugins
  List<Plugin> get plugins => _plugins.values.toList();

  /// Get plugin configuration
  Map<String, dynamic>? getPluginConfig(String name) => _configs[name];
}

/// Example usage:
/// 
/// ```dart
/// final pluginManager = PluginManager();
/// 
/// // Register MySQL plugin
/// pluginManager.registerPlugin(
///   MysqlPlugin({
///     'host': 'localhost',
///     'port': 3306,
///     'database': 'mydb',
///     'username': 'user',
///     'password': 'pass',
///   }),
///   {
///     'host': 'localhost',
///     'port': 3306,
///     'database': 'mydb',
///     'username': 'user',
///     'password': 'pass',
///   },
/// );
/// 
/// // Initialize and start plugins
/// await pluginManager.initializePlugins();
/// await pluginManager.startPlugins();
/// 
/// // Use in request handling
/// await pluginManager.beforeRequest(request);
/// // ... handle request ...
/// await pluginManager.afterRequest(request, response);
/// 
/// // Stop plugins when shutting down
/// await pluginManager.stopPlugins();
/// ``` 