//
//  FileDiffsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/04.
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


struct FileDiffsView: View {
    var fileDiffs: [FileDiff]

    var body: some View {
        LazyVStack(alignment: .leading) {
            ForEach(fileDiffs) { fileDiff in
                Text(fileDiff.header)
                    .fontWeight(.bold)
                ForEach(fileDiff.extendedHeaderLines, id: \.self) { line in
                    Text(line)
                        .fontWeight(.bold)
                }
                ForEach(fileDiff.fromFileToFileLines, id: \.self) { line in
                    Text(line)
                        .fontWeight(.bold)
                }
                chunksView2(fileDiff.chunks, fileDiffHeader: fileDiff.header)
                    .padding(.top, 8)
            }
        }
        .font(Font.system(.body, design: .monospaced))
    }

    private func chunksView2(_ chunks: [Chunk], fileDiffHeader: String) -> some View {
        ForEach(chunks) { chunk in
            ChunkView(chunk: chunk, fileDiffHeader: fileDiffHeader)
        }
    }

    // to be able to select multiple lines of text
    private func chunksViews(_ chunks: [Chunk]) -> Text {
        let views = chunks.map { chunk in
            let chunksText = chunk.lines.map { line in
                Text(line.raw)
                    .foregroundStyle(chunkLineColor(line))
            }
            return chunksText.reduce(Text("")) { partialResult, text in
                partialResult + text + Text("\n")
            }
        }
        return views.reduce(Text("")) { partialResult, text in
            partialResult + text + Text("\n")
        }
    }

    private func chunkLineColor(_ line: Chunk.Line) -> SwiftUI.Color {
        switch line.kind {
        case .header:
            return .secondary
        case .removed:
            return .red
        case .added:
            return .green
        case .unchanged:
            return .primary
        }
    }
}
