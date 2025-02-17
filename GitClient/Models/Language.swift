//
//  Language.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/02/17.
//

import Foundation
import Sourceful

enum Language: String {
    case swift, python, javascript, typescript, java, kotlin, c, cpp, csharp, ruby, php, go, rust, shell, perl, html, css, markdown

    private static func detect(fileDiffHeader: String) -> Language? {
        let components = fileDiffHeader.components(separatedBy: " ")
        guard components.count > 2 else {
            return nil
        }

        guard let filePath = components.last?.dropFirst(2) else {
            return nil
        }

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
        default: return nil
        }
    }

    static func lexer(fileDiffHeader: String) -> Lexer {
        switch detect(fileDiffHeader: fileDiffHeader) {
        case .java:
            return JavaLexer()
        case .swift:
            return SwiftLexer()
        default:
            return PlainLexer()
        }
    }

}
