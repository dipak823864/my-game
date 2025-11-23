import 'package:flutter/material.dart';

// Constants
const double handleRadius = 9.0;
const double rotationHandleDistance = 30.0;

class EditorComposition {
  Size dimension;
  Color backgroundColor;
  List<BaseLayer> layers;

  EditorComposition({
    required this.dimension,
    this.backgroundColor = Colors.white,
    List<BaseLayer>? layers,
  }) : layers = layers ?? [];

  factory EditorComposition.fromJson(Map<String, dynamic> json) {
    return EditorComposition(
      dimension: Size(
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
      backgroundColor: Color(json['backgroundColor'] as int),
      layers: (json['layers'] as List)
          .map((l) => BaseLayer.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width': dimension.width,
      'height': dimension.height,
      'backgroundColor': backgroundColor.value,
      'layers': layers.map((l) => l.toJson()).toList(),
    };
  }
}

abstract class BaseLayer {
  String id;
  String type;
  Offset position;
  Offset velocity;
  double rotation;
  double scale;
  bool isSelected;
  bool isEditing;

  BaseLayer({
    required this.id,
    required this.type,
    this.position = Offset.zero,
    this.velocity = Offset.zero,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.isSelected = false,
    this.isEditing = false,
  });

  factory BaseLayer.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'text':
        return TextLayer.fromJson(json);
      case 'rectangle':
        return RectangleLayer.fromJson(json);
      case 'circle':
        return CircleLayer.fromJson(json);
      default:
        throw Exception('Unknown layer type: ${json['type']}');
    }
  }

  Map<String, dynamic> toJson();

  Matrix4 get matrix {
    final mat = Matrix4.identity();
    mat.setTranslationRaw(position.dx, position.dy, 0);
    mat.rotateZ(rotation);
    mat.scale(scale, scale, 1.0);
    return mat;
  }

  void paint(Canvas canvas, Size size);
  Size get size;
}

class TextLayer extends BaseLayer {
  String text;
  TextStyle style;
  Size _cachedSize = Size.zero;

  TextSelection selection;
  bool showCursor;

  TextLayer({
    required super.id,
    required this.text,
    super.position,
    super.velocity,
    super.rotation,
    super.scale,
    this.style = const TextStyle(fontSize: 30, color: Colors.black),
    this.selection = const TextSelection.collapsed(offset: 0),
    this.showCursor = false,
  }) : super(type: 'text');

  factory TextLayer.fromJson(Map<String, dynamic> json) {
    return TextLayer(
      id: json['id'] as String,
      text: json['text'] as String,
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      velocity: Offset(
        (json['vx'] as num).toDouble(),
        (json['vy'] as num).toDouble(),
      ),
      rotation: (json['rotation'] as num).toDouble(),
      scale: (json['scale'] as num).toDouble(),
      style: TextStyle(
        fontSize: (json['fontSize'] as num).toDouble(),
        color: Color(json['color'] as int),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'text': text,
      'x': position.dx,
      'y': position.dy,
      'vx': velocity.dx,
      'vy': velocity.dy,
      'rotation': rotation,
      'scale': scale,
      'fontSize': style.fontSize,
      'color': style.color?.value ?? Colors.black.value,
    };
  }

  @override
  Size get size => _cachedSize;

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    _cachedSize = textPainter.size;

    final paintOffset = Offset(-_cachedSize.width / 2, -_cachedSize.height / 2);

    // 1. Draw Selection Highlights
    if (isEditing) {
      final selectionColor = Colors.blue.withValues(alpha: 0.3);
      final safeSelection = TextSelection(
        baseOffset: selection.baseOffset.clamp(0, text.length),
        extentOffset: selection.extentOffset.clamp(0, text.length),
      );

      if (!safeSelection.isCollapsed) {
        final boxes = textPainter.getBoxesForSelection(safeSelection);
        for (var box in boxes) {
          final rect = box.toRect().shift(paintOffset);
          canvas.drawRect(rect, Paint()..color = selectionColor);
        }
      }
    }

    // 2. Draw Text
    textPainter.paint(canvas, paintOffset);

    // 3. Draw Cursor
    if (isEditing && showCursor && selection.isCollapsed) {
      final safeOffset = selection.baseOffset.clamp(0, text.length);
      final caretOffset = textPainter.getOffsetForCaret(
        TextPosition(offset: safeOffset),
        Rect.zero,
      );
      final cursorHeight = text.isEmpty
          ? (style.fontSize ?? 30)
          : textPainter.preferredLineHeight;

      final p1 = paintOffset + caretOffset;
      final p2 = p1 + Offset(0, cursorHeight);

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = Colors.blueAccent
          ..strokeWidth = 2,
      );
    }

    _drawUI(canvas, paintOffset & _cachedSize);
  }

  void _drawUI(Canvas canvas, Rect rect) {
    if (isSelected) {
      final borderPaint = Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / scale;

      _drawDashedRect(canvas, rect, borderPaint);

      final handleFill = Paint()..color = Colors.white;
      final handleStroke = Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 / scale;
      final radius = handleRadius / scale;

      final corners = [
        rect.topLeft,
        rect.topRight,
        rect.bottomLeft,
        rect.bottomRight,
      ];
      for (var point in corners) {
        canvas.drawCircle(point, radius, handleFill);
        canvas.drawCircle(point, radius, handleStroke);
      }

      final topCenter = rect.topCenter;
      final rotPos = Offset(
        topCenter.dx,
        topCenter.dy - (rotationHandleDistance / scale),
      );
      canvas.drawLine(topCenter, rotPos, borderPaint);
      canvas.drawCircle(rotPos, radius, handleFill);
      canvas.drawCircle(rotPos, radius, handleStroke);
    }
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    final path = Path()..addRect(rect);
    final dashWidth = 10.0 / scale;
    final dashSpace = 5.0 / scale;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }
}

class RectangleLayer extends BaseLayer {
  Color color;
  Size _size;

  RectangleLayer({
    required super.id,
    required this.color,
    required Size size,
    super.position,
    super.velocity,
    super.rotation,
    super.scale,
  }) : _size = size,
       super(type: 'rectangle');

  factory RectangleLayer.fromJson(Map<String, dynamic> json) {
    return RectangleLayer(
      id: json['id'] as String,
      color: Color(json['color'] as int),
      size: Size(
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      velocity: Offset(
        (json['vx'] as num).toDouble(),
        (json['vy'] as num).toDouble(),
      ),
      rotation: (json['rotation'] as num).toDouble(),
      scale: (json['scale'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'color': color.value,
      'width': _size.width,
      'height': _size.height,
      'x': position.dx,
      'y': position.dy,
      'vx': velocity.dx,
      'vy': velocity.dy,
      'rotation': rotation,
      'scale': scale,
    };
  }

  @override
  Size get size => _size;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: _size.width,
      height: _size.height,
    );
    canvas.drawRect(rect, Paint()..color = color);

    if (isSelected) {
      final borderPaint = Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / scale;

      final handleFill = Paint()..color = Colors.white;
      final handleStroke = Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 / scale;
      final radius = handleRadius / scale;

      canvas.drawRect(rect, borderPaint);

      final corners = [
        rect.topLeft,
        rect.topRight,
        rect.bottomLeft,
        rect.bottomRight,
      ];
      for (var point in corners) {
        canvas.drawCircle(point, radius, handleFill);
        canvas.drawCircle(point, radius, handleStroke);
      }

      final topCenter = rect.topCenter;
      final rotPos = Offset(
        topCenter.dx,
        topCenter.dy - (rotationHandleDistance / scale),
      );
      canvas.drawLine(topCenter, rotPos, borderPaint);
      canvas.drawCircle(rotPos, radius, handleFill);
      canvas.drawCircle(rotPos, radius, handleStroke);
    }
  }
}

class CircleLayer extends BaseLayer {
  Color color;
  double radius;

  CircleLayer({
    required super.id,
    required this.color,
    required this.radius,
    super.position,
    super.velocity,
    super.rotation,
    super.scale,
  }) : super(type: 'circle');

  factory CircleLayer.fromJson(Map<String, dynamic> json) {
    return CircleLayer(
      id: json['id'] as String,
      color: Color(json['color'] as int),
      radius: (json['radius'] as num).toDouble(),
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      velocity: Offset(
        (json['vx'] as num).toDouble(),
        (json['vy'] as num).toDouble(),
      ),
      rotation: (json['rotation'] as num).toDouble(),
      scale: (json['scale'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'color': color.value,
      'radius': radius,
      'x': position.dx,
      'y': position.dy,
      'vx': velocity.dx,
      'vy': velocity.dy,
      'rotation': rotation,
      'scale': scale,
    };
  }

  @override
  Size get size => Size(radius * 2, radius * 2);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(Offset.zero, radius, Paint()..color = color);

    if (isSelected) {
      final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
      final borderPaint = Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / scale;

      final handleFill = Paint()..color = Colors.white;
      final handleStroke = Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 / scale;
      final r = handleRadius / scale;

      canvas.drawRect(rect, borderPaint); // Draw bounding box for selection

      final corners = [
        rect.topLeft,
        rect.topRight,
        rect.bottomLeft,
        rect.bottomRight,
      ];
      for (var point in corners) {
        canvas.drawCircle(point, r, handleFill);
        canvas.drawCircle(point, r, handleStroke);
      }

      final topCenter = rect.topCenter;
      final rotPos = Offset(
        topCenter.dx,
        topCenter.dy - (rotationHandleDistance / scale),
      );
      canvas.drawLine(topCenter, rotPos, borderPaint);
      canvas.drawCircle(rotPos, r, handleFill);
      canvas.drawCircle(rotPos, r, handleStroke);
    }
  }
}
