import 'package:hydro/bin/globals.dart';
import 'package:hydro/bin/metadata/metadata.dart';

class Command implements Metadata {
  final String name;
  final Pattern? pattern;
  final String? arguments;

  const Command(this.name, [this.pattern, this.arguments]);

  @override
  bool shouldRun() {
    return name == args.first;
  }
}

@Command('name')
doSomething() {
  print('here is the name printed');
}
