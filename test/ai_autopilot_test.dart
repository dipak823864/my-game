import 'package:flutter_test/flutter_test.dart';
import 'package:my_editor/game/ai_controller.dart';
import 'package:my_editor/game/models.dart';

void main() {
  group('AutoPilotSystem Tests', () {
    late AutoPilotSystem ai;

    setUp(() {
      ai = AutoPilotSystem();
    });

    test('Scenario A (Critical): Obstacle in Lane 0 at dist 10 -> Move Left or Right', () {
      final player = Player(laneIndex: 0);
      final obstacles = [
        Obstacle(laneIndex: 0, distanceFromPlayer: 10, type: ObstacleType.normal),
      ];

      final action = ai.decideMove(player, obstacles);

      expect(action, anyOf(GameAction.moveLeft, GameAction.moveRight));
    });

    test('Scenario B (Jump): All lanes blocked, middle obstacle low -> Jump', () {
      final player = Player(laneIndex: 0);
      final obstacles = [
        Obstacle(laneIndex: -1, distanceFromPlayer: 10, type: ObstacleType.normal),
        Obstacle(laneIndex: 0, distanceFromPlayer: 10, type: ObstacleType.low),
        Obstacle(laneIndex: 1, distanceFromPlayer: 10, type: ObstacleType.normal),
      ];

      final action = ai.decideMove(player, obstacles);

      expect(action, GameAction.jump);
    });

    test('Scenario C (Greedy): Collectible in Lane 1 (Right) -> Move to Lane 1', () {
      final player = Player(laneIndex: 0);
      final obstacles = [
        // Safe path to collectible
        Obstacle(laneIndex: 1, distanceFromPlayer: 15, type: ObstacleType.collectible),
      ];

      final action = ai.decideMove(player, obstacles);

      expect(action, GameAction.moveRight);
    });
  });
}
