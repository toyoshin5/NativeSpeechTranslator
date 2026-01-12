## 仕様変更

アプリの設計として，TranslationClient.swiftによる直訳は必ず行ったうえで，isFinalのタイミングで，TranslationLLMClient.swiftによるLLMを使った翻訳を行うという流れに変更します．LLMを使った翻訳をするかどうかは設定画面で選択できます．

TranslationClient.swift を参考に，(というか同じインタフェースの)TranslationLLMClient.swift を作成してください．

TranslationLLMClientでは，LLMによる翻訳を行います．翻訳は以下のモデルに対応させます．

- OpenAI: gpt-4o-mini (最新の最も安いモデルを調べて)
- Gemini: gemini-3.0-flash (最新の最も安いモデルを調べて)
- Groq: llama-3.3-70b-versatile, llama-3.1-8b-instruct
- Foundation Models: 既存のコードを参考にする(APIキー不要)

それぞれAPIキーを登録できるような設定画面を設けて，そこで設定できるようにしてほしいです．

## 設定画面
既存のsegment controlとは削除します．，代わりにLLMを用いた翻訳を行うかどうかを選択できるような設定画面を設けたいです．オンのときは，使用する会社とモデルを選び，それぞれAPIキーを入力して保存できるようにしてほしいです．

## 削除するファイル

TranslationServiceLLM
TranslationPolishingService

## 備考
ファイル構造も整えてほしい

