# Native Speech Translator

<img width="1011" alt=" 2026-01-08 1 54 58" src="https://github.com/user-attachments/assets/f6052738-27e7-47a9-aa0d-7ece4dfa5a41" />


<img width="937" alt="Image" src="https://github.com/user-attachments/assets/441935d9-35c1-4f76-bd02-05c7d8fd3d5c" />

macOS Tahoe以降で動作するオフラインのリアルタイム音声認識 & 翻訳ツール

## 概要

マイク音声をリアルタイムでキャプチャし、オンデバイスで以下の処理を行います

LadioCast，BlackHole等を活用することで、zoom通話などから音声をキャプチャすることもできます

1. `SpeechAnalyzer` による文字起こし
2. `Translation`によるリアルタイム翻訳
3. `FoundationModels`またはOpenAI Compatible APIによる高精度な翻訳
4. 収録したスピーチ内容の要約機能

## 対応翻訳言語

以下の言語に対応しています

- 日本語 (ja-JP)
- 英語 (en-US)
- スペイン語 (es-ES)
- フランス語 (fr-FR)
- ドイツ語 (de-DE)
- 韓国語 (ko-KR)
- 中国語 (zh-CN)
- イタリア語 (it-IT)
- ポルトガル語 (pt-PT)

## 動作要件

- **macOS 26.0+**

## ビルド方法

### 1. mintの導入

```bash
brew install mint
```

### 2. XcodeGenでプロジェクトファイルの生成

```bash
mint run xcodegen
```

### 3. ビルド

```bash
xcodebuild -scheme NativeSpeechTranslator -destination 'platform=macOS' build
```

### xcode-build-server

```bash
xcode-build-server config -project *.xcodeproj -scheme NativeSpeechTranslator
```
