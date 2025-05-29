import 'package:hydro/bin/request.dart';
import 'package:hydro/bin/response.dart';

abstract class Route {
  String get target;

  Response? onRoute(Request request);
}

class Root extends Route {
  @override
  Response? onRoute(Request request) {
    print('Method ${request is Get}');

    if (request is Get) {
      return View(
        '<A href="google.com"> Hello World ${request.get('id')}</a> <script>alert("Hello World")</script>',
        restrictJs: true,
      );
    }
    return null;
  }

  @override
  String get target => '/:id';
}
