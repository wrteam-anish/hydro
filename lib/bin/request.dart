abstract class Request {
  String get method;
  String path = '';
  Map<String, String>  arguments={};


  String? get(String key){
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
