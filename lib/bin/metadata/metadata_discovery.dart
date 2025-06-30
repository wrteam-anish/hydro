import 'dart:mirrors';

import 'package:hydro/bin/globals.dart';
import 'package:hydro/bin/metadata/metadata.dart';

class MetadataDiscovery {
  static void discover() {
    final mirrorSystem = currentMirrorSystem();
    bool found = false;

    for (final lib in mirrorSystem.libraries.values) {
      for (final decl in lib.declarations.values) {
        if (decl is MethodMirror &&
            decl.metadata.isNotEmpty &&
            decl.isRegularMethod &&
            decl.isStatic) {
          for (final InstanceMirror meta in decl.metadata) {
            final annotation = meta.reflectee;

            final ClassMirror annotationMirror =
                reflectType(annotation.runtimeType) as ClassMirror;
            final ClassMirror metadataType =
                reflectType(Metadata) as ClassMirror;
            if (annotationMirror.isSubtypeOf(metadataType)) {
              final childClass = meta.reflectee as Metadata;
              if (childClass.shouldRun()) {
                lib.invoke(decl.simpleName, []);
                found = true;
                break;
              }
            }
          }
        }
      }
    }
    if (!found) {
      print('Unknown command: ${args.join(" ")}');
    }
  }
}
