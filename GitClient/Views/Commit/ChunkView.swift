//
//  ChunkView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/02/18.
//


import SwiftUI
import Sourceful

struct ChunkView: View {
    var chunk: Chunk
    var filePath: String
    var lexer: Lexer {
        get {
            Language.lexer(filePath: filePath)
        }
    }

    var body: some View {
        SourceCodeTextEditor(
            text: .constant(chunk.raw),
            customization: .init(
                didChangeText: {_ in },
                insertionPointColor: { Sourceful.Color.white },
                lexerForSource: { _ in lexer },
                textViewDidBeginEditing: { _ in },
                theme: { FileDiffTheme() }
            ),
            lineNumbers: .constant(chunk.lineNumbers)
        )
    }
}

#Preview {
    let filePath = "GitClient/Models/Language.swift"
    let text = """
@@ -127,9 +127,6 @@ public struct SourceCodeTextEditor: _ViewRepresentable {
     // Comment
     public func sizeThatFits(_ proposal: ProposedViewSize, nsView: SyntaxTextView, context: Context) -> CGSize? {
         guard let width = proposal.width else { return nil }
         let height = fittingHeight(for: nsView.contentTextView, width: width)
+        print("gutterWidth", nsView.textView.gutterWidth)
-        print("Computed Size:", CGSize(width: width, height: height))
-
         return CGSize(width: width, height: height)
     }
"""

    let text2 = """
@@ -12,9 +12,6 @@ public struct SourceCodeTextEditor: _ViewRepresentable {
     // Comment
     public func sizeThatFits(_ proposal: ProposedViewSize, nsView: SyntaxTextView, context: Context) -> CGSize? {
         guard let width = proposal.width else { return nil }
         let height = fittingHeight(for: nsView.contentTextView, width: width)
+        print("gutterWidth", nsView.textView.gutterWidth)
-        print("Computed Size:", CGSize(width: width, height: height))
-
         return CGSize(width: width, height: height)
     }
"""

    ScrollView {
        LazyVStack {
            ChunkView(chunk: Chunk(raw: text), filePath: filePath)
            ChunkView(chunk: Chunk(raw: text2), filePath: filePath)
            ChunkView(chunk: Chunk(raw: text), filePath: filePath)
        }
            .frame(width: 400)
    }
}

