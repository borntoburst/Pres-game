import 'package:flutter/foundation.dart';

/// Global score & level state shared across games.
class ScoreProvider extends ChangeNotifier {
  int _totalScore = 0;
  int _currentLevel = 1;
  int _stars = 0;

  int get totalScore => _totalScore;
  int get currentLevel => _currentLevel;
  int get stars => _stars;

  void addScore(int points) {
    _totalScore += points;
    // Every 100 points = 1 star
    _stars = _totalScore ~/ 100;
    notifyListeners();
  }

  void advanceLevel() {
    _currentLevel++;
    notifyListeners();
  }

  void reset() {
    _totalScore = 0;
    _currentLevel = 1;
    _stars = 0;
    notifyListeners();
  }
}
