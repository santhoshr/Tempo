//
//  Language.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/02/17.
//

import Foundation
import Sourceful
import SwiftUI

enum Language: String {
    case swift, python, javascript, typescript, java, kotlin, c, cpp, csharp, ruby, php, go, rust, shell, perl, html, css, markdown, ocaml

    private static func detect(filePath: String) -> Language? {
        let ext = URL(fileURLWithPath: String(filePath)).pathExtension.lowercased()

        switch ext {
        case "swift": return .swift
        case "py": return .python
        case "js": return .javascript
        case "ts": return .typescript
        case "java": return .java
        case "kt": return .kotlin
        case "c": return .c
        case "cpp", "cc", "cxx": return .cpp
        case "cs": return .csharp
        case "rb": return .ruby
        case "php": return .php
        case "go": return .go
        case "rs": return .rust
        case "sh", "bash", "zsh": return .shell
        case "pl": return .perl
        case "html": return .html
        case "css": return .css
        case "md": return .markdown
        case "ml": return .ocaml
        default: return nil
        }
    }

    static func lexer(filePath: String) -> Lexer {
        switch detect(filePath: filePath) {
        case .java:
            return JavaLexer()
        case .javascript, .typescript:
            return JavaScriptLexer()
        case .python:
            return Python3Lexer()
        case .swift:
            return SwiftLexer()
        case .ocaml:
            return OCamlLexer()
        default:
            return PlainLexer()
        }
    }

    static func thumbnail(filePath: String) -> SwiftUI.Image {
        switch detect(filePath: filePath) {
        case .swift:
            return .init("Swift")
        default:
            return .init(systemName: "doc")
        }
    }
}
