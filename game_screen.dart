import 'package:flutter/material.dart';

import '../models/game_info.dart';
import '../utils/app_theme.dart';
import '../games/connect_pairs_game.dart';
import '../games/counting_game.dart';
import '../games/shortest_object_game.dart';
import '../games/classification_game.dart';

/// Wraps each game with a common app bar and background.
class GameScreen extends StatelessWidget {
  final GameInfo game;
  const GameScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: game.color.withOpacity(0.08),
      appBar: AppBar(
        backgroundColor: game.color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(game.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Text(
              game.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ],
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: SafeArea(child: _buildGame()),
    );
  }

  Widget _buildGame() {
    switch (game.id) {
      case 'connect_pairs':
        return const ConnectPairsGame();
      case 'counting':
        return const CountingGame();
      case 'shortest':
        return const ShortestObjectGame();
      case 'classification':
        return const ClassificationGame();
      default:
        return const Center(child: Text('Coming soon!'));
    }
  }
}
