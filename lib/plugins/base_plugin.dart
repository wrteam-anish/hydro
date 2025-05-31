import 'dart:async';
import 'package:hydro/plugins/plugin.dart';
import 'package:hydro/bin/request.dart';
import 'package:hydro/bin/response.dart';

/// Base class for all plugins with common functionality
abstract class BasePlugin extends Plugin {
  BasePlugin(Map<String, dynamic> config) : super(config);

  /// Plugin metadata
  @override
  String get name;
  @override
  String get version;
  @override
  String get description;
  @override
  List<String> get dependencies => [];

  /// Plugin lifecycle methods
  @override
  Future<void> onInitialize() async {
    // Validate configuration
    if (!validateConfig()) {
      throw ArgumentError('Invalid plugin configuration');
    }
  }

  @override
  Future<void> onStart() async {}

  @override
  Future<void> onStop() async {}

  /// Request handling methods
  @override
  Future<void> onBeforeRequest(Request request) async {}

  @override
  Future<void> onAfterRequest(Request request, Response response) async {}

  @override
  Future<void> handleError(Request request, dynamic error) async {
    print('Error in plugin $name: $error');
  }

  /// Configuration validation
  @override
  bool validateConfig() => true;

  /// Helper methods for configuration
  T? getConfig<T>(String key, [T? defaultValue]) {
    return config[key] as T? ?? defaultValue;
  }

  bool hasConfig(String key) => config.containsKey(key);

  /// Helper methods for logging
  void logInfo(String message) {
    print('ℹ️ [$name] $message');
  }

  void logError(String message) {
    print('❌ [$name] $message');
  }

  void logSuccess(String message) {
    print('✅ [$name] $message');
  }
}

/// Example plugin implementation:
/// 
/// ```dart
/// class MyPlugin extends BasePlugin {
///   @override
///   String get name => 'my_plugin';
/// 
///   @override
///   String get version => '1.0.0';
/// 
///   @override
///   String get description => 'My custom plugin';
/// 
///   MyPlugin(Map<String, dynamic> config) : super(config);
/// 
///   @override
///   bool validateConfig() {
///     return hasConfig('required_field');
///   }
/// 
///   @override
///   Future<void> onStart() async {
///     logInfo('Starting plugin...');
///     // Your startup code here
///     logSuccess('Plugin started successfully');
///   }
/// }
/// ``` 