class Request {
  String method = '';
  String path = '';
  Map<String, dynamic> arguments = {};
  Map<String, String> queryParameters = {};

  String? get(String key) {
    if (key.startsWith('?')) {
      return arguments['query']?[key];
    }
    return arguments[key];
  }
}

class Post extends Request {
  @override
  String get method => 'post';
}

class Get extends Request {
  @override
  String get method => 'get';
}

class Put extends Request {
  @override
  String get method => 'put';
}

class Patch extends Request {
  @override
  String get method => 'patch';
}

class Delete extends Request {
  @override
  String get method => 'delete';
}
