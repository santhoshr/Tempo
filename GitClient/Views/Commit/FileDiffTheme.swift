//
//  FileDiffTheme.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/02/16.
//


import Foundation
import Sourceful
import AppKit


public struct FileDiffTheme: SourceCodeTheme {

    public init() {}

    public static var font: NSFont {
        let baseFont = NSFont.preferredFont(forTextStyle: .body)
        return NSFont.monospacedSystemFont(ofSize: baseFont.pointSize - 1, weight: .regular)
    }

    private static var lineNumbersColor: Color {
        return NSColor.tertiaryLabelColor
    }

    public let lineNumbersStyle: LineNumbersStyle? = LineNumbersStyle(font: font, textColor: lineNumbersColor)

    public let gutterStyle: GutterStyle = GutterStyle(backgroundColor: NSColor.textBackgroundColor, minimumWidth: 42) // コードのインデントをラインナンバーが3桁と2桁を揃えるため、minimumWidth = 42に設定

    public var font: NSFont {
        FileDiffTheme.font
    }

    public let backgroundColor = NSColor.textBackgroundColor

    public func color(for syntaxColorType: SourceCodeTokenType) -> Color {
        switch syntaxColorType {
        case .plain:
            return NSColor.textColor

        case .number:
            return Color(red: 116/255, green: 109/255, blue: 176/255, alpha: 1.0)

        case .string:
            return Color(red: 211/255, green: 35/255, blue: 46/255, alpha: 1.0)

        case .identifier:
            return Color(red: 20/255, green: 156/255, blue: 146/255, alpha: 1.0)

        case .keyword:
            return Color(red: 215/255, green: 0, blue: 143/255, alpha: 1.0)

        case .comment:
            return Color(red: 69.0/255.0, green: 187.0/255.0, blue: 62.0/255.0, alpha: 1.0)

        case .editorPlaceholder:
            return backgroundColor
        }
	}

    public func color(for diffType: GitDiffOutputChunkTokenType) -> Color? {
        switch diffType {
        case .header:
            return NSColor.tertiaryLabelColor
        default:
            return nil
        }
    }

    public func backGroundColor(for diffType: GitDiffOutputChunkTokenType) -> Color? {
        switch diffType {
        case .header, .unchanged:
            return nil
        case .removed:
            return NSColor.red.withAlphaComponent(0.1)
        case .added:
            return NSColor.green.withAlphaComponent(0.2)
        }
    }
}
