import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:my_editor/game/models.dart';

class WorldRenderer extends Component with HasGameRef {
  final Biome currentBiome;

  WorldRenderer({required this.currentBiome});

  @override
  Future<void> onLoad() async {
    // Add the background component
    add(ProceduralBackground(currentBiome));
  }
}

class ProceduralBackground extends PositionComponent with HasGameRef {
  final Biome biome;

  ProceduralBackground(this.biome);

  @override
  void render(Canvas canvas) {
    // Determine color based on biome
    final color = biome == Biome.gramam ? Colors.green[900] :
                  biome == Biome.nagaram ? Colors.grey[900] : Colors.teal[900];

    // Fill the screen
    canvas.drawRect(gameRef.size.toRect(), Paint()..color = color ?? Colors.black);

    // Bloom effect simulation (overlay)
    final Paint bloomPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          Colors.white.withOpacity(0.05),
          Colors.transparent
        ],
        stops: const [0.0, 1.0],
      ).createShader(gameRef.size.toRect());

    canvas.drawRect(gameRef.size.toRect(), bloomPaint);
  }
}
