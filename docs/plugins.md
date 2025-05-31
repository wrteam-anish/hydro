# Hydro Plugin System Guide

This guide explains how to create, register, and use plugins in the Hydro framework.

## Table of Contents
1. [Creating a Plugin](#creating-a-plugin)
2. [Registering a Plugin](#registering-a-plugin)
3. [Using Plugins](#using-plugins)
4. [Plugin Lifecycle](#plugin-lifecycle)
5. [Best Practices](#best-practices)

## Creating a Plugin

### 1. Create Plugin Class
Create a new file in `lib/plugins/` directory, e.g., `lib/plugins/my_plugin.dart`:

```dart
import 'package:hydro/plugins/base_plugin.dart';
import 'package:hydro/bin/request.dart';
import 'package:hydro/bin/response.dart';

class MyPlugin extends BasePlugin {
  @override
  String get name => 'my_plugin';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'My custom plugin';

  MyPlugin(Map<String, dynamic> config) : super(config);

  @override
  bool validateConfig() {
    // Validate required configuration
    return hasConfig('required_field');
  }

  @override
  Future<void> onStart() async {
    logInfo('Starting plugin...');
    // Your startup code here
    logSuccess('Plugin started successfully');
  }

  // Add your plugin-specific methods
  Future<String> doSomething() async {
    return 'Plugin is working!';
  }
}
```

## Registering a Plugin

### 1. Add Plugin to Registry
Add your plugin to the plugin registry in `lib/plugins/plugin_registry.dart`:

```dart
import 'package:hydro/plugins/my_plugin.dart';

class PluginRegistry {
  // ... existing code ...

  void _discoverPlugins() {
    // Register built-in plugins
    _registerPluginType('mysql', MysqlPlugin);
    
    // Register your plugin
    _registerPluginType('my_plugin', MyPlugin);
  }
}
```

### 2. Configure Plugin
In your server code (e.g., `lib/hydro.dart`), register the plugin configuration:

```dart
void _registerDefaultPlugins() {
  // Register your plugin configuration
  _pluginRegistry.registerPluginConfig('my_plugin', {
    'required_field': 'value',
    // Add other configuration as needed
  });
}
```

## Using Plugins

### 1. In Routes
Access plugins in your route handlers:

```dart
import 'package:hydro/plugins/plugin_manager.dart';

class MyRoute extends Route {
  final PluginManager _pluginManager;

  MyRoute(this._pluginManager);

  @override
  Future<Response> handle(Request request) async {
    // Get your plugin
    final myPlugin = _pluginManager.getPlugin('my_plugin') as MyPlugin;
    
    // Use plugin methods
    final result = await myPlugin.doSomething();
    
    return Response.json({'message': result});
  }
}
```

### 2. In Middleware
Use plugins in middleware:

```dart
import 'package:hydro/plugins/plugin_manager.dart';

class MyMiddleware extends Middleware {
  final PluginManager _pluginManager;

  MyMiddleware(this._pluginManager);

  @override
  Future<bool> handle(Request request) async {
    final myPlugin = _pluginManager.getPlugin('my_plugin') as MyPlugin;
    // Use plugin in middleware
    return true;
  }
}
```

### 3. In Other Classes
Inject and use plugins in any class:

```dart
class MyService {
  final PluginManager _pluginManager;

  MyService(this._pluginManager);

  Future<void> doSomething() async {
    final myPlugin = _pluginManager.getPlugin('my_plugin') as MyPlugin;
    // Use plugin methods
  }
}
```

## Plugin Lifecycle

Plugins go through the following lifecycle:

1. **Registration**: Plugin type is registered in the registry
2. **Configuration**: Plugin configuration is registered
3. **Loading**: Plugin instance is created
4. **Initialization**: `onInitialize()` is called
5. **Starting**: `onStart()` is called
6. **Running**: Plugin is active and handling requests
7. **Stopping**: `onStop()` is called during shutdown

### Request Lifecycle
For each request:
1. `beforeRequest()` is called
2. Request is processed
3. `afterRequest()` is called
4. If an error occurs, `handleError()` is called

## Best Practices

### 1. Configuration
- Use environment variables for sensitive data
- Provide default values for optional configuration
- Validate required configuration in `validateConfig()`

```dart
@override
bool validateConfig() {
  final requiredFields = ['api_key', 'endpoint'];
  for (final field in requiredFields) {
    if (!hasConfig(field)) {
      logError('Missing required configuration: $field');
      return false;
    }
  }
  return true;
}
```

### 2. Error Handling
- Use the built-in logging methods
- Handle errors gracefully
- Provide meaningful error messages

```dart
@override
Future<void> handleError(Request request, dynamic error) async {
  logError('Error in request ${request.path}: $error');
  // Handle plugin-specific errors
}
```

### 3. Resource Management
- Clean up resources in `onStop()`
- Handle connection states properly
- Use try-catch blocks for external operations

```dart
@override
Future<void> onStop() async {
  logInfo('Stopping plugin...');
  try {
    // Clean up resources
    await _cleanup();
    logSuccess('Plugin stopped successfully');
  } catch (e) {
    logError('Error stopping plugin: $e');
  }
}
```

### 4. Testing
- Create mock plugins for testing
- Test plugin lifecycle methods
- Test error handling

```dart
class MockMyPlugin extends BasePlugin {
  MockMyPlugin(Map<String, dynamic> config) : super(config);
  
  @override
  String get name => 'mock_my_plugin';
  
  // Implement mock behavior
}
```

## Example: Complete Plugin Implementation

Here's a complete example of a plugin that integrates with an external API:

```dart
import 'package:hydro/plugins/base_plugin.dart';
import 'package:hydro/bin/request.dart';
import 'package:hydro/bin/response.dart';
import 'package:http/http.dart' as http;

class ApiPlugin extends BasePlugin {
  late final String _apiKey;
  late final String _endpoint;
  final _client = http.Client();

  @override
  String get name => 'api';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'External API integration plugin';

  ApiPlugin(Map<String, dynamic> config) : super(config);

  @override
  bool validateConfig() {
    return hasConfig('api_key') && hasConfig('endpoint');
  }

  @override
  Future<void> onInitialize() async {
    await super.onInitialize();
    _apiKey = getConfig('api_key')!;
    _endpoint = getConfig('endpoint')!;
  }

  @override
  Future<void> onStart() async {
    logInfo('Starting API plugin...');
    // Test connection
    try {
      await _testConnection();
      logSuccess('API plugin started successfully');
    } catch (e) {
      logError('Failed to start API plugin: $e');
      rethrow;
    }
  }

  @override
  Future<void> onStop() async {
    logInfo('Stopping API plugin...');
    _client.close();
    logSuccess('API plugin stopped');
  }

  Future<void> _testConnection() async {
    final response = await _client.get(
      Uri.parse('$_endpoint/health'),
      headers: {'Authorization': 'Bearer $_apiKey'},
    );
    if (response.statusCode != 200) {
      throw Exception('API health check failed');
    }
  }

  Future<Map<String, dynamic>> fetchData(String path) async {
    try {
      final response = await _client.get(
        Uri.parse('$_endpoint/$path'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );
      return response.statusCode == 200
          ? response.body as Map<String, dynamic>
          : throw Exception('API request failed');
    } catch (e) {
      logError('API request failed: $e');
      rethrow;
    }
  }
}
```

## Conclusion

The Hydro plugin system provides a flexible and powerful way to extend your application's functionality. By following these guidelines, you can create robust, maintainable plugins that integrate seamlessly with your application.

Remember to:
- Follow the plugin lifecycle
- Handle errors gracefully
- Clean up resources properly
- Use the built-in logging system
- Test your plugins thoroughly

For more information, refer to the [API documentation](docs/api.md) and [examples](examples/). 