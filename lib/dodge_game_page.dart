import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:math' as math;
import 'dart:async';

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
  String _aiCommentary = '';
  bool _isLoadingCommentary = false;
  String _apiKey = '';

  @override
  void initState() {
    super.initState();
    _gameController = AnimationController(
      duration: const Duration(milliseconds: 16), // 60fps
      vsync: this,
    )..repeat();
    
    _gameController.addListener(_updateGame);
    _loadHighScore();
    _loadApiKey();
  }

  // APIキーを読み込む
  Future<void> _loadApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _apiKey = prefs.getString('gemini_api_key') ?? '';
      });
    } catch (e) {
      setState(() {
        _apiKey = '';
      });
    }
  }

  // APIキーを保存
  Future<void> _saveApiKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gemini_api_key', key);
      setState(() {
        _apiKey = key;
      });
    } catch (e) {
      // 保存失敗時は何もしない
    }
  }

  // ハイスコアを読み込む
  Future<void> _loadHighScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _highScore = prefs.getInt('dodge_game_high_score') ?? 0;
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
      await prefs.setInt('dodge_game_high_score', _highScore);
    } catch (e) {
      // 保存失敗時は何もしない
    }
  }

  // APIキー設定ダイアログを表示
  void _showApiKeyDialog() {
    final TextEditingController controller = TextEditingController();
    controller.text = _apiKey;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings, color: Color(0xFF8B7355)),
              SizedBox(width: 8),
              Text(
                'APIキー設定',
                style: TextStyle(
                  color: Color(0xFF5D4E37),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gemini APIキーを入力してください',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5D4E37),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: true, // パスワード形式（伏せ字）
                decoration: InputDecoration(
                  hintText: 'AIza...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD4C4B0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD4C4B0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF8B7355)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5D4E37),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '※APIキーは安全に保存されます',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFD4C4B0),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'キャンセル',
                style: TextStyle(
                  color: Color(0xFF5D4E37),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _saveApiKey(controller.text);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('APIキーを保存しました'),
                    backgroundColor: Color(0xFF8B7355),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B7355),
                foregroundColor: Colors.white,
              ),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  // AI実況を生成
  Future<void> _generateAICommentary(int score, int highScore) async {
    if (_apiKey.isEmpty) {
      setState(() {
        _aiCommentary = '設定からAPIキーを入力すると、AI実況が楽しめます！';
        _isLoadingCommentary = false;
      });
      return;
    }

    setState(() {
      _isLoadingCommentary = true;
      _aiCommentary = '';
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final prompt = '今回のスコアは$score、最高記録は$highScoreです。短くユニークな実況を1つ生成して';
      
      // タイムアウト設定（10秒）
      final response = await model.generateContent([Content.text(prompt)])
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('通信がタイムアウトしました', const Duration(seconds: 10));
            },
          );
      
      if (response.text != null) {
        setState(() {
          _aiCommentary = 'AI実況：${response.text!.trim()}';
        });
      } else {
        setState(() {
          _aiCommentary = 'AI実況：応答がありませんでした';
        });
      }
    } on TimeoutException catch (e) {
      setState(() {
        _aiCommentary = 'AI実況：通信がタイムアウトしました。ネット接続やAPIキーを確認してください';
      });
      print('AI実況タイムアウトエラー: $e');
    } catch (e) {
      setState(() {
        _aiCommentary = 'AI実況：エラー詳細: ${e.toString()}';
      });
      print('AI実況エラー詳細: $e');
    } finally {
      setState(() {
        _isLoadingCommentary = false;
      });
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
          
          // AI実況を生成
          _generateAICommentary(_score, _highScore);
          
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
              const SizedBox(height: 16),
              // AI実況表示
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F6F0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD4C4B0)),
                ),
                child: _isLoadingCommentary
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B7355)),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'AI実況生成中...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8B7355),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _aiCommentary.isNotEmpty
                            ? _aiCommentary
                            : 'AI実況：準備中...',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5D4E37),
                        ),
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              icon: Icon(
                _apiKey.isEmpty ? Icons.settings_outlined : Icons.settings,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                _apiKey.isEmpty ? 'AI設定' : 'AI設定済',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: _showApiKeyDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: _apiKey.isEmpty 
                    ? const Color(0xFF8B7355).withOpacity(0.7)
                    : const Color(0xFF8B7355),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
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
            // APIキー未設定時の案内
            if (_apiKey.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B7355).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF8B7355).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF8B7355),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: const Text(
                        'AI実況を楽しむには、右上の「AI設定」からAPIキーを入力してください',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8B7355),
                          fontWeight: FontWeight.w500,
                        ),
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
