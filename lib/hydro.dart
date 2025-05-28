import 'dart:io';

import 'package:hydro/bin/entry_point.dart';
import 'package:hydro/bin/middleware.dart';
import 'package:hydro/bin/request.dart';
import 'package:hydro/bin/response.dart';
import 'package:hydro/bin/route.dart';

startServer(EntryPoint entryPoint) {
  BootStrap(entryPoint);
}

class BootStrap {
  BootStrap(EntryPoint entryPoint) {
    _serverStartup(
      entryPoint.configuration,
      entryPoint.routes,
      entryPoint.requestTypes,
      entryPoint.middlewares,
    );
  }

  _serverStartup(
    Configuration config,
    List<Route> routes,
    List<Request> requestTypes,
    List<Middleware> middlewares,
  ) async {
    HttpServer httpServer = await HttpServer.bind(config.ip, config.port);
    print('Server started on http://${config.ip.address}:${config.port}');

    httpServer.listen((HttpRequest req) async {
      for (Route route in routes) {
        if (matchRoute(route.target, req.uri.toString())) {
          for (Request request in requestTypes) {
            if (req.method.toLowerCase() == request.method.toLowerCase()) {
              Map<String, String>? parsedArguments = parseArguments(
                route.target,
                req.uri.path,
              );
              bool middlewarePassed = middlewares.handle(request);
              print('Passed :$middlewarePassed');

              if (!middlewarePassed) {
                // Middleware rejected the request — send 403 Forbidden or similar
                req.response.statusCode = HttpStatus.forbidden;
                await req.response.close();
                return;
              }

              Response? response = route.onRoute(
                request
                  ..path = req.uri.path
                  ..arguments = parsedArguments ?? {},
              );

              if (response != null) {
                req.response.headers.set('Content-Type', response.type);

                req.response.write(response.content);

                req.response.close();
              }
            }
          }
        }
      }
    });
  }
}

Map<String, String>? parseArguments(String pattern, String path) {
  final patternSegments = pattern.split('/');
  final pathSegments = path.split('/');

  Map<String, String> result = {};

  int pIndex = 0;
  int aIndex = 0;

  while (pIndex < patternSegments.length) {
    final pSegment = patternSegments[pIndex];

    if (aIndex >= pathSegments.length) {
      // If remaining pattern segments are all optional, we're good
      final remainingOptional = patternSegments
          .skip(pIndex)
          .every((seg) => seg.startsWith(':') && seg.endsWith('?'));
      return remainingOptional ? result : null;
    }

    final aSegment = pathSegments[aIndex];

    if (pSegment.startsWith(':')) {
      final isOptional = pSegment.endsWith('?');
      final paramName = pSegment.substring(
        1,
        isOptional ? pSegment.length - 1 : null,
      );

      if (!isOptional || (isOptional && aSegment.isNotEmpty)) {
        result[paramName] = aSegment;
        aIndex++;
      }

      pIndex++;
    } else {
      // Static segment must match
      if (pSegment != aSegment) return null;
      pIndex++;
      aIndex++;
    }
  }

  if (aIndex != pathSegments.length) return null; // extra segments in path
  return result;
}

bool matchRoute(String pattern, String path) {
  final patternSegments = pattern.split('/');
  final pathSegments = path.split('/');

  int pIndex = 0;
  int aIndex = 0;

  while (pIndex < patternSegments.length) {
    if (aIndex >= pathSegments.length) {
      // Check if remaining pattern segments are all optional
      final remainingOptional = patternSegments
          .skip(pIndex)
          .every((seg) => seg.startsWith(':') && seg.endsWith('?'));
      return remainingOptional;
    }

    final pSegment = patternSegments[pIndex];
    final aSegment = pathSegments[aIndex];

    if (pSegment.startsWith(':')) {
      if (pSegment.endsWith('?')) {
        // Optional parameter — advance pattern but only advance path if it exists
        pIndex++;
        aIndex++;
        continue;
      } else {
        // Regular dynamic parameter — must consume both
        pIndex++;
        aIndex++;
        continue;
      }
    }

    // Static segment must match exactly
    if (pSegment != aSegment) return false;

    pIndex++;
    aIndex++;
  }

  // Make sure all path segments are consumed
  return aIndex == pathSegments.length;
}
