abstract class Response {
  final String content;
  final String type = 'text/plain';
  Response(this.content);
}

class StringResponse extends Response {
  StringResponse(super.content);
}

class View extends Response {
  @override
  String get type => 'text/html';
  final bool restrictJs;
  final String content;

  View(String rawContent, {this.restrictJs = false})
    : content = restrictJs ? _removeScripts(rawContent) : rawContent,
      super(restrictJs ? _removeScripts(rawContent) : rawContent);

  static String _removeScripts(String html) {
    final scriptTagRegExp = RegExp(
      r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>',
      caseSensitive: false,
      dotAll: true,
    );
    return html.replaceAll(scriptTagRegExp, '');
  }
}

class Json extends Response {
  @override
  String get type => 'application/json';
  Json(super.content);
}

class Xml extends Response {
  @override
  String get type => 'application/xml';
  Xml(super.content);
}
