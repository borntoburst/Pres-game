# 🎮 Preschool Games — Flutter Mini-Game App

A complete Flutter educational game app for preschool children (ages 3–6), built with clean architecture, kid-friendly UI, and four engaging mini-games.

---

## 🚀 Quick Start

```bash
flutter pub get
flutter run
```

**Requirements:** Flutter 3.x+, Dart SDK ≥ 3.0.0  
**Dependency:** `provider: ^6.1.1` (state management only)

---

## 📁 Project Structure

```
lib/
├── main.dart                         # Entry point, Provider setup, portrait lock
├── models/
│   └── game_info.dart                # GameInfo model + all-games registry
├── screens/
│   ├── home_screen.dart              # Game grid, global score badge
│   └── game_screen.dart             # App bar wrapper, routes to games
├── games/
│   ├── connect_pairs_game.dart       # 🎈 Balloon line-drawing game
│   ├── counting_game.dart            # ⭐ Counting with 3 difficulty levels
│   ├── shortest_object_game.dart     # 📏 Shortest object with trick cases
│   └── classification_game.dart     # 🐾 Drag-drop classification game
├── widgets/
│   ├── game_card.dart                # Home screen card with press animation
│   ├── answer_button.dart            # Large bouncy answer button
│   └── animated_feedback_widget.dart # Star burst + Next / Replay overlay
└── utils/
    ├── app_theme.dart                # ThemeData, color palette
    ├── score_provider.dart           # Global ChangeNotifier for score/level
    └── sound_util.dart               # Sound + TTS placeholders (print-based)
```

---

## 🎮 Games

### 🎈 Connect Pairs (Nối Cặp)
- **Levels:** 2×2 → 3×3 → 4×4 grid, auto-scales with level
- **Mechanic:** Drag to draw a line from one balloon to its same-colored partner
- **Path overlap detection:** Proximity sampling prevents crossing paths
- **Feedback:** Glowing paths, checkmark on connected nodes, shake + banner on error
- **Score:** +50 + (level × 10) per level complete

### ⭐ Counting Game (Đếm Số)
- **Difficulty tiers:** Easy (2–5), Medium (6–8), Hard (9–10)
- **Object pool:** 24 unambiguous emoji from 4 categories
- **3 answer choices:** Always distinct, always near the true count
- **Streak bonus:** +5 pts per answer when streak ≥ 3
- **Reward:** Animated star burst on correct answer
- **Voice:** `SoundUtil.speakInstruction()` prints to console (ready for flutter_tts)

### 📏 Shortest Object (Ngắn Nhất)
- **Visual ≠ actual:** Each object gets a random visual scale (0.5×–1.8×) independent of its true length, preventing naive visual shortcuts
- **Trick difficulty:** Length gap narrows from 20–30 (level 1) to 5–10 (level 5)
- **Randomized positions:** Objects placed at random vertical positions on the board
- **Post-answer reveal:** Shows true numerical lengths so teachers can discuss
- **Guaranteed 1 correct:** Only the item with minimum `value` is correct

### 🐾 Classification (Phân Loại)
- **Categories:** Animals, Vehicles, Fruit (2 random per round)
- **Mechanic:** `Draggable<int>` + `DragTarget<int>` for reliable drag-drop
- **Feedback:** Hover highlight, green glow on correct, red flash on wrong
- **Score:** +10 per correct placement

---

## 🎨 Design System

| Token          | Value       |
|----------------|-------------|
| Background     | `#FFF9F0`   |
| Orange accent  | `#FF6B35`   |
| Teal accent    | `#4ECDC4`   |
| Pink accent    | `#FF6B9D`   |
| Purple accent  | `#A855F7`   |
| Green accent   | `#6BCB77`   |
| Yellow primary | `#FFD93D`   |

All interactive elements use ≥ 48dp touch targets. Animations use `elasticOut` curves for a playful feel.

---

## 🔊 Sound Integration

Replace `SoundUtil` methods with a real audio package:

```yaml
# pubspec.yaml
dependencies:
  just_audio: ^0.9.37      # audio playback
  flutter_tts: ^4.0.2      # text-to-speech
```

```dart
// Replace SoundUtil.playCorrect():
await player.setAsset('assets/audio/correct.mp3');
await player.play();

// Replace SoundUtil.speakInstruction():
await flutterTts.speak(text);
```

---

## 📈 Score System

Managed by `ScoreProvider` (ChangeNotifier):

| Event              | Points             |
|--------------------|--------------------|
| Counting correct   | +10                |
| Streak ≥ 3 bonus   | +5                 |
| Shortest correct   | +10                |
| Classification hit | +10                |
| Pairs level done   | +50 + (level × 10) |

Every 100 pts = 1 ⭐ shown on home screen. Long-press the score badge to reset.

---

## 🏗 Architecture Notes

- **State management:** `Provider` + `setState` (appropriate for game scope)
- **Level generation:** Pure functions, deterministic per level number (easy to test)
- **Painters:** `CustomPainter` used only for grid lines and path drawing; all nodes are positioned `Widget`s for hit-testing accuracy
- **No external assets:** All visuals use emoji + Flutter primitives

---

## 🔧 Extending the App

**Add a new game:**
1. Create `lib/games/my_game.dart`
2. Add an entry to `allGames` in `lib/models/game_info.dart`
3. Add a `case` in `GameScreen._buildGame()`

**Add more levels to Connect Pairs:**
Edit `_buildLevel()` in `connect_pairs_game.dart` — the grid/pair counts are a simple lookup table.
