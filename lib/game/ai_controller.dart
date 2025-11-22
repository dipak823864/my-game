import 'package:my_editor/game/models.dart';

enum GameAction { moveLeft, moveRight, jump, stay }

class AutoPilotSystem {
  GameAction decideMove(Player player, List<Obstacle> obstacles) {
    // Look-Ahead: Filter obstacles < 20 units away
    final relevantObstacles = obstacles.where((o) => o.distanceFromPlayer < 20).toList();

    if (relevantObstacles.isEmpty) {
      return GameAction.stay;
    }

    // Sort by distance to handle closest first
    relevantObstacles.sort((a, b) => a.distanceFromPlayer.compareTo(b.distanceFromPlayer));

    // Check for collectibles (Greedy)
    // We only care about collectibles if there isn't an immediate threat blocking the path
    // Or maybe we prioritize safety first, then greedy.
    // "Greedy: If safe, move toward Collectibles."

    // Let's build a simple map of safety per lane.
    // Lanes are -1, 0, 1.

    bool isLaneSafe(int lane) {
      // A lane is safe if there are no normal/low obstacles in it within the lookahead
      // OR if there is a 'low' obstacle, we can jump over it?
      // Wait, jumping is an action.
      // Let's simplify: A lane is BLOCKED if there is a non-collectible obstacle.

      // Note: 'low' obstacles require jumping, 'normal' block completely (unless we can jump them? Usually normal means avoid).
      // Scenario B says "middle obstacle type low... Assert returns Action.jump".
      // So 'low' can be jumped over. 'normal' must be avoided laterally.

      return !relevantObstacles.any((o) =>
        o.laneIndex == lane &&
        o.type != ObstacleType.collectible // Collectibles don't block
        // If it is 'low', it is technically safe IF we jump, but "isLaneSafe" usually implies "safe to exist in".
        // Let's define "clear" vs "jumpable".
      );
    }

    // Identify threats in current lane
    final currentLaneObstacles = relevantObstacles.where((o) => o.laneIndex == player.laneIndex).toList();

    Obstacle? closestThreat;
    for (final obs in currentLaneObstacles) {
      if (obs.type != ObstacleType.collectible) {
        closestThreat = obs;
        break;
      }
    }

    // GREEDY CHECK (If no immediate threat or threat is far enough?)
    // The prompt says "If safe, move toward Collectibles".
    // Let's check for collectibles in other lanes.

    final collectibles = relevantObstacles.where((o) => o.type == ObstacleType.collectible).toList();
    if (collectibles.isNotEmpty) {
      // Find closest collectible
      final target = collectibles.first; // They are sorted by distance

      if (target.laneIndex != player.laneIndex) {
        // Check if we can move there
        if (isLaneSafe(target.laneIndex)) {
          if (target.laneIndex < player.laneIndex) return GameAction.moveLeft;
          if (target.laneIndex > player.laneIndex) return GameAction.moveRight;
        }
      }
    }

    if (closestThreat == null) {
      // No immediate threat in current lane, and no reachable collectible triggered a move.
      return GameAction.stay;
    }

    // HANDING THREATS
    if (closestThreat.type == ObstacleType.low) {
      // Check if we can just jump
      // Scenario B: Block all lanes, middle is low -> Jump.
      // Implicitly, if we can switch to a safe lane, maybe we should?
      // But if all lanes are blocked, we MUST jump.
      // If side lanes are safe, should we jump or switch?
      // Usually switching is safer than jumping if valid.
      // But let's prioritize: if current is low, we CAN jump.

      // Let's check side lanes.
      bool leftSafe = player.laneIndex > -1 && isLaneSafe(player.laneIndex - 1);
      bool rightSafe = player.laneIndex < 1 && isLaneSafe(player.laneIndex + 1);

      if (!leftSafe && !rightSafe) {
        return GameAction.jump;
      }

      // If sides are safe, we could switch or jump.
      // Let's assume jumping is "costly" or "risky", so switch if possible?
      // Scenario B explicitly says "Block all lanes".
      // If I have a low obstacle and side is open, I'll switch.
      if (leftSafe) return GameAction.moveLeft;
      if (rightSafe) return GameAction.moveRight;

      return GameAction.jump; // Should be covered by !leftSafe && !rightSafe
    } else {
      // Normal obstacle (High/Tall). Must switch.
      bool leftSafe = player.laneIndex > -1 && isLaneSafe(player.laneIndex - 1);
      bool rightSafe = player.laneIndex < 1 && isLaneSafe(player.laneIndex + 1);

      if (leftSafe && rightSafe) {
        // Both safe, choose one?
        // Scenario A: Lane 0, dist 10. Left or Right.
        return GameAction.moveLeft; // Default to left?
      }
      if (leftSafe) return GameAction.moveLeft;
      if (rightSafe) return GameAction.moveRight;

      // If trapped (all lanes blocked by normal obstacles), nothing to do.
      // Maybe jump as a last resort? But for now stay.
      return GameAction.stay;
    }
  }

  // Helper to determine if a specific lane index has obstacles that are NOT collectibles
  // and are not low (unless we are considering jumping logic elsewhere)
  bool _isLaneBlocked(List<Obstacle> obstacles, int laneIndex) {
    return obstacles.any((o) => o.laneIndex == laneIndex && o.type != ObstacleType.collectible);
  }
}
