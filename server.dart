import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:async/async.dart';

const watchedDirectories = ['lib', 'bin'];
const portInUse = 4545;
const wsPort = 4040;

Process? process;
Process? newProcess;
Timer? debounceTimer;
final lastFileStates = <String, Map<String, dynamic>>{};
final connectedClients = <WebSocket>{};

Future<void> start() async {
  print('🚀 Starting main server...');
  await killPort(portInUse);
  await killPort(wsPort);

  try {
    process = await Process.start('dart', ['run', 'bin/hydro.dart']);

    process!.stdout.transform(utf8.decoder).listen((data) {
      stdout.write(data);
      if (data.contains('Server started')) {
        print('✅ Main server is ready');
      }
    });

    process!.stderr.transform(utf8.decoder).listen((data) {
      stderr.write(data);
      if (data.contains('Error')) {
        print('❌ Server error detected');
        restartServer();
      }
    });

    process!.exitCode.then((code) {
      print('❌ Server exited with code $code');
      if (code != 0) {
        restartServer();
      }
    });
  } catch (e) {
    print('❌ Failed to start server: $e');
    await Future.delayed(Duration(seconds: 1));
    restartServer();
  }
}

Future<void> stop() async {
  if (process != null) {
    print('🛑 Stopping old server...');
    try {
      process!.kill(ProcessSignal.sigterm);
      await process!.exitCode.timeout(
        Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Force killing server...');
          process!.kill(ProcessSignal.sigkill);
          return 0;
        },
      );
    } catch (e) {
      print('⚠️ Error stopping server: $e');
    }
    await Future.delayed(Duration(milliseconds: 500));
    print('✅ Server stopped.');
    process = null;
  }
}

Future<void> restartServer() async {
  print('🚀 Starting new server instance...');

  try {
    newProcess = await Process.start('dart', ['run', 'bin/hydro.dart']);

    newProcess!.stdout.transform(utf8.decoder).listen((data) {
      stdout.write(data);
      if (data.contains('Server started')) {
        print('✅ New server is ready');
        _handoverToNewServer();
      }
    });

    newProcess!.stderr.transform(utf8.decoder).listen((data) {
      stderr.write(data);
      if (data.contains('Error')) {
        print('❌ New server error detected');
        stop();
      }
    });
  } catch (e) {
    print('❌ Failed to start new server: $e');
    await Future.delayed(Duration(seconds: 1));
    stop();
  }
}

Future<void> _handoverToNewServer() async {
  if (process != null) {
    print('🛑 Stopping old server...');
    process!.kill(ProcessSignal.sigterm);
    await process!.exitCode;
    print('✅ Old server stopped.');
  }

  process = newProcess;
  newProcess = null;
  notifyClientsToReload();
}

Future<void> killPort(int port) async {
  try {
    final result = await Process.run('lsof', ['-i', ':$port']);
    final output = result.stdout.toString();

    if (output.contains('LISTEN')) {
      final lines = output.split('\n');
      for (final line in lines.skip(1)) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          final pid = int.tryParse(parts[1]);
          if (pid != null) {
            print('⚠️ Killing process $pid using port $port');
            await Process.run('kill', ['-9', '$pid']);
          }
        }
      }
    }
  } catch (e) {
    print('⚠️ Error killing port $port: $e');
  }
}

bool isValidChange(FileSystemEvent event) {
  final path = event.path;
  final file = File(path);

  // Skip temp or hidden files
  if (!file.existsSync() ||
      path.endsWith('.DS_Store') ||
      path.startsWith('.') ||
      path.contains('~') ||
      path.endsWith('.tmp')) {
    return false;
  }

  final stat = file.statSync();
  final lastState = lastFileStates[path];

  // Compare size and last modified time
  final changed =
      lastState == null ||
      stat.modified.isAfter(lastState['modified']) ||
      stat.size != lastState['size'];

  if (changed) {
    lastFileStates[path] = {'modified': stat.modified, 'size': stat.size};
    return true;
  }

  return false;
}

Future<void> startWebSocketServer() async {
  try {
    final server = await HttpServer.bind('localhost', wsPort);
    print('WebSocket server running on ws://localhost:$wsPort');

    await for (HttpRequest request in server) {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        connectedClients.add(socket);
        print(
          'New WebSocket client connected (${connectedClients.length} total)',
        );

        socket.listen(
          (data) {
            // Handle incoming messages if needed
          },
          onDone: () {
            connectedClients.remove(socket);
            print(
              'WebSocket client disconnected (${connectedClients.length} remaining)',
            );
          },
          onError: (error) {
            print('WebSocket error: $error');
            connectedClients.remove(socket);
          },
        );
      } else {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..close();
      }
    }
  } catch (e) {
    print('❌ Failed to start WebSocket server: $e');
    await Future.delayed(Duration(seconds: 1));
    startWebSocketServer();
  }
}

void notifyClientsToReload() {
  if (connectedClients.isNotEmpty) {
    print('🔔 Notifying ${connectedClients.length} clients to reload');
    for (final client in connectedClients.toList()) {
      try {
        client.add('reload');
      } catch (e) {
        print('Error notifying client: $e');
        connectedClients.remove(client);
      }
    }
  }
}

Future<void> main() async {
  print('🚀 Starting development server...');

  // Start WebSocket server first
  await startWebSocketServer();

  // Then start main server
  await start();

  // Set up file watchers
  final watchers =
      watchedDirectories
          .map((dir) => Directory(dir).watch(recursive: true))
          .toList();

  final mergedStream = StreamGroup.merge(watchers);

  mergedStream.listen((event) {
    if (event is FileSystemModifyEvent && isValidChange(event)) {
      print('📁 File changed: ${event.path}');
      debounceTimer?.cancel();
      debounceTimer = Timer(Duration(milliseconds: 500), () async {
        await restartServer();
      });
    }
  });
}
