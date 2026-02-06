# 1行日記アプリ - デプロイ手順

## 概要

このアプリはFlutter Webで構築された1行日記アプリです。パステル・ミニマルデザインで、データはブラウザのローカルストレージに保存されます。

## デプロイ方法

### Windows環境でのデプロイ

#### 方法1: バッチファイルを使用（推奨）
```cmd
deploy_web.bat
```

#### 方法2: PowerShellスクリプトを使用
```powershell
.\deploy_web.ps1
```

#### 方法3: 手動実行
```cmd
# 1. 依存関係をインストール
flutter pub get

# 2. Webアプリをビルド
flutter build web --base-href "/diary_app/" --web-renderer canvaskit

# 3. docsフォルダにコピー
xcopy "build\web\*" "docs\" /E /I /Y

# 4. ビルドフォルダをクリーンアップ
rmdir /S /Q "build\web"
```

### ローカルでのテスト

デプロイ後にローカルでテストする場合：

```cmd
# docsフォルダでHTTPサーバーを起動
cd docs
python -m http.server 8000

# ブラウザで以下のURLにアクセス
# http://localhost:8000/diary_app/
```

## GitHub Pagesへのデプロイ

1. このリポジトリをGitHubにプッシュ
2. GitHubリポジトリのSettingsに移動
3. "Pages"セクションで以下を設定：
   - Source: Deploy from a branch
   - Branch: main (またはメインブランチ)
   - Folder: /docs
4. "Save"をクリック
5. 数分後に `https://[username].github.io/dairy_app/diary_app/` でアクセス可能

## 機能

- ✅ 1行日記の入力と保存
- ✅ 日付表示（YYYY/MM/DD形式）
- ✅ 新しい順のリスト表示
- ✅ 左スワイプでの削除（ゴミ箱アイコン付き）
- ✅ データ永続化（shared_preferences）
- ✅ パステル・ミニマルデザイン
- ✅ エラー防止策（初期化エラー対策、Webビルド対応）

## 技術仕様

- **フレームワーク**: Flutter 3.6.0+
- **データ保存**: shared_preferences
- **デザイン**: Material 3 + カスタムパステルカラー
- **Webレンダラー**: CanvasKit（高品質な描画）
- **ベースURL**: `/diary_app/`

## カラーテーマ

- 背景: `#FDFCF0` (落ち着いたベージュ)
- メインカラー: `#8B7355` (温かいブラウン)
- テキストカラー: `#5D4E37` (濃いブラウン)
- アクセントカラー: `#D4C4B0` (ライトブラウン)

## エラー防止策

- `late`変数を避け、`initState`で確実に初期化
- `dart:async`を含め、Webビルドに必要なライブラリを網羅
- `mounted`チェックでウィジェット生存確認
- 例外処理でクラッシュを防止
- `dispose`でリソースを適切に解放
