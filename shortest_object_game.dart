import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/app_theme.dart';
import '../utils/score_provider.dart';
import '../utils/sound_util.dart';
import '../widgets/answer_button.dart';

// ─────────────────────────────────────────────
// OBJECT DEFINITIONS
// ─────────────────────────────────────────────

class _ObjectType {
  final String emoji;
  final String name;
  final Color color;
  const _ObjectType(this.emoji, this.name, this.color);
}

const _objectTypes = [
  _ObjectType('🐍', 'Con rắn',  Color(0xFF6BCB77)),
  _ObjectType('🪱', 'Con sâu',  Color(0xFFFF6B35)),
  _ObjectType('📏', 'Cây thước', Color(0xFF4ECDC4)),
  _ObjectType('🎀', 'Dải ruy-băng', Color(0xFFFF6B9D)),
  _ObjectType('🌈', 'Cầu vồng', Color(0xFFA855F7)),
  _ObjectType('🎋', 'Cây tre',  Color(0xFF6BCB77)),
  _ObjectType('🚂', 'Đoàn tàu', Color(0xFFFF6B35)),
];

// ─────────────────────────────────────────────
// QUESTION MODEL
// ─────────────────────────────────────────────

class _ShortItem {
  final _ObjectType type;
  /// The TRUE length value (1–100). Shortest = correct answer.
  final double value;
  /// Visual width = value * scale multiplier (disconnected from value).
  final double visualWidth;
  /// Random vertical position within the board (0 = top, 1 = bottom).
  final double verticalFraction;
  /// Whether this object is flipped horizontally.
  final bool flipped;

  const _ShortItem({
    required this.type,
    required this.value,
    required this.visualWidth,
    required this.verticalFraction,
    required this.flipped,
  });
}

class _ShortQuestion {
  final List<_ShortItem> items;
  final int correctIndex;
  const _ShortQuestion({required this.items, required this.correctIndex});
}

/// Generates a question where visual width ≠ actual value.
/// Trick cases: items very similar in length, but visual scale differs.
_ShortQuestion _generateQuestion(int level, Random rng) {
  final type = _objectTypes[rng.nextInt(_objectTypes.length)];
  const int count = 4;

  // Difficulty: gap between lengths shrinks with level
  // Level 1: gap 20–30, Level 3+: gap 5–10
  final int minGap = max(5, 30 - level * 8);
  final int maxGap = max(8, 40 - level * 8);

  // Generate unique actual lengths with sufficient gaps
  double shortest = 20 + rng.nextDouble() * 20; // 20–40
  List<double> values = [shortest];
  for (int i = 1; i < count; i++) {
    final gap = minGap + rng.nextDouble() * (maxGap - minGap);
    values.add(values.last + gap);
  }
  values.shuffle(rng);

  // Correct index = item with smallest value
  final correctIndex = values.indexOf(values.reduce(min));

  // Visual width: apply a DIFFERENT random scale per item (trick!)
  // This breaks the naive "longest looking = longest" assumption.
  final items = List.generate(count, (i) {
    // Scale between 0.5× and 1.8× relative to value
    final scale = 0.5 + rng.nextDouble() * 1.3;
    return _ShortItem(
      type: type,
      value: values[i],
      visualWidth: values[i] * scale,
      verticalFraction: 0.15 + rng.nextDouble() * 0.65,
      flipped: rng.nextBool(),
    );
  });

  return _ShortQuestion(items: items, correctIndex: correctIndex);
}

// ─────────────────────────────────────────────
// GAME WIDGET
// ─────────────────────────────────────────────

class ShortestObjectGame extends StatefulWidget {
  const ShortestObjectGame({super.key});

  @override
  State<ShortestObjectGame> createState() => _ShortestObjectGameState();
}

class _ShortestObjectGameState extends State<ShortestObjectGame>
    with SingleTickerProviderStateMixin {

  final _rng = Random();
  int _level = 1;
  int _score = 0;
  late _ShortQuestion _question;
  int? _selected;
  bool _answered = false;
  late AnimationController _bounceCtrl;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400),
    );
    _nextQuestion();
    SoundUtil.speakInstruction('Tìm vật ngắn nhất nhé!');
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    setState(() {
      _question = _generateQuestion(_level, _rng);
      _selected = null;
      _answered = false;
    });
  }

  void _selectItem(int index) {
    if (_answered) return;
    final correct = index == _question.correctIndex;
    setState(() {
      _selected = index;
      _answered = true;
      if (correct) {
        _score += 10;
        SoundUtil.playCorrect();
        context.read<ScoreProvider>().addScore(10);
        _bounceCtrl.forward(from: 0);
      } else {
        SoundUtil.playWrong();
      }
    });
    Future.delayed(
      const Duration(milliseconds: 1400),
      () {
        if (correct && _level < 5) setState(() => _level++);
        _nextQuestion();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Màn $_level', style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800,
              )),
              Text('⭐ $_score', style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primaryOrange,
              )),
            ],
          ),
        ),

        // Instruction
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('📏', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Text(
                'Chạm vào vật NGẮN NHẤT!',
                style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ),

        // Board
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: LayoutBuilder(builder: (ctx, constraints) {
                return Stack(
                  children: List.generate(_question.items.length, (i) {
                    return _buildItem(i, constraints.maxWidth, constraints.maxHeight);
                  }),
                );
              }),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Legend: show true lengths after answer
        if (_answered)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              'Độ dài thật: ' +
                  List.generate(
                    _question.items.length,
                    (i) => '${(i == _question.correctIndex ? '✅' : '')}${_question.items[i].value.toStringAsFixed(0)}',
                  ).join(' | '),
              style: const TextStyle(fontSize: 13, color: AppTheme.textLight),
              textAlign: TextAlign.center,
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildItem(int index, double boardW, double boardH) {
    final item = _question.items[index];
    // Normalize visual width to fit within board (max 80% of board width)
    final allVisual = _question.items.map((e) => e.visualWidth).toList();
    final maxVisual = allVisual.reduce(max);
    final normalizedW = (item.visualWidth / maxVisual) * boardW * 0.78;

    // Vertical position
    final topPos = item.verticalFraction * (boardH - 60);

    // Left aligned with random indent
    const double leftPad = 24;

    bool isCorrect = _answered && index == _question.correctIndex;
    bool isWrong   = _answered && index == _selected && index != _question.correctIndex;

    return Positioned(
      left: leftPad,
      top: topPos,
      child: GestureDetector(
        onTap: () => _selectItem(index),
        child: AnimatedScale(
          scale: isCorrect ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          child: Container(
            height: 48,
            width: normalizedW,
            decoration: BoxDecoration(
              color: isCorrect
                  ? AppTheme.primaryGreen.withOpacity(0.2)
                  : isWrong
                      ? Colors.red.withOpacity(0.1)
                      : item.type.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCorrect
                    ? AppTheme.primaryGreen
                    : isWrong
                        ? Colors.red
                        : item.type.color,
                width: isCorrect || isWrong ? 3 : 2,
              ),
            ),
            child: Row(
              children: item.flipped
                  ? [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 4,
                          decoration: BoxDecoration(
                            color: item.type.color.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(item.type.emoji,
                            style: const TextStyle(fontSize: 22)),
                      ),
                    ]
                  : [
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(item.type.emoji,
                            style: const TextStyle(fontSize: 22)),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 4,
                          decoration: BoxDecoration(
                            color: item.type.color.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
