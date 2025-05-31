import 'package:html/dom.dart' as html;

abstract class Node {
  List<Node> children;
  Node({this.children = const []});

  html.Element renderDom();
  String renderHtml() => renderDom().outerHtml;
}

class Text extends Node {
  final String text;
  Text(this.text);

  @override
  html.Element renderDom() {
    final span = html.Element.tag('span');
    span.text = text;
    return span;
  }
}

class Div extends Node {
  Div({List<Node> children = const []}) : super(children: children);

  @override
  html.Element renderDom() {
    final div = html.Element.tag('div');
    for (final child in children) {
      div.append(child.renderDom());
    }
    return div;
  }
}

// === Image ===
class Image extends Node {
  final String url;
  final String? alt;
  Image(this.url, {this.alt});

  @override
  html.Element renderDom() {
    final img = html.Element.tag('img');
    img.attributes['src'] = url;
    if (alt != null) img.attributes['alt'] = alt!;
    return img;
  }
}

// === Column ===
class Column extends Node {
  Column({List<Node> children = const []}) : super(children: children);

  @override
  html.Element renderDom() {
    final div = html.Element.tag('div');
    div.attributes['style'] = 'display: flex; flex-direction: column;';
    for (final child in children) {
      div.append(child.renderDom());
    }
    return div;
  }
}

// === Row ===
class Row extends Node {
  Row({List<Node> children = const []}) : super(children: children);

  @override
  html.Element renderDom() {
    final div = html.Element.tag('div');
    div.attributes['style'] = 'display: flex; flex-direction: row;';
    for (final child in children) {
      div.append(child.renderDom());
    }
    return div;
  }
}

// === Flex (custom direction) ===
class Flex extends Node {
  final String direction; // 'row' or 'column'

  Flex({this.direction = 'row', List<Node> children = const []})
    : super(children: children);

  @override
  html.Element renderDom() {
    final div = html.Element.tag('div');
    div.attributes['style'] = 'display: flex; flex-direction: $direction;';
    for (final child in children) {
      div.append(child.renderDom());
    }
    return div;
  }
}

// === Button ===
class Button extends Node {
  final String label;
  final String? onClick;

  Button(this.label, {this.onClick});

  @override
  html.Element renderDom() {
    final btn = html.Element.tag('button');
    btn.text = label;
    if (onClick != null) btn.attributes['onclick'] = onClick!;
    return btn;
  }
}

// === TextField ===
class TextField extends Node {
  final String? placeholder;
  final String? name;

  TextField({this.placeholder, this.name});

  @override
  html.Element renderDom() {
    final input = html.Element.tag('input');
    input.attributes['type'] = 'text';
    if (placeholder != null) input.attributes['placeholder'] = placeholder!;
    if (name != null) input.attributes['name'] = name!;
    return input;
  }
}

// === TextArea ===
class TextArea extends Node {
  final String? placeholder;
  final String? name;

  TextArea({this.placeholder, this.name});

  @override
  html.Element renderDom() {
    final area = html.Element.tag('textarea');
    if (placeholder != null) area.attributes['placeholder'] = placeholder!;
    if (name != null) area.attributes['name'] = name!;
    return area;
  }
}

// === Video ===
class Video extends Node {
  final String src;
  final bool controls;

  Video(this.src, {this.controls = true});

  @override
  html.Element renderDom() {
    final video = html.Element.tag('video');
    video.attributes['src'] = src;
    if (controls) video.attributes['controls'] = '';
    return video;
  }
}

// === Audio ===
class Audio extends Node {
  final String src;
  final bool controls;

  Audio(this.src, {this.controls = true});

  @override
  html.Element renderDom() {
    final audio = html.Element.tag('audio');
    audio.attributes['src'] = src;
    if (controls) audio.attributes['controls'] = '';
    return audio;
  }
}
