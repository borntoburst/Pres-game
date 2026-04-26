import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/app_theme.dart';
import '../utils/score_provider.dart';
import '../utils/sound_util.dart';
import '../widgets/animated_feedback_widget.dart';

// ═══════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════

class _Node {
  final int id;       // flat index: row * gridSize + col
  final int pairId;
  final int row;
  final int col;
  const _Node({required this.id, required this.pairId, required this.row, required this.col});
}

class _DrawnPath {
  final int pairId;
  final Color color;
  final List<Offset> points;
  const _DrawnPath({required this.pairId, required this.color, required this.points});

  _DrawnPath withPoint(Offset p) =>
      _DrawnPath(pairId: pairId, color: color, points: [...points, p]);
}

// ═══════════════════════════════════════════════════════
// LEVEL GENERATOR
// ═══════════════════════════════════════════════════════

class _LevelData {
  final int gridSize;
  final int pairCount;
  final List<_Node> nodes;
  final List<Color> pairColors;
  const _LevelData({required this.gridSize, required this.pairCount, required this.nodes, required this.pairColors});
}

_LevelData _buildLevel(int level) {
  // Scale grid and pairs with level
  final int gridSize = level == 1 ? 2 : (level == 2 ? 3 : 4);
  final int pairCount = level == 1 ? 1 : (level == 2 ? 2 : min(level, 4));

  final colors = [
    AppTheme.primaryOrange,
    AppTheme.primaryBlue,
    AppTheme.primaryPink,
    AppTheme.primaryPurple,
    AppTheme.primaryGreen,
  ].sublist(0, min(pairCount, 5));

  final rng = Random(level * 31 + 7);
  final positions = List.generate(gridSize * gridSize, (i) => i)..shuffle(rng);

  final nodes = <_Node>[];
  for (int p = 0; p < pairCount; p++) {
    final a = positions[p * 2];
    final b = positions[p * 2 + 1];
    nodes.add(_Node(id: a, pairId: p, row: a ~/ gridSize, col: a % gridSize));
    nodes.add(_Node(id: b, pairId: p, row: b ~/ gridSize, col: b % gridSize));
  }

  return _LevelData(gridSize: gridSize, pairCount: pairCount, nodes: nodes, pairColors: colors);
}

// ═══════════════════════════════════════════════════════
// GAME WIDGET
// ═══════════════════════════════════════════════════════

class ConnectPairsGame extends StatefulWidget {
  const ConnectPairsGame({super.key});
  @override
  State<ConnectPairsGame> createState() => _ConnectPairsGameState();
}

class _ConnectPairsGameState extends State<ConnectPairsGame>
    with TickerProviderStateMixin {

  // ── State ─────────────────────────────────────────────
  int _level = 1;
  late _LevelData _levelData;
  final Map<int, _DrawnPath> _done = {};   // pairId → completed path
  _DrawnPath? _active;                      // path being drawn right now
  int? _activeStartId;                      // which node the drag started on
  bool _showError = false;
  bool _levelComplete = false;

  /// Node center positions computed from layout; keyed by node.id.
  final Map<int, Offset> _centers = {};

  late AnimationController _errorCtrl;
  late AnimationController _completionCtrl;

  // ── Init / dispose ────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _errorCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _completionCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _loadLevel(1);
  }

  @override
  void dispose() {
    _errorCtrl.dispose();
    _completionCtrl.dispose();
    super.dispose();
  }

  void _loadLevel(int lvl) {
    _level = lvl;
    _levelData = _buildLevel(lvl);
    _done.clear();
    _active = null;
    _activeStartId = null;
    _showError = false;
    _levelComplete = false;
    _centers.clear();
    _completionCtrl.reset();
    SoundUtil.speakInstruction('Nối các bong bóng cùng màu!');
  }

  // ── Hit testing ───────────────────────────────────────
  _Node? _nodeAt(Offset pos) {
    const double r = 34;
    for (final n in _levelData.nodes) {
      final c = _centers[n.id];
      if (c != null && (c - pos).distance <= r) return n;
    }
    return null;
  }

  // ── Gesture handlers ──────────────────────────────────
  void _onPanStart(DragStartDetails d) {
    final hit = _nodeAt(d.localPosition);
    if (hit == null) return;
    if (_done.containsKey(hit.pairId)) return; // already connected

    setState(() {
      _showError = false;
      _activeStartId = hit.id;
      _active = _DrawnPath(
        pairId: hit.pairId,
        color: _levelData.pairColors[hit.pairId],
        points: [_centers[hit.id]!],
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_active == null) return;
    setState(() {
      _active = _active!.withPoint(d.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails d) {
    final active = _active;
    if (active == null) return;

    final endHit = _nodeAt(active.points.last);
    final valid = endHit != null &&
        endHit.pairId == active.pairId &&
        endHit.id != _activeStartId;

    if (valid && !_collides(active)) {
      // Snap final point to the target node center
      final snapped = _DrawnPath(
        pairId: active.pairId,
        color: active.color,
        points: [
          ...active.points.sublist(0, active.points.length - 1),
          _centers[endHit.id]!,
        ],
      );
      _done[active.pairId] = snapped;
      SoundUtil.playCorrect();

      final allDone = _done.length == _levelData.pairCount;
      setState(() {
        _active = null;
        _activeStartId = null;
        _levelComplete = allDone;
      });

      if (allDone) {
        SoundUtil.playComplete();
        context.read<ScoreProvider>().addScore(50 + _level * 10);
        _completionCtrl.forward();
      }
    } else {
      _flashError();
    }
  }

  void _flashError() {
    SoundUtil.playWrong();
    setState(() {
      _active = null;
      _activeStartId = null;
      _showError = true;
    });
    _errorCtrl.forward(from: 0).then((_) {
      if (mounted) setState(() => _showError = false);
    });
  }

  // ── Overlap check ─────────────────────────────────────
  /// Samples points along both paths and checks for proximity collisions.
  bool _collides(_DrawnPath candidate) {
    const double threshold = 16;
    const int step = 4;
    for (final existing in _done.values) {
      if (existing.pairId == candidate.pairId) continue;
      final a = candidate.points;
      final b = existing.points;
      for (int i = 0; i < a.length; i += step) {
        for (int j = 0; j < b.length; j += step) {
          if ((a[i] - b[j]).distance < threshold) return true;
        }
      }
    }
    return false;
  }

  // ═════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _topBar(),
        _banner(),
        const SizedBox(height: 6),
        Expanded(child: _board()),
        if (_levelComplete)
          AnimatedFeedbackWidget(
            controller: _completionCtrl,
            onNext: () => setState(() => _loadLevel(_level + 1)),
            onReplay: () => setState(() => _loadLevel(_level)),
            message: 'Tuyệt vời! 🎈',
            points: 50 + _level * 10,
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Top bar ───────────────────────────────────────────
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        children: [
          // Pair progress circles
          for (int p = 0; p < _levelData.pairCount; p++) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: _done.containsKey(p)
                    ? _levelData.pairColors[p]
                    : _levelData.pairColors[p].withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(color: _levelData.pairColors[p], width: 2),
              ),
              child: _done.containsKey(p)
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
          const Spacer(),
          Text('Màn $_level',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _loadLevel(_level)),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: AppTheme.primaryBlue, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner ────────────────────────────────────────────
  Widget _banner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: _showError
            ? Colors.red.withOpacity(0.08)
            : AppTheme.primaryOrange.withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _showError
              ? Colors.red.withOpacity(0.35)
              : AppTheme.primaryOrange.withOpacity(0.25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_showError ? '❌' : '🎈', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            _showError
                ? 'Đường bị chồng hoặc sai cặp! Thử lại!'
                : 'Nối các bong bóng cùng màu nhau!',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _showError ? Colors.red.shade600 : AppTheme.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }

  // ── Board ─────────────────────────────────────────────
  Widget _board() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: AspectRatio(
        aspectRatio: 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: LayoutBuilder(builder: (ctx, cst) {
            final sz = cst.maxWidth;
            final cell = sz / _levelData.gridSize;

            // Recompute centers each layout pass
            for (final n in _levelData.nodes) {
              _centers[n.id] = Offset((n.col + 0.5) * cell, (n.row + 0.5) * cell);
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(children: [
                  // Grid
                  CustomPaint(
                    size: Size(sz, sz),
                    painter: _GridPainter(gridSize: _levelData.gridSize, cellSize: cell),
                  ),
                  // Completed paths
                  for (final p in _done.values)
                    CustomPaint(size: Size(sz, sz), painter: _PathPainter(path: p, alpha: 255)),
                  // Active path
                  if (_active != null)
                    CustomPaint(size: Size(sz, sz), painter: _PathPainter(path: _active!, alpha: 170)),
                  // Balloons
                  for (final n in _levelData.nodes) _balloon(n, cell),
                ]),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Balloon node ──────────────────────────────────────
  Widget _balloon(_Node node, double cellSize) {
    final center = _centers[node.id];
    if (center == null) return const SizedBox.shrink();

    final color = _levelData.pairColors[node.pairId];
    final connected = _done.containsKey(node.pairId);
    final isActive = _active?.pairId == node.pairId;
    final r = cellSize * 0.22;

    return Positioned(
      left: center.dx - r,
      top: center.dy - r,
      width: r * 2,
      height: r * 2,
      child: AnimatedScale(
        scale: connected ? 1.2 : (isActive ? 1.08 : 1.0),
        duration: const Duration(milliseconds: 250),
        curve: Curves.elasticOut,
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [color.withOpacity(0.85), color],
              center: const Alignment(-0.35, -0.35),
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.85), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(connected ? 0.6 : 0.3),
                blurRadius: connected ? 14 : 7,
                spreadRadius: connected ? 3 : 0,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: connected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
              : Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.white54, shape: BoxShape.circle,
                  ),
                ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════

class _GridPainter extends CustomPainter {
  final int gridSize;
  final double cellSize;
  const _GridPainter({required this.gridSize, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFFEEEEF5)
      ..strokeWidth = 1;

    for (int i = 1; i < gridSize; i++) {
      canvas.drawLine(Offset(i * cellSize, 0), Offset(i * cellSize, size.height), line);
      canvas.drawLine(Offset(0, i * cellSize), Offset(size.width, i * cellSize), line);
    }

    final dot = Paint()..color = const Color(0xFFD4D4E8);
    for (int r = 0; r <= gridSize; r++) {
      for (int c = 0; c <= gridSize; c++) {
        canvas.drawCircle(Offset(c * cellSize, r * cellSize), 2.5, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter o) => o.gridSize != gridSize;
}

class _PathPainter extends CustomPainter {
  final _DrawnPath path;
  final int alpha; // 0–255

  const _PathPainter({required this.path, required this.alpha});

  @override
  void paint(Canvas canvas, Size size) {
    if (path.points.length < 2) return;

    final p = _buildPath();

    // Glow
    canvas.drawPath(
      p,
      Paint()
        ..color = path.color.withAlpha((alpha * 0.28).round())
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    // Main
    canvas.drawPath(
      p,
      Paint()
        ..color = path.color.withAlpha(alpha)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    // Highlight
    canvas.drawPath(
      p,
      Paint()
        ..color = Colors.white.withAlpha((alpha * 0.3).round())
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  Path _buildPath() {
    final p = Path()..moveTo(path.points.first.dx, path.points.first.dy);
    for (int i = 1; i < path.points.length; i++) {
      p.lineTo(path.points[i].dx, path.points[i].dy);
    }
    return p;
  }

  @override
  bool shouldRepaint(_PathPainter o) =>
      o.path.points.length != path.points.length || o.alpha != alpha;
}
