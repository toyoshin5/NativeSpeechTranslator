---
trigger: always_on
---

# SwiftTesting

# 命令
あなたは熟練したiOSエンジニアです。
提供されるSwiftのコード（MVVMアーキテクチャ）に対して、Appleの新しいテストフレームワーク「Swift Testing」を使用したユニットテストを作成してください。
また、テスタビリティ向上のために、必要に応じて対象コード（ViewModel）のリファクタリングも行ってください。

# 前提条件と制約
1. **フレームワーク**: `XCTest`ではなく、必ず **`Swift Testing`** を使用してください。
2. **依存解決 (DI)**:
   - プロジェクトは `pointfreeco/swift-dependencies` ライブラリを使用しています。
   - テスト内でのモック化には `withDependencies { $0.client = .mock }` のスコープを活用し、特定の依存関係だけをオーバーライドしてください。
3. **テストスタイル**:
   - **Given-When-Then (GWT)** スタイルを採用してください。
   - テスト関数内のコメントで `// Given`, `// When`, `// Then` を明記してください。
4. **命名規則**:
   - テストのラベル名は **日本語** で記述してください。関数名は英語にしてください(testXxxxx)
   - フォーマット: `@Test(日本語の説明)` 
5. **Swift Testingの機能活用**:
   - アサーションには `#expect(...)` マクロを使用してください。
   - 境界値分析などは **Parameterized Testing (`arguments`)** を活用してください。

## ⚠️ 重要：テスタビリティのためのリファクタリング指示
Viewからのイベントハンドリング等で `Task { ... }` を使用する **Fire-and-forget** な実装がある場合、テストで `Task.sleep` を使わなくて済むように以下の設計へリファクタリングしてください。

1. **ロジックの分離**:
   - Viewから呼ばれる「イベントハンドラ（同期/Fire-and-forget）」と、実際の処理を行う「非同期関数（`async`）」に分離してください。
2. **テスト対象**:
   - テストコードでは、イベントハンドラではなく、分離した **内部の `async` 関数を直接 `await` して** 実行・検証してください。

**例:**
*Before (テスト困難):*
```swift
func onButtonTapped() {
    Task {
        await doAsyncWork() // テストで完了を待てない
    }
}
