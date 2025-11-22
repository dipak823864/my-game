import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:my_editor/game/ai_controller.dart';
import 'package:my_editor/game/models.dart';
import 'package:my_editor/game/world_renderer.dart';
import 'package:my_editor/game/state_management.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DrishyaGame extends FlameGame with HasCollisionDetection, TapDetector {
  final WidgetRef ref;
  final AudioPlayer _audioPlayer = AudioPlayer();

  DrishyaGame(this.ref);

  late Player playerModel;
  late AutoPilotSystem _aiController;
  bool isAIActive = false;

  // Game entities
  late PlayerComponent playerComponent;
  // We would have a proper ObstacleManager, but for this iteration we'll simulate or implement basic spawning.
  List<Obstacle> obstacles = [];

  // Biome management
  Biome currentBiome = Biome.gramam;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Initialize Logic
    playerModel = Player(laneIndex: 0);
    _aiController = AutoPilotSystem();

    // Add Background/World
    add(WorldRenderer(currentBiome: currentBiome));

    // Add Player
    playerComponent = PlayerComponent(playerModel);
    add(playerComponent);

    // Add minimal obstacle spawner (Simulated for now or basic implementation)
    // In a real game, we'd have an ObstacleManager component.

    // Start ambient audio
    // _audioPlayer.setReleaseMode(ReleaseMode.loop);
    // await _audioPlayer.play(AssetSource('ambient.mp3')); // Commented out as we don't have assets
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isAIActive) {
      final action = _aiController.decideMove(playerModel, obstacles);
      _applyAction(action);
    }

    // Update obstacles (move them towards player, spawn new ones, etc.)
    // For the scope of this task, we focus on the AI hook.

    // Check for collisions/collections (Simulated)
    // if (collidedWithLetter) {
    //   ref.read(gameStateProvider.notifier).collectLetter("D");
    //   _playChord();
    // }

    // Sync visual player position with model
    playerComponent.updatePosition(dt);
  }

  void _applyAction(GameAction action) {
    // Simple state machine for movement
    switch (action) {
      case GameAction.moveLeft:
        if (playerModel.laneIndex > -1) {
           playerModel.laneIndex--;
           _playSfx();
        }
        break;
      case GameAction.moveRight:
        if (playerModel.laneIndex < 1) {
           playerModel.laneIndex++;
           _playSfx();
        }
        break;
      case GameAction.jump:
        playerComponent.jump();
        _playSfx();
        break;
      case GameAction.stay:
        break;
    }
  }

  void toggleAI() {
    isAIActive = !isAIActive;
    debugPrint("AI Autopilot: $isAIActive");
  }

  void _playSfx() {
    // Play a procedural beep or placeholder
    // _audioPlayer.play(AssetSource('sfx.wav'));
  }

  void _playChord() {
    // Procedural chord logic would go here
  }
}

class PlayerComponent extends PositionComponent {
  final Player model;
  static const double laneWidth = 100.0;

  bool isJumping = false;
  double jumpTimer = 0;

  PlayerComponent(this.model);

  @override
  Future<void> onLoad() async {
    // Placeholder for player sprite
    // add(SpriteComponent(...));
    // Using a simple rect for visualization
    add(RectangleComponent(
      size: Vector2(50, 50),
      paint: Paint()..color = Colors.orange,
      anchor: Anchor.center,
    ));
  }

  void updatePosition(double dt) {
    // Lerp towards target lane X
    double targetX = model.laneIndex * laneWidth;
    // Simple lerp
    x += (targetX - x) * 10 * dt;

    // Jump logic
    if (isJumping) {
      y = -100; // Jump height
      jumpTimer -= dt;
      if (jumpTimer <= 0) {
        isJumping = false;
        y = 0;
      }
    } else {
      y = 0;
    }
  }

  void jump() {
    if (!isJumping) {
      isJumping = true;
      jumpTimer = 0.5; // Jump duration
    }
  }
}
