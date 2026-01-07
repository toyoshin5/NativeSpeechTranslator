# Native Speech Translator

<img width="1011" height="743" alt=" 2026-01-08 1 54 58" src="https://github.com/user-attachments/assets/7161e124-ce53-41ae-8309-f0e480f2212e" />


macOS Tahoe以降で動作するオフラインのリアルタイム音声認識 & 翻訳ツール

## 概要

マイク音声をリアルタイムでキャプチャし、オンデバイスで以下の処理を行います
LadioCast，BlackHole等を活用することで、zoom通話などから音声をキャプチャすることができます

1. `SpeechAnalyzer` による文字起こし
2. `FoundationModels` による日本語翻訳

## 動作要件

- **macOS 26.0+**

## ビルド方法

### 1. XcodeGenの導入(brew)

```bash
brew install xcodegen
```

### 2. プロジェクトファイルの生成

```bash
xcodegen generate
```

### 3. ビルド

```bash
xcodebuild -scheme NativeSpeechTranslator -destination 'platform=macOS' build
```
