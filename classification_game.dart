import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/app_theme.dart';
import '../utils/score_provider.dart';
import '../utils/sound_util.dart';

// ─────────────────────────────────────────────
// DATA
// ─────────────────────────────────────────────

class _Category {
  final String name;
  final String emoji;
  final Color color;
  final List<String> items;
  const _Category({
    required this.name,
    required this.emoji,
    required this.color,
    required this.items,
  });
}

const _categories = [
  _Category(
    name: 'Động vật',
    emoji: '🐾',
    color: AppTheme.primaryGreen,
    items: ['🐶','🐱','🐸','🦊','🐧','🐼','🦁','🐘'],
  ),
  _Category(
    name: 'Xe cộ',
    emoji: '🚗',
    color: AppTheme.primaryBlue,
    items: ['🚗','🚕','🚌','✈️','🚂','🚁','⛵','🚀'],
  ),
  _Category(
    name: 'Trái cây',
    emoji: '🍎',
    color: AppTheme.primaryPink,
    items: ['🍎','🍊','🍋','🍇','🍓','🫐','🍑','🍒'],
  ),
];

class _DragItem {
  final String emoji;
  final int categoryIndex;
  bool placed = false;

  _DragItem({required this.emoji, required this.categoryIndex});
}

// ─────────────────────────────────────────────
// GAME WIDGET
// ─────────────────────────────────────────────

class ClassificationGame extends StatefulWidget {
  const ClassificationGame({super.key});

  @override
  State<ClassificationGame> createState() => _ClassificationGameState();
}

class _ClassificationGameState extends State<ClassificationGame> {
  final _rng = Random();
  List<_DragItem> _items = [];
  int _score = 0;
  int _errors = 0;
  bool _levelComplete = false;
  int? _wrongDropIndex;

  // Pick 2 random categories per round
  List<int> _activeCatIndices = [0, 1];

  @override
  void initState() {
    super.initState();
    _loadRound();
    SoundUtil.speakInstruction('Hãy sắp xếp vào đúng nhóm nhé!');
  }

  void _loadRound() {
    _activeCatIndices = List.generate(_categories.length, (i) => i)
      ..shuffle(_rng);
    _activeCatIndices = _activeCatIndices.sublist(0, 2);

    final items = <_DragItem>[];
    for (final ci in _activeCatIndices) {
      final cat = _categories[ci];
      final shuffled = List<String>.from(cat.items)..shuffle(_rng);
      for (final emoji in shuffled.take(3)) {
        items.add(_DragItem(emoji: emoji, categoryIndex: ci));
      }
    }
    items.shuffle(_rng);

    setState(() {
      _items = items;
      _levelComplete = false;
      _wrongDropIndex = null;
    });
  }

  void _onDrop(int itemIndex, int targetCatIndex) {
    final item = _items[itemIndex];
    final correct = item.categoryIndex == targetCatIndex;
    if (correct) {
      setState(() {
        item.placed = true;
        _score += 10;
        _wrongDropIndex = null;
      });
      SoundUtil.playCorrect();
      context.read<ScoreProvider>().addScore(10);
      if (_items.every((e) => e.placed)) {
        setState(() => _levelComplete = true);
        SoundUtil.playComplete();
      }
    } else {
      setState(() {
        _errors++;
        _wrongDropIndex = targetCatIndex;
      });
      SoundUtil.playWrong();
      Future.delayed(
        const Duration(milliseconds: 600),
        () => setState(() => _wrongDropIndex = null),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = _activeCatIndices.map((i) => _categories[i]).toList();
    final unplaced = _items.where((e) => !e.placed).toList();

    return Column(
      children: [
        // Score
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('⭐ $_score', style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800,
              )),
              Text(
                'Còn lại: ${unplaced.length}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppTheme.textLight),
              ),
            ],
          ),
        ),

        // Instruction
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Text(
            '🖐 Kéo thả vào đúng nhóm!',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                color: AppTheme.textDark),
            textAlign: TextAlign.center,
          ),
        ),

        // Category drop zones
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: List.generate(cats.length, (ci) {
              final cat = cats[ci];
              final catIdx = _activeCatIndices[ci];
              final placed = _items.where((e) => e.placed && e.categoryIndex == catIdx).toList();
              final isWrong = _wrongDropIndex == catIdx;

              return Expanded(
                child: DragTarget<int>(
                  onWillAcceptWithDetails: (_) => true,
                  onAcceptWithDetails: (details) => _onDrop(details.data, catIdx),
                  builder: (ctx, candidates, rejected) {
                    final hovering = candidates.isNotEmpty;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isWrong
                            ? Colors.red.withOpacity(0.1)
                            : hovering
                                ? cat.color.withOpacity(0.25)
                                : cat.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isWrong
                              ? Colors.red
                              : hovering
                                  ? cat.color
                                  : cat.color.withOpacity(0.3),
                          width: hovering || isWrong ? 3 : 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(cat.emoji, style: const TextStyle(fontSize: 30)),
                          Text(cat.name, style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800,
                            color: cat.color,
                          )),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4, runSpacing: 4,
                            children: placed.map((e) => Text(e.emoji,
                                style: const TextStyle(fontSize: 24))).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ),

        // Draggable items
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _levelComplete
                ? _buildComplete()
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: List.generate(_items.length, (i) {
                      final item = _items[i];
                      if (item.placed) return const SizedBox.shrink();
                      return Draggable<int>(
                        data: i,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(item.emoji,
                                style: const TextStyle(fontSize: 32)),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _itemCard(item.emoji),
                        ),
                        child: _itemCard(item.emoji),
                      );
                    }),
                  ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _itemCard(String emoji) {
    return Container(
      width: 68, height: 68,
      decoration: BoxDecoration(
        color: AppTheme.primaryYellow.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryYellow, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 34)),
    );
  }

  Widget _buildComplete() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🎉', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 8),
        const Text('Giỏi lắm!', style: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w900,
        )),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loadRound,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('Chơi tiếp!', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }
}
