import 'package:hydro/bin/globals.dart';
import 'package:mysql1/mysql1.dart';

final settings = ConnectionSettings(
  host: '193.', // e.g. db1234.hostingprovider.com
  user: '',
  password: '',
  db: '',
  useCompression: true,
  useSSL: true,
);
void main() async {
  // Replace these with your actual online MySQL server credentials:

  try {
    final conn = await MySqlConnection.connect(settings);
    print('>>>is connected ${conn}');
    // Example query: get current date/time from server
    await Future.delayed(Duration(microseconds: 40));
    await conn.close();
  } catch (e) {
    print('Failed to connect or query: $e');
  }
}
