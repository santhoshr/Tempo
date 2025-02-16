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
        return NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .regular)
    }

    private static var lineNumbersColor: Color {
        return NSColor.secondaryLabelColor
    }

    public let lineNumbersStyle: LineNumbersStyle? = LineNumbersStyle(font: font, textColor: lineNumbersColor)

    public let gutterStyle: GutterStyle = GutterStyle(backgroundColor: NSColor.windowBackgroundColor, minimumWidth: 32)

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
	
}
