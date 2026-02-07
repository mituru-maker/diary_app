import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'core/constants.dart';

// 弾除けゲーム画面
class DodgeGamePage extends StatefulWidget {
  const DodgeGamePage({super.key});

  @override
  State<DodgeGamePage> createState() => _DodgeGamePageState();
}

class _DodgeGamePageState extends State<DodgeGamePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _gameController;
  List<Bullet> _bullets = [];
  double _playerX = 0.5;
  int _score = 0;
  int _highScore = 0;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _gameController = AnimationController(
      duration: const Duration(milliseconds: 16), // 60fps
      vsync: this,
    )..repeat();
    
    _gameController.addListener(_updateGame);
    _loadHighScore();
  }

  // ハイスコアを読み込む
  Future<void> _loadHighScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _highScore = prefs.getInt(AppConstants.dodgeGameHighScoreKey) ?? 0;
      });
    } catch (e) {
      setState(() {
        _highScore = 0;
      });
    }
  }

  // ハイスコアを保存
  Future<void> _saveHighScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppConstants.dodgeGameHighScoreKey, _highScore);
    } catch (e) {
      // 保存失敗時は何もしない
    }
  }

  @override
  void dispose() {
    _gameController.dispose();
    super.dispose();
  }

  void _updateGame() {
    if (_gameOver) return;

    setState(() {
      // 弾を追加（ランダムな位置と速度）
      if (_bullets.isEmpty || DateTime.now().millisecondsSinceEpoch % 30 == 0) {
        _bullets.add(Bullet(
          x: math.Random().nextDouble(),
          y: 0.0,
          speed: 0.01 + math.Random().nextDouble() * 0.02,
        ));
      }

      // 弾を移動
      for (int i = _bullets.length - 1; i >= 0; i--) {
        _bullets[i].y += _bullets[i].speed;
        
        // 画面外の弾を削除
        if (_bullets[i].y > 1.0) {
          _bullets.removeAt(i);
          _score++;
          continue;
        }

        // 当たり判定
        double dx = _bullets[i].x - _playerX;
        double dy = _bullets[i].y - 0.85; // プレイヤー位置
        double distance = math.sqrt(dx * dx + dy * dy);
        
        if (distance < 0.05) { // 当たり判定半径
          _gameOver = true;
          bool isNewRecord = false;
          
          // ハイスコア更新チェック
          if (_score > _highScore) {
            _highScore = _score;
            isNewRecord = true;
            _saveHighScore(); // 新記録を保存
          }
          
          _showGameOverDialog(isNewRecord);
        }
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_gameOver) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    
    setState(() {
      _playerX = details.localPosition.dx / size.width;
      _playerX = _playerX.clamp(0.05, 0.95); // 画面内に制限
    });
  }

  void _restartGame() {
    setState(() {
      _bullets.clear();
      _gameOver = false;
      _playerX = 0.5;
      _score = 0;
    });
  }

  void _showGameOverDialog(bool isNewRecord) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ゲームオーバー！',
                style: TextStyle(
                  color: Color(0xFF5D4E37),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isNewRecord) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B7355),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'New Record!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '今回のスコア',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF5D4E37),
                    ),
                  ),
                  Text(
                    '$_score',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B7355),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ベストスコア',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF5D4E37),
                    ),
                  ),
                  Text(
                    '$_highScore',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4C4B0),
                    ),
                  ),
                ],
              ),
              if (isNewRecord) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B7355).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '🎉 新記録達成！おめでとう！ 🎉',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8B7355),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
              },
              child: const Text(
                'もう一度',
                style: TextStyle(
                  color: Color(0xFF8B7355),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text(
                'ホームに戻る',
                style: TextStyle(
                  color: Color(0xFF5D4E37),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '弾除けゲーム',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5D4E37),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Color(0xFF5D4E37)),
          onPressed: () {
            Navigator.pop(context);
          },
          tooltip: 'ホームに戻る',
        ),
        backgroundColor: const Color(0xFFFDFCF0),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F6F0),
              Color(0xFFE8E0D5),
            ],
          ),
        ),
        child: Column(
          children: [
            // スコア表示
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'スコア: $_score',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D4E37),
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Best: ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD4C4B0),
                        ),
                      ),
                      Text(
                        '$_highScore',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B7355),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ゲーム画面
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: GestureDetector(
                    onPanUpdate: _onPanUpdate,
                    child: Container(
                      margin: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: DodgeGamePainter(
                          bullets: _bullets,
                          playerX: _playerX,
                          gameOver: _gameOver,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 弾のクラス
class Bullet {
  double x;
  double y;
  double speed;

  Bullet({
    required this.x,
    required this.y,
    required this.speed,
  });
}

// ゲーム描画用のCustomPainter
class DodgeGamePainter extends CustomPainter {
  final List<Bullet> bullets;
  final double playerX;
  final bool gameOver;

  DodgeGamePainter({
    required this.bullets,
    required this.playerX,
    required this.gameOver,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // プレイヤーを描画
    final playerPaint = Paint()
      ..color = gameOver ? Colors.grey : const Color(0xFF8B7355)
      ..style = PaintingStyle.fill;

    final playerCenter = Offset(playerX * size.width, size.height * 0.85);
    canvas.drawCircle(playerCenter, 20, playerPaint);

    // 弾を描画
    final bulletPaint = Paint()
      ..color = gameOver ? Colors.grey.shade400 : Colors.red.shade400
      ..style = PaintingStyle.fill;

    for (final bullet in bullets) {
      final bulletCenter = Offset(
        bullet.x * size.width,
        bullet.y * size.height,
      );
      canvas.drawCircle(bulletCenter, 8, bulletPaint);
    }

    // ゲームオーバー時のテキスト
    if (gameOver) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'GAME OVER',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4E37),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          size.height * 0.4,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
