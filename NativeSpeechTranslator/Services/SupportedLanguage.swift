//
//  SupportedLanguage.swift
//  NativeSpeechTranslator
//
//  Created by Shingo Toyoda on 2026/01/17.
//

import Foundation

enum SupportedLanguage: String, CaseIterable, Identifiable {
    case english = "en-US"
    case spanish = "es-ES"
    case french = "fr-FR"
    case german = "de-DE"
    case japanese = "ja-JP"
    case korean = "ko-KR"
    case chinese = "zh-CN"
    case italian = "it-IT"
    case portuguese = "pt-PT"

    var id: String { rawValue }

    var displayName: String {
        Locale.current.localizedString(forLanguageCode: String(rawValue.prefix(2))) ?? self.rawValue
    }
}
