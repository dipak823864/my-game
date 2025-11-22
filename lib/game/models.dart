enum Biome { gramam, nagaram, vanam }

enum ObstacleType { normal, low, collectible }

class Obstacle {
  final int laneIndex;
  final double distanceFromPlayer;
  final ObstacleType type;

  Obstacle({
    required this.laneIndex,
    required this.distanceFromPlayer,
    required this.type,
  });
}

class Player {
  int laneIndex;
  // Assuming we might need speed later, but for now just laneIndex is sufficient for the test logic

  Player({required this.laneIndex});
}

class GameState {
  final List<String> collectedLetters;

  GameState({this.collectedLetters = const []});
}
