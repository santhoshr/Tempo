//
//  ChunkView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/02/18.
//


import SwiftUI
import Sourceful

struct ChunkView: View {
    @State var chunk: Chunk
    var fileDiffHeader: String
    var lexer: Lexer {
        get {
            Language.lexer(fileDiffHeader: fileDiffHeader)
        }
    }

    var body: some View {
        SourceCodeTextEditor(
            text: $chunk.raw,
            customization: .init(
                didChangeText: {_ in },
                insertionPointColor: { Sourceful.Color.white },
                lexerForSource: { _ in lexer },
                textViewDidBeginEditing: { _ in },
                theme: { FileDiffTheme() }
            ),
            lineNumbers: $chunk.lineNumbers
        )
    }
}

#Preview {
    var fileDiffHeader = "diff --git a/GitClient/Models/Language.swift b/GitClient/Models/Language.swift"
    var text = """
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

    var text2 = """
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
            ChunkView(chunk: Chunk(raw: text), fileDiffHeader: fileDiffHeader)
            ChunkView(chunk: Chunk(raw: text2), fileDiffHeader: fileDiffHeader)
            ChunkView(chunk: Chunk(raw: text), fileDiffHeader: fileDiffHeader)
        }
            .frame(width: 400)
    }
}

