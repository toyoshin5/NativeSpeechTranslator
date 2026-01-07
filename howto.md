

# NativeSpeechTranslator 仕様書

## 1. プロジェクト概要

### 1.1 目的

Mac上のシステム音声（Zoom等）をリアルタイムでキャプチャし、macOSネイティブの最新AI技術を用いて「文字起こし」と「翻訳」を同時並行で行うアプリケーションを開発する。

### 1.2 開発の指針（重要）

本プロジェクトで使用する `SpeechAnalyzer` および `FoundationModels` は、**macOS 26 世代の非常に新しい技術**である。
そのため、実装者は**以下のプロセスを遵守すること**。

* **検索駆動開発:** コーディング中は常に Google 検索を行い、公式ドキュメントの更新、最新のサンプルコード、および既知の不具合情報を確認しながら進めること。
* https://developer.apple.com/documentation/FoundationModels
* https://developer.apple.com/documentation/speech/speechanalyzer
* **仕様の柔軟性:** APIのシグネチャ等が仕様書と異なる場合、検索で見つかった最新の実装パターンを優先する。

## 2. システム要件・環境

### 2.1 ターゲット環境

* **OS:** macOS 26.0 以降
* **ハードウェア:** Apple Silicon搭載Mac
* **開発ツール:** Xcode 17.x 以降, XcodeGen

## 3. アーキテクチャ・技術スタック

### 3.1 フレームワーク

* **UI:** SwiftUI
* **音声処理:** AVFoundation, Speech (`SpeechAnalyzer`)
* **AI・翻訳:** FoundationModels (オンデバイスLLM)
* **プロジェクト管理:** XcodeGen

## 4. 機能要件

### 4.1 音声入力設定 (UI変更)

* **デバイス選択:**
* メイン画面の見やすい位置に**プルダウンメニュー（Picker）**を配置すること。
* プルダウンには、現在利用可能な入力デバイス名（例: "BlackHole 2ch", "MacBook Proのマイク"）を一覧表示する。
* ユーザーがプルダウンを変更した瞬間、オーディオエンジンを再起動し、新しいデバイスでの聞き取りを即座に開始すること。



### 4.2 音声認識機能 (SpeechAnalyzer)

* `SpeechAnalyzer` を使用し、非同期ストリーム (`AsyncSequence`) で音声バッファを処理する。
* **並行処理:** 翻訳処理の遅延が音声認識をブロックしないよう、認識タスクは独立したActorで実行し続けること。

### 4.3 AI翻訳機能 (FoundationModels)

* **1文ごとのパイプライン処理:**
* 音声認識で「文が確定 (`isFinal`)」したタイミングで、そのテキストを翻訳タスクへ非同期に投げる。
* **指示プロンプト:** `FoundationModels` のテキスト生成APIに対し、以下の指示を含めること。
> "You are a professional interpreter. Translate the following text into natural Japanese immediately."




* **エラーハンドリング:**
* LLMの推論が間に合わない場合でも、キューに積んで順次処理し、入力の聞き取りは止めないこと。



### 4.4 画面構成 (Main View)

SwiftUIらしいでざいんを意識して構成すること。

* **上部ヘッダー:**
* **[プルダウン]** 音声入力ソース選択
* **[インジケータ]** 録音中/停止中ステータス


* **中央コンテンツ:**
* **タイムラインリスト (ScrollView):**
* 各行に「原文（左/上）」と「翻訳（右/下）」を表示。
* 翻訳中は `ProgressView` または「翻訳中...」のアニメーションを表示する。




* **下部コントロール:**
* 開始/停止ボタン、ログ保存ボタン。



## 5. 開発プロトコル（AIエージェント/実装者向け）

### 5.1 検索必須項目

実装を開始する前に、以下のキーワードでGoogle検索を行い、最新のAPI仕様を把握すること。

1. `"swift SpeechAnalyzer sample code macOS"`
2. `"swift FoundationModels tutorial text generation"`

## 6. XcodeGen 設定仕様 (`project.yml`)

### 6.1 基本設定

* **name:** NativeSpeechTranslator
* **deploymentTarget:** macOS "26.0"

### 6.2 依存関係・権限

他にも必要そうでしたら追加してください

* **Entitlements:**
* `com.apple.security.device.audio-input`: true
* `com.apple.developer.machine-learning.models`: true

* **Info.plist:**
* `NSSpeechRecognitionUsageDescription`: "音声を文字に変換するために使用します。"
* `NSMicrophoneUsageDescription`: "システム音声をキャプチャするためにマイク入力を使用します。"
