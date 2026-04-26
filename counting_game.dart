import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/app_theme.dart';
import '../utils/score_provider.dart';
import '../utils/sound_util.dart';
import '../widgets/answer_button.dart';
import '../widgets/animated_feedback_widget.dart';

// ─────────────────────────────────────────────
// DIFFICULTY CONFIG
// ─────────────────────────────────────────────

enum CountDifficulty { easy, medium, hard }

class _DiffConfig {
  final String label;
  final int min, max;
  final Color color;
  const _DiffConfig(this.label, this.min, this.max, this.color);
}

const _configs = {
  CountDifficulty.easy:   _DiffConfig('Dễ',    2,  5,  AppTheme.primaryGreen),
  CountDifficulty.medium: _DiffConfig('Vừa',   6,  8,  AppTheme.primaryBlue),
  CountDifficulty.hard:   _DiffConfig('Khó',   9, 10,  AppTheme.primaryPink),
};

// ─────────────────────────────────────────────
// OBJECT POOL — unambiguous emoji grouped by category
// ─────────────────────────────────────────────

const _objectPool = [
  '🍎', '🍊', '🍋', '🍇', '🍓', '🫐',
  '⭐', '🌟', '🔵', '🟡', '🔴', '🟢',
  '🐶', '🐱', '🐸', '🦊', '🐧', '🐼',
  '✏️', '📚', '🎈', '🏀', '⚽', '🎵',
];

// ─────────────────────────────────────────────
// QUESTION MODEL
// ─────────────────────────────────────────────

class _Question {
  final String objectEmoji;
  final int count;
  final List<int> choices; // always 3 choices, exactly 1 correct
  const _Question({
    required this.objectEmoji,
    required this.count,
    required this.choices,
  });
}

_Question _generateQuestion(CountDifficulty diff, Random rng) {
  final cfg = _configs[diff]!;
  final count = cfg.min + rng.nextInt(cfg.max - cfg.min + 1);
  final emoji = _objectPool[rng.nextInt(_objectPool.length)];

  // Generate 2 wrong answers that are close but distinct
  final Set<int> choiceSet = {count};
  while (choiceSet.length < 3) {
    int wrong = count + (rng.nextBool() ? 1 : -1) * (1 + rng.nextInt(3));
    if (wrong >= 1 && wrong <= 12 && wrong != count) {
      choiceSet.add(wrong);
    }
  }
  final choices = choiceSet.toList()..shuffle(rng);

  return _Question(objectEmoji: emoji, count: count, choices: choices);
}

// ─────────────────────────────────────────────
// GAME WIDGET
// ─────────────────────────────────────────────

class CountingGame extends StatefulWidget {
  const CountingGame({super.key});

  @override
  State<CountingGame> createState() => _CountingGameState();
}

class _CountingGameState extends State<CountingGame>
    with SingleTickerProviderStateMixin {

  final _rng = Random();
  CountDifficulty _difficulty = CountDifficulty.easy;
  late _Question _question;
  int _score = 0;
  int _streak = 0;
  int? _selectedAnswer;
  bool _answered = false;
  bool _showStars = false;
  late AnimationController _starCtrl;

  @override
  void initState() {
    super.initState();
    _starCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    );
    _nextQuestion();
    _speakInstruction();
  }

  void _speakInstruction() {
    SoundUtil.speakInstruction('Đếm xem có bao nhiêu ${_question.objectEmoji}?');
  }

  void _nextQuestion() {
    setState(() {
      _question = _generateQuestion(_difficulty, _rng);
      _selectedAnswer = null;
      _answered = false;
      _showStars = false;
    });
    Future.delayed(const Duration(milliseconds: 200), _speakInstruction);
  }

  void _selectAnswer(int answer) {
    if (_answered) return;
    final correct = answer == _question.count;

    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      if (correct) {
        _streak++;
        _score += 10 + (_streak >= 3 ? 5 : 0); // streak bonus
        _showStars = true;
        SoundUtil.playCorrect();
        context.read<ScoreProvider>().addScore(10);
      } else {
        _streak = 0;
        SoundUtil.playWrong();
      }
    });

    if (correct) {
      _starCtrl.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 1200), _nextQuestion);
    } else {
      Future.delayed(const Duration(milliseconds: 900), _nextQuestion);
    }
  }

  @override
  void dispose() {
    _starCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Difficulty selector ────────────────
        _buildDifficultyBar(),

        // ── Score row ─────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('⭐ $_score điểm',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              if (_streak >= 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('🔥 x$_streak', style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14,
                  )),
                ),
            ],
          ),
        ),

        // ── Instruction text ──────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Text(
            'Đếm xem có bao nhiêu ${_question.objectEmoji}?',
            style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // ── Objects display ───────────────────
        Expanded(
          flex: 3,
          child: _buildObjectGrid(),
        ),

        // ── Star animation ────────────────────
        if (_showStars) _buildStarBurst(),

        // ── Answer choices ────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Row(
            children: _question.choices.map((choice) {
              Color? bg;
              if (_answered && choice == _question.count) {
                bg = AppTheme.primaryGreen;
              } else if (_answered && choice == _selectedAnswer) {
                bg = Colors.red.shade300;
              }
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnswerButton(
                    label: '$choice',
                    backgroundColor: bg,
                    onTap: () => _selectAnswer(choice),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: CountDifficulty.values.map((d) {
          final cfg = _configs[d]!;
          final selected = d == _difficulty;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _difficulty = d;
                  _score = 0;
                  _streak = 0;
                });
                _nextQuestion();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? cfg.color : cfg.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${cfg.label}\n${cfg.min}–${cfg.max}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : cfg.color,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildObjectGrid() {
    final count = _question.count;
    // Determine best grid columns
    final cols = count <= 4 ? 2 : (count <= 6 ? 3 : 4);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: List.generate(count, (i) {
            // Staggered entrance delay
            return TweenAnimationBuilder<double>(
              key: ValueKey('${_question.objectEmoji}_$i'),
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 200 + i * 60),
              curve: Curves.elasticOut,
              builder: (ctx, v, child) => Transform.scale(
                scale: v,
                child: Text(
                  _question.objectEmoji,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: count <= 5 ? 40 : (count <= 8 ? 32 : 26),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStarBurst() {
    return AnimatedBuilder(
      animation: _starCtrl,
      builder: (ctx, _) {
        return SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final delay = i * 0.15;
              final t = (_starCtrl.value - delay).clamp(0.0, 1.0);
              return Transform.scale(
                scale: Curves.elasticOut.transform(t),
                child: Opacity(
                  opacity: t,
                  child: const Text('⭐', style: TextStyle(fontSize: 28)),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
