import 'package:flutter/material.dart';
import 'dart:math' as math;

// 弾除けゲーム画面
class DodgeGamePage extends StatefulWidget {
  const DodgeGamePage({super.key});

  @override
  State<DodgeGamePage> createState() => _DodgeGamePageState();
}

class _DodgeGamePageState extends State<DodgeGamePage>
    with TickerProviderStateMixin {
  late AnimationController _gameController;
  List<Bullet> _bullets = [];
  bool _gameOver = false;
  double _playerX = 0.5; // 0.0 - 1.0 の範囲
  int _score = 0;
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _gameController = AnimationController(
      duration: const Duration(milliseconds: 16), // 60fps
      vsync: this,
    )..repeat();
    
    _gameController.addListener(_updateGame);
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
          if (_score > _highScore) {
            _highScore = _score;
          }
          _showGameOverDialog();
        }
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_gameOver) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    
    setState(() {
      _playerX = (details.localPosition.dx / size.width).clamp(0.0, 1.0);
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

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'ゲームオーバー！',
            style: TextStyle(
              color: Color(0xFF5D4E37),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'スコア: $_score',
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFF8B7355),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ハイスコア: $_highScore',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFFD4C4B0),
                ),
              ),
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
                  Text(
                    'ハイスコア: $_highScore',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B7355),
                    ),
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
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CustomPaint(
                          painter: DodgeGamePainter(
                            bullets: _bullets,
                            playerX: _playerX,
                            gameOver: _gameOver,
                          ),
                          child: Container(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 操作説明
            Container(
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                '指で左右にドラッグして弾を避けよう！',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8B7355),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 弾クラス
class Bullet {
  double x;
  double y;
  final double speed;
  
  Bullet({
    required this.x,
    required this.y,
    required this.speed,
  });
}

// ゲーム描画クラス
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
    // 背景
    final bgPaint = Paint()
      ..color = const Color(0xFF2C2416)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    
    // グリッド線（優しい雰囲気）
    final gridPaint = Paint()
      ..color = const Color(0xFF3D3426).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    for (int i = 0; i < 10; i++) {
      double y = (size.height / 10) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
    
    // プレイヤー（優しい青い円）
    final playerPaint = Paint()
      ..color = gameOver ? Colors.grey.withOpacity(0.7) : const Color(0xFF8B7355)
      ..style = PaintingStyle.fill;
    
    final playerRadius = size.width * 0.06;
    canvas.drawCircle(
      Offset(playerX * size.width, size.height * 0.85),
      playerRadius,
      playerPaint,
    );
    
    // プレイヤーの光沢効果
    if (!gameOver) {
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(playerX * size.width - playerRadius * 0.3, size.height * 0.85 - playerRadius * 0.3),
        playerRadius * 0.3,
        highlightPaint,
      );
    }
    
    // 弾（優しい赤い円）
    final bulletPaint = Paint()
      ..color = const Color(0xFFD4A574)
      ..style = PaintingStyle.fill;
    
    final bulletRadius = size.width * 0.025;
    for (final bullet in bullets) {
      canvas.drawCircle(
        Offset(bullet.x * size.width, bullet.y * size.height),
        bulletRadius,
        bulletPaint,
      );
      
      // 弾の光沢効果
      final bulletHighlight = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(bullet.x * size.width - bulletRadius * 0.3, bullet.y * size.height - bulletRadius * 0.3),
        bulletRadius * 0.2,
        bulletHighlight,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
