import 'dart:async';
import 'package:hydro/bin/request.dart';
import 'package:hydro/bin/response.dart';
import 'package:hydro/plugins/base_plugin.dart';
import 'package:mysql1/mysql1.dart';

/// MySQL Plugin implementation
class MysqlPlugin extends BasePlugin {
  @override
  String get name => 'mysql';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'MySQL database plugin for Hydro';

  // MySQL connection state
  bool _isConnected = false;
  MySqlConnection? _connection;

  MysqlPlugin(Map<String, dynamic> config) : super(config);

  @override
  bool validateConfig() {
    final requiredFields = ['host', 'port', 'database', 'username', 'password'];
    for (final field in requiredFields) {
      if (!hasConfig(field)) {
        logError('Missing required configuration: $field');
        return false;
      }
    }
    return true;
  }

  @override
  Future<void> onInitialize() async {
    logInfo('Initializing MySQL plugin...');
    await super.onInitialize();
  }

  @override
  Future<void> onStart() async {
    logInfo('Starting MySQL plugin...');
    try {
      // Initialize MySQL connection
      _connection = await _createConnection();
      _isConnected = true;
      logSuccess('MySQL connected successfully');
    } catch (e) {
      logError('Failed to connect to MySQL: $e');
      rethrow;
    }
  }

  @override
  Future<void> onStop() async {
    logInfo('Stopping MySQL plugin...');
    if (_isConnected && _connection != null) {
      try {
        await _connection!.close();
        _isConnected = false;
        _connection = null;
        logSuccess('MySQL connection closed');
      } catch (e) {
        logError('Error closing MySQL connection: $e');
      }
    }
  }

  @override
  Future<void> onBeforeRequest(Request request) async {
    if (!_isConnected) {
      throw StateError('MySQL connection not established');
    }
  }

  @override
  Future<void> onAfterRequest(Request request, Response response) async {
    // Clean up any resources if needed
  }

  @override
  Future<void> handleError(Request request, dynamic error) async {
    logError('Error in request ${request.path}: $error');
    // Handle MySQL-specific errors
  }

  /// Create a new MySQL connection
  Future<MySqlConnection> _createConnection() async {
    final settings = ConnectionSettings(
      host: getConfig('host') ?? 'localhost',
      port: getConfig('port') ?? 3306,
      db: getConfig('database') ?? 'hydro',
      user: getConfig('username') ?? 'root',
      password: getConfig('password') ?? '',
    );

    try {
      final connection = await MySqlConnection.connect(settings);
      logSuccess('MySQL connection established');
      return connection;
    } catch (e) {
      logError('Failed to connect to MySQL: $e');
      rethrow;
    }
  }

  /// Execute a query
  Future<List<Map<String, dynamic>>> query(
    String sql, [
    Map<String, dynamic>? params,
  ]) async {
    if (!_isConnected || _connection == null) {
      throw StateError('MySQL connection not established');
    }

    try {
      final results = await _connection!.query(sql, params?.values.toList());
      final rows = await results.toList();

      return rows.map((row) {
        final map = <String, dynamic>{};
        final fields = row.fields;
        final values = row.values;

        for (var i = 0; i < fields.length; i++) {
          final field = fields[i];
          if (field != null && values != null && i < values.length) {
            final value = values[i];
            map[field.name] = value;
          }
        }
        return map;
      }).toList();
    } catch (e) {
      logError('Query error: $e');
      rethrow;
    }
  }

  /// Execute a transaction
  Future<T> transaction<T>(Future<T> Function() callback) async {
    if (!_isConnected || _connection == null) {
      throw StateError('MySQL connection not established');
    }

    try {
      await _connection!.query('START TRANSACTION');
      final result = await callback();
      await _connection!.query('COMMIT');
      return result;
    } catch (e) {
      await _connection!.query('ROLLBACK');
      logError('Transaction error: $e');
      rethrow;
    }
  }

  /// Check if connected to MySQL
  bool get isConnected => _isConnected;

  /// Get the MySQL connection
  MySqlConnection? get connection => _connection;
}
