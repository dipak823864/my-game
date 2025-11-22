import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_editor/game/drishya_game.dart';

void main() {
  runApp(const ProviderScope(child: DrishyaApp()));
}

class DrishyaApp extends ConsumerStatefulWidget {
  const DrishyaApp({super.key});

  @override
  ConsumerState<DrishyaApp> createState() => _DrishyaAppState();
}

class _DrishyaAppState extends ConsumerState<DrishyaApp> {
  late DrishyaGame game;

  @override
  void initState() {
    super.initState();
    game = DrishyaGame(ref);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            // Game Widget
            GameWidget(game: game),

            // UI Overlay
            Positioned(
              top: 40,
              right: 20,
              child: ElevatedButton(
                onPressed: () {
                  game.toggleAI();
                  setState(() {}); // Rebuild to show status change if we wanted to update UI text
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: game.isAIActive ? Colors.green : Colors.red,
                ),
                child: Text(
                  game.isAIActive ? "AI: ACTIVE" : "AI: OFF",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Title
            const Positioned(
              top: 40,
              left: 20,
              child: Text(
                "Drishya: The Eternal Path",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
