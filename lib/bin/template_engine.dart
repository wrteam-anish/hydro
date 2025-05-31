class HydroTemplateEngine {
  final Map<String, dynamic> context;

  HydroTemplateEngine(this.context);

  String render(String template) {
    template = _renderConditionals(template);
    template = _renderLoops(template);
    template = _renderVariables(template);
    return template;
  }

  String _renderVariables(String template) {
    return template.replaceAllMapped(RegExp(r'{{\s*([a-zA-Z0-9_.]+)\s*}}'), (
      match,
    ) {
      final keyPath = match.group(1)!;
      final value = _resolveKeyPath(keyPath, context);
      return value?.toString() ?? '';
    });
  }

  String _renderConditionals(String template) {
    final pattern = RegExp(
      r'{{if (.+?)}}(.*?)({{else}}(.*?))?{{end}}',
      dotAll: true,
    );
    return template.replaceAllMapped(pattern, (match) {
      final condition = match.group(1)!.trim();
      final trueBlock = match.group(2)!;
      final falseBlock = match.group(4) ?? '';

      final conditionValue = _resolveKeyPath(condition, context);
      final isTrue =
          conditionValue == true ||
          conditionValue == 'true' ||
          conditionValue != null && conditionValue != false;

      return isTrue ? trueBlock : falseBlock;
    });
  }

  String _renderLoops(String template) {
    final loopPattern = RegExp(
      r'{{for (\w+) in ([a-zA-Z0-9_.]+)}}(.*?){{end}}',
      dotAll: true,
    );
    return template.replaceAllMapped(loopPattern, (match) {
      final itemVar = match.group(1)!;
      final listKey = match.group(2)!;
      final block = match.group(3)!;

      final list = _resolveKeyPath(listKey, context);
      if (list is! List) return '';

      return list.map((item) {
        final localCtx = Map<String, dynamic>.from(context);
        localCtx[itemVar] = item;
        return HydroTemplateEngine(localCtx).render(block);
      }).join();
    });
  }

  dynamic _resolveKeyPath(String keyPath, Map<String, dynamic> ctx) {
    final keys = keyPath.split('.');
    dynamic current = ctx;
    for (var key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }
}
