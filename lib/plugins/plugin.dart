import 'dart:async';
import 'package:hydro/bin/request.dart';
import 'package:hydro/bin/response.dart';

/// Base interface for all plugins
abstract class Plugin {
  /// Plugin configuration
  final Map<String, dynamic> config;

  /// Plugin name
  String get name;

  /// Plugin version
  String get version;

  /// Plugin description
  String get description;

  /// Plugin dependencies
  List<String> get dependencies => [];

  /// Plugin status
  bool get isInitialized => _initialized;
  bool get isStarted => _started;

  bool _initialized = false;
  bool _started = false;

  Plugin(this.config);

  /// Called when the plugin is initialized
  Future<void> initialize() async {
    if (_initialized) return;
    await onInitialize();
    _initialized = true;
  }

  /// Called when the plugin is started
  Future<void> start() async {
    if (!_initialized) {
      throw StateError('Plugin must be initialized before starting');
    }
    if (_started) return;
    await onStart();
    _started = true;
  }

  /// Called when the plugin is stopped
  Future<void> stop() async {
    if (!_started) return;
    await onStop();
    _started = false;
  }

  /// Called before each request
  Future<void> beforeRequest(Request request) async {
    if (!_started) return;
    await onBeforeRequest(request);
  }

  /// Called after each request
  Future<void> afterRequest(Request request, Response response) async {
    if (!_started) return;
    await onAfterRequest(request, response);
  }

  /// Called when an error occurs
  Future<void> onError(Request request, dynamic error) async {
    if (!_started) return;
    await handleError(request, error);
  }

  /// Override these methods in your plugin implementation

  /// Called during initialization
  Future<void> onInitialize() async {}

  /// Called when the plugin starts
  Future<void> onStart() async {}

  /// Called when the plugin stops
  Future<void> onStop() async {}

  /// Called before each request
  Future<void> onBeforeRequest(Request request) async {}

  /// Called after each request
  Future<void> onAfterRequest(Request request, Response response) async {}

  /// Called when an error occurs
  Future<void> handleError(Request request, dynamic error) async {}

  /// Validate plugin configuration
  bool validateConfig() => true;

  /// Get plugin configuration value
  T? getConfig<T>(String key, [T? defaultValue]) {
    return config[key] as T? ?? defaultValue;
  }

  /// Check if plugin has a configuration value
  bool hasConfig(String key) => config.containsKey(key);
}
