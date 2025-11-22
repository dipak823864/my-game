import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_editor/game/models.dart';

class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier() : super(GameState());

  void collectLetter(String letter) {
    state = GameState(collectedLetters: [...state.collectedLetters, letter]);
  }

  void reset() {
    state = GameState();
  }
}

final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier();
});
