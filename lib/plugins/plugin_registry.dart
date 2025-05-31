import 'dart:async';
import 'dart:io';
import 'dart:mirrors';
import 'package:hydro/plugins/plugin.dart';
import 'package:hydro/plugins/plugin_manager.dart';
import 'package:hydro/plugins/mysql_plugin.dart';

/// Registry for managing plugin discovery and loading
class PluginRegistry {
  final PluginManager _pluginManager;
  final Map<String, Map<String, dynamic>> _pluginConfigs = {};
  final Map<String, Type> _pluginTypes = {};

  PluginRegistry(this._pluginManager) {
    _discoverPlugins();
  }

  /// Discover available plugins
  void _discoverPlugins() {
    // Register built-in plugins
    _registerPluginType('mysql', MysqlPlugin);

    // You can add more built-in plugins here
    // _registerPluginType('redis', RedisPlugin);
    // _registerPluginType('auth', AuthPlugin);
  }

  /// Register a plugin type
  void _registerPluginType(String name, Type pluginType) {
    _pluginTypes[name] = pluginType;
  }

  /// Register a plugin configuration
  void registerPluginConfig(String name, Map<String, dynamic> config) {
    if (!_pluginTypes.containsKey(name)) {
      throw ArgumentError('Unknown plugin type: $name');
    }
    _pluginConfigs[name] = config;
  }

  /// Load all registered plugins
  Future<void> loadPlugins() async {
    for (final entry in _pluginConfigs.entries) {
      final name = entry.key;
      final config = entry.value;

      try {
        final plugin = await _createPlugin(name, config);
        if (plugin != null) {
          _pluginManager.registerPlugin(plugin, config);
          print('✅ Plugin $name registered successfully');
        }
      } catch (e) {
        print('❌ Failed to load plugin $name: $e');
      }
    }
  }

  /// Create a plugin instance
  Future<Plugin?> _createPlugin(
    String name,
    Map<String, dynamic> config,
  ) async {
    final pluginType = _pluginTypes[name];
    if (pluginType == null) {
      print('❌ Unknown plugin type: $name');
      return null;
    }

    try {
      // Create plugin instance using reflection
      final instance =
          reflectClass(pluginType).newInstance(Symbol(''), [config]).reflectee
              as Plugin;
      return instance;
    } catch (e) {
      print('❌ Failed to create plugin instance: $e');
      return null;
    }
  }

  /// Get all registered plugin configurations
  Map<String, Map<String, dynamic>> get pluginConfigs =>
      Map.unmodifiable(_pluginConfigs);

  /// Check if a plugin is registered
  bool isPluginRegistered(String name) => _pluginConfigs.containsKey(name);

  /// Get plugin configuration
  Map<String, dynamic>? getPluginConfig(String name) => _pluginConfigs[name];

  /// Get available plugin types
  List<String> get availablePluginTypes => _pluginTypes.keys.toList();
}

/// Example usage:
/// 
/// ```dart
/// final pluginManager = PluginManager();
/// final registry = PluginRegistry(pluginManager);
/// 
/// // Register plugin configurations
/// registry.registerPluginConfig('mysql', {
///   'host': 'localhost',
///   'port': 3306,
///   'database': 'mydb',
///   'username': 'user',
///   'password': 'pass',
/// });
/// 
/// // Load all plugins
/// await registry.loadPlugins();
/// 
/// // Initialize and start plugins
/// await pluginManager.initializePlugins();
/// await pluginManager.startPlugins();
/// ``` 