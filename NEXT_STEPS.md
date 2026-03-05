# メンチン道場 — リリース準備手順書

> **前提**: コード完成済み、バグ修正16件適用済み、`flutter analyze` No issues、debug APKビルド成功済み。

---

## 1. Android実機テスト

### 1-1. USBデバッグを有効にする
1. 端末の「設定」→「端末情報」→「ビルド番号」を**7回タップ** → 開発者モードON
2. 「設定」→「開発者向けオプション」→「**USBデバッグ**」をON
3. USB-CケーブルでPCに接続
4. 端末に「USBデバッグを許可しますか？」ダイアログが出たら「OK」

### 1-2. 接続確認
```bash
cd C:\Users\haman\Downloads\チンイツ\chinitsu_app
C:\Users\haman\.vscode\extensions\dart-code.flutter-3.128.0\flutter\bin\flutter.bat devices
```
→ 端末名（例: `Pixel 7 (mobile)`）が表示されればOK

### 1-3. アプリをインストール・実行
```bash
# 方法A: 直接実行（ホットリロード可能）
C:\Users\haman\.vscode\extensions\dart-code.flutter-3.128.0\flutter\bin\flutter.bat run

# 方法B: ビルド済みAPKをインストール
adb install build\app\outputs\flutter-apk\app-debug.apk
```

### 1-4. テスト項目チェックリスト

#### ホーム画面
- [ ] タイトル「清一色道場」が表示される
- [ ] 現在の段位（無級）とRP（0）が表示される
- [ ] マンズ/ピンズ/ソーズの切り替えが動作する
- [ ] プライバシーポリシー・利用規約リンクが開く
- [ ] プロフィールアイコン（右上）が反応する

#### れんしゅうモード
- [ ] 手牌13枚が正常表示（牌画像が読み込まれる）
- [ ] 1-9の待ち選択ボタンがタップでトグルする
- [ ] 「テンパイではない」ボタンが動作する
- [ ] **何も選択せずに「答え合わせ」を押すと反応しない**（BUG-16修正確認）
- [ ] 答え合わせ → 正解/不正解のフィードバック表示
- [ ] 正解時: 緑テキスト + スコア表示
- [ ] 不正解時: 赤テキスト + 正解の待ち表示
- [ ] 「次の問題→」で新しい手牌が表示される
- [ ] 「ホームに戻る」でホーム画面に戻る

#### タイムアタック（TA）モード
- [ ] 2:00からカウントダウン開始
- [ ] **ローディング中にタイマーが減っていない**（BUG-22修正確認）
- [ ] タイマー0で自動的に結果画面へ遷移
- [ ] TA中の全問で解答→次の問題が正常動作

#### 結果画面
- [ ] スコア・正解数・問題数が正しく表示
- [ ] TA時: RP変動（+XX / -XX）と基準スコアが表示
- [ ] Xシェアボタンでツイート画面が開く
- [ ] **「もう一度」で新しいゲームセッションが開始される**（BUG-02修正確認）
- [ ] 「ホームに戻る」でホーム画面に戻る

#### プロフィール
- [ ] 段位・RP・進捗バーが表示
- [ ] 累計統計が正しく更新される
- [ ] バッジ一覧が表示される（初回は全て「?」）
- [ ] Xシェアボタンが動作する

#### データ永続化
- [ ] アプリを完全終了→再起動後にデータが保持されている
- [ ] 段位・RP・バッジ・統計すべて保持

#### クォータ（広告）
- [ ] 50問プレイ後にアップグレード画面が表示される
- [ ] 「動画を見て続ける」ボタンが表示される（テスト広告が表示される）
- [ ] 広告視聴後に追加プレイが可能になる

#### レイアウト確認
- [ ] 画面が縦向き固定になっている
- [ ] 小さい端末（5インチ程度）で文字やボタンが切れない
- [ ] 大きい端末（6.5インチ+）でレイアウトが崩れない
- [ ] ノッチ/パンチホール端末でSafeArea内に収まっている

---

## 2. アプリアイコン設定

### 2-1. アイコン画像の準備
Canvaで生成したアイコンをPNG（1024x1024px）でエクスポート済み。

### 2-2. プロジェクトに配置
```bash
# アイコン用ディレクトリ作成
mkdir -p chinitsu_app/assets/icon/

# ダウンロードしたPNGをコピー
cp ダウンロードしたアイコン.png chinitsu_app/assets/icon/app_icon.png
```

### 2-3. flutter_launcher_icons の設定
`chinitsu_app/pubspec.yaml` の末尾に追加:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.0

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#F7F1E3"
  adaptive_icon_foreground: "assets/icon/app_icon.png"
```

### 2-4. アイコン生成
```bash
cd C:\Users\haman\Downloads\チンイツ\chinitsu_app
C:\Users\haman\.vscode\extensions\dart-code.flutter-3.128.0\flutter\bin\flutter.bat pub run flutter_launcher_icons
```
→ Android/iOS両方のアイコンが自動生成される

---

## 3. AdMob本番設定

### 3-1. AdMobアカウント作成
1. https://admob.google.com/ にアクセス
2. Googleアカウントでログイン
3. 利用規約に同意 → AdMobアカウント作成完了

### 3-2. アプリ登録
1. 左メニュー「アプリ」→「アプリを追加」
2. **Android版**:
   - プラットフォーム: Android
   - アプリ名: `清一色道場`
   - 「アプリはアプリストアに掲載されていますか？」→「いいえ」（初回）
   - 作成後に表示される**アプリID**をメモ（`ca-app-pub-XXXXXXX~YYYYYYY` 形式）
3. 同じ手順で**iOS版**も登録（iOS対応する場合）

### 3-3. リワード広告ユニット作成
1. 登録したAndroidアプリを選択
2. 「広告ユニット」→「広告ユニットを追加」→「**リワード**」を選択
3. 広告ユニット名: `chinitsu_rewarded`
4. 作成後に表示される**広告ユニットID**をメモ（`ca-app-pub-XXXXXXX/ZZZZZZZ` 形式）
5. iOS版でも同様に作成

### 3-4. コード修正（3ファイル）

#### ファイル1: `lib/services/ad_service.dart`
テスト広告IDを本番IDに差し替え:
```dart
// ★ 17-23行目あたりを変更
String get _rewardedAdUnitId {
  if (Platform.isAndroid) {
    return 'ca-app-pub-あなたのID/Android広告ユニットID';  // ← ここを変更
  } else if (Platform.isIOS) {
    return 'ca-app-pub-あなたのID/iOS広告ユニットID';      // ← ここを変更
  }
  throw UnsupportedError('Unsupported platform');
}
```

#### ファイル2: `android/app/src/main/AndroidManifest.xml`
`<application>` タグ内に追加:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-あなたのアプリID"/>
```
※ 広告ユニットIDではなく**アプリID**（`~`区切りの方）を使う

#### ファイル3: `ios/Runner/Info.plist`（iOS対応時のみ）
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-あなたのアプリID</string>
```

### 3-5. テスト確認
- **本番IDに差し替えた後も、テスト端末を登録すればテスト広告が表示される**
- AdMob管理画面 →「設定」→「テスト端末」→ 端末のAdvertising IDを登録
- または `AdRequest(testDeviceIds: ['あなたの端末ID'])` をコードに追加

---

## 4. スクリーンショット撮影

### 4-1. 必要な画像

| ストア | 必須枚数 | サイズ |
|--------|----------|--------|
| Google Play | 最低2枚（推奨4-8枚） | 16:9 or 9:16 |
| App Store | 各サイズ最低1枚 | 6.7" (1290x2796) + 5.5" (1242x2208) |

### 4-2. 撮影する画面（推奨4枚）
1. **ホーム画面** — タイトル・段位表示が見える状態
2. **ゲーム画面** — 手牌13枚＋待ち選択ボタンが押された状態
3. **結果画面** — 高スコアでRP+が表示されている状態
4. **プロフィール画面** — いくつかのバッジが獲得済みの状態

### 4-3. 撮影方法
```bash
# エミュレータのスクリーンショット
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png screenshot.png

# または、端末の電源ボタン+音量下ボタン同時押し
```

### 4-4. 加工のヒント
- Canvaの「スマホモックアップ」テンプレートにスクリーンショットをはめ込むと見栄えが良い
- キャッチコピーを追加: 「清一色の待ち、瞬時に見抜く」等

---

## 5. Google Playリリースビルド＋申請

### 5-1. Google Play Console登録
1. https://play.google.com/console にアクセス
2. Googleアカウントでログイン
3. **デベロッパー登録料 $25（一回限り）** を支払い
4. デベロッパー名・連絡先を入力

### 5-2. 署名用キーストア作成（初回のみ）
```bash
keytool -genkey -v -keystore C:\Users\haman\chinitsu-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias chinitsu
```
→ パスワード・名前等を入力（**パスワードは忘れずにメモ！紛失するとアプリ更新不可**）

### 5-3. key.properties 作成
`chinitsu_app/android/key.properties` を新規作成:
```properties
storePassword=入力したパスワード
keyPassword=入力したパスワード
keyAlias=chinitsu
storeFile=C:\\Users\\haman\\chinitsu-release-key.jks
```
**⚠ このファイルはGitにコミットしないこと！ `.gitignore` に追加推奨**

### 5-4. build.gradle 修正
`chinitsu_app/android/app/build.gradle` の先頭付近に追加:
```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

`buildTypes` セクションを変更:
```groovy
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
    }
}
```

### 5-5. リリースビルド
```bash
cd C:\Users\haman\Downloads\チンイツ\chinitsu_app
C:\Users\haman\.vscode\extensions\dart-code.flutter-3.128.0\flutter\bin\flutter.bat build appbundle --release
```
→ `build/app/outputs/bundle/release/app-release.aab` が生成される

### 5-6. Google Play Consoleでアプリ作成＋提出
1. 「アプリを作成」→ 以下を入力:
   - アプリ名: `清一色道場 - チンイツ待ち当て練習`
   - デフォルト言語: 日本語
   - アプリ or ゲーム: ゲーム
   - 無料 or 有料: 無料
2. 「ダッシュボード」のセットアップガイドに従って情報入力:
   - **ストアの掲載情報**: 説明文・スクリーンショット・アイコン（512x512版）
   - **コンテンツのレーティング**: 質問票に回答（ギャンブル要素なし→全年齢）
   - **ターゲットユーザー**: 13歳以上（麻雀アプリのため）
   - **プライバシーポリシー**: URL入力（GitHub Pages等にホスティング）
   - **データセーフティ**:
     - 広告ID収集: はい（AdMob）
     - 位置情報: いいえ
     - 個人情報: いいえ
3. 「製品版」→「新しいリリースを作成」→ AABファイルをアップロード
4. 「審査に提出」

### 5-7. 審査について
- 通常1-3営業日で審査完了
- 初回アプリは少し長くなることがある
- リジェクトされた場合は理由を確認して修正→再提出

---

## 6. プライバシーポリシーのホスティング

### Google Play / App Storeの両方で必須
ストア申請時にプライバシーポリシーのURLが必要。

### 方法A: GitHub Pages（無料・推奨）
1. GitHubリポジトリを作成（例: `chinitsu-privacy-policy`）
2. `index.html` にプライバシーポリシーの内容を記載
   - アプリ内の `legal_screen.dart` の `privacyPolicyJa` テキストをHTMLに変換
3. Settings → Pages → Source: main branch → Save
4. URLが発行される（例: `https://username.github.io/chinitsu-privacy-policy/`）

### 方法B: Notion（簡単）
1. Notionでプライバシーポリシーのページを作成
2. 「Share」→「Publish to web」でURLを取得

### 記載URL（2箇所で使用）
- Google Play Console の「ストアの掲載情報」→「プライバシーポリシー」
- App Store Connect の「App情報」→「プライバシーポリシーURL」

---

## 7. iOS対応（Mac環境が必要）

### 7-1. 前提条件
- macOS + Xcode インストール済み
- Apple Developer Program 登録済み（**年間 $99**）
- CocoaPods インストール済み（`sudo gem install cocoapods`）

### 7-2. Mac上でのセットアップ
```bash
# プロジェクトをMacに転送（USB/クラウド/Git）
cd chinitsu_app
flutter pub get

# iOS依存関係の解決
cd ios && pod install && cd ..

# iOSビルド確認
flutter build ios --debug
```

### 7-3. Xcode設定
```bash
open ios/Runner.xcworkspace
```
1. 左のファイルツリーで「Runner」を選択
2. 「Signing & Capabilities」タブ:
   - Team: あなたのApple Developerチームを選択
   - Bundle Identifier: `com.chinitsudojo.chinitsuDojo`（変更不要）
3. 「General」タブ:
   - Deployment Target: `13.0` 以上

### 7-4. TestFlight でベータテスト
1. https://appstoreconnect.apple.com でアプリを作成
2. Xcodeから Archive → Distribute App → App Store Connect
3. TestFlightでテスターを招待してテスト
4. 問題なければ審査提出

### 7-5. App Store 審査提出
1. スクリーンショット（6.7" + 5.5"）をアップロード
2. 説明文（NEXT_STEPS.md §3-3と同じ内容）を入力
3. プライバシーポリシーURL入力
4. Privacy Nutrition Labels設定:
   - Data Used to Track You: Advertising Data（AdMob使用のため）
   - Data Linked to You: なし
5. 審査提出

---

## 8. GDPR/UMP対応（海外配信する場合のみ）

### 必要な場合
- EU圏向けに配信する場合のみ（日本国内のみなら不要）

### 手順
1. AdMob管理画面 → 「プライバシーとメッセージ」→ GDPR同意メッセージ作成
2. `google_mobile_ads` パッケージにUMP SDK同梱済み
3. `lib/main.dart` の `_init()` 内に追加:
   ```dart
   final params = ConsentRequestParameters();
   ConsentInformation.instance.requestConsentInfoUpdate(params, () {
     ConsentInformation.instance.isConsentFormAvailable().then((available) {
       if (available) ConsentForm.loadAndShowConsentFormIfRequired((error) {});
     });
   }, (error) {});
   ```
4. テスト: AdMob設定でデバッグ地理情報をEEAに設定して動作確認

---

## チェックリスト形式の全体進捗

| # | タスク | 状態 | 必要なもの |
|---|--------|------|-----------|
| 1 | コード完成+バグ修正 | ✅ 完了 | — |
| 2 | アプリアイコン作成 | 🔄 Canvaで生成済み→選択待ち | — |
| 3 | Android実機テスト | ⬜ 未着手 | Android端末+USB |
| 4 | AdMobアカウント設定 | ⬜ 未着手 | Googleアカウント |
| 5 | 広告IDをコードに反映 | ⬜ 未着手 | AdMob設定後 |
| 6 | プライバシーポリシーURL | ⬜ 未着手 | GitHub/Notion |
| 7 | スクリーンショット撮影 | ⬜ 未着手 | 実機テスト後 |
| 8 | キーストア作成 | ⬜ 未着手 | — |
| 9 | リリースビルド | ⬜ 未着手 | キーストア後 |
| 10 | Google Play Console登録 | ⬜ 未着手 | $25 |
| 11 | ストア申請 | ⬜ 未着手 | 全て完了後 |
| 12 | iOS対応 | ⬜ 未着手 | Mac + $99/年 |
| 13 | GDPR対応 | ⬜ 海外配信時のみ | EU配信時 |
