// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:hydro/bin/constants.dart';
import 'package:hydro/bin/htc_node.dart';
import 'package:hydro/bin/template_engine.dart';

abstract class Response {
  final String content;
  bool isTemplate = false;
  final String type = 'text/plain';
  Future<String> render() async {
    return Future.value('');
  }

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
  Map<String, dynamic>? arguments;

  View(String rawContent, {this.restrictJs = false, this.arguments})
    : content = restrictJs ? _removeScripts(rawContent) : rawContent,
      super(restrictJs ? _removeScripts(rawContent) : rawContent) {
    // Set isTemplate after super() because it's not in constructor
    isTemplate = rawContent.startsWith('@');
  }

  static String _removeScripts(String html) {
    final hotReloadScript = RegExp(
      r'<script>\s*const\s+socket\s*=\s*new\s+WebSocket[^<]*</script>',
      caseSensitive: false,
      dotAll: true,
    );

    final scriptTagRegExp = RegExp(
      r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>',
      caseSensitive: false,
      dotAll: true,
    );

    final hotReloadMatch = hotReloadScript.firstMatch(html);
    final hotReloadScriptContent = hotReloadMatch?.group(0) ?? '';

    String withoutScripts = html.replaceAll(scriptTagRegExp, '');

    if (hotReloadScriptContent.isNotEmpty) {
      withoutScripts += hotReloadScriptContent;
    }

    return withoutScripts;
  }

  Future<String> templateLoader(String name) async {
    final String stripedName = name.replaceFirst('@', '');
    String filePath =
        '${Constant.templateFolder}/$stripedName.${Constant.templateExtension}';
    String content = await File(filePath).readAsString();
    return await HydroTemplateEngine(arguments ?? {}).render(content);
  }

  @override
  Future<String> render() async {
    if (isTemplate) {
      return await templateLoader(content);
    }
    return content;
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

class HCT extends Response {
  final Node root;
  HCT({required this.root}) : super(root.renderHtml());
  @override
  String get type => 'text/html';
}
