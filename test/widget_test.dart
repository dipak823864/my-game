import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_editor/editor_canvas.dart';
import 'package:my_editor/models.dart';
import 'dart:convert';

void main() {
  testWidgets('Headless Game Test - JSON to Physics', (WidgetTester tester) async {
    // 1. Define the game state purely as JSON
    // A rectangle with velocity moving to the right
    final jsonString = '''
    {
      "width": 800,
      "height": 600,
      "backgroundColor": 4294967295,
      "layers": [
        {
          "type": "rectangle",
          "id": "rect-1",
          "color": 4294901760,
          "width": 100,
          "height": 100,
          "x": 0,
          "y": 0,
          "vx": 100,
          "vy": 0,
          "rotation": 0,
          "scale": 1
        }
      ]
    }
    ''';

    // 2. Initialize Engine State
    final Map<String, dynamic> jsonData = jsonDecode(jsonString);
    final composition = EditorComposition.fromJson(jsonData);

    // Verify initial state
    final rectLayer = composition.layers[0] as RectangleLayer;
    expect(rectLayer.position.dx, 0.0);
    expect(rectLayer.velocity.dx, 100.0);

    // 3. Build the Game Widget
    // We need to pump it to start the Ticker
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditorCanvas(composition: composition),
        ),
      ),
    );

    // 4. Simulate passage of time
    // We pump for 1 second (1000ms).
    // The physics engine should update position = position + velocity * dt
    // new_x = 0 + 100 * 1.0 = 100
    await tester.pump(const Duration(seconds: 1));

    // 5. Assert Game State Updated
    // We allow a small epsilon because Ticker might not be exactly precise down to the microsecond in tests
    expect(rectLayer.position.dx, closeTo(100.0, 5.0));

    // Optional: Simulate another second
    await tester.pump(const Duration(seconds: 1));
    expect(rectLayer.position.dx, closeTo(200.0, 5.0));
  });
}
