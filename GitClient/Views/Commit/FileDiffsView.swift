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

    var body: some View {
        SourceCodeTextEditor(
            text: $chunk.raw,
            customization: .init(
                didChangeText: {_ in },
                insertionPointColor: { Sourceful.Color.white },
                lexerForSource: { _ in SwiftLexer() }, // TODO: 言語によって切り替え
                textViewDidBeginEditing: { _ in },
                theme: { FileDiffTheme() }
            )// TODO: line numberの設定
        )
    }
}

#Preview {
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
    ScrollView {
        LazyVStack {
            ChunkView(chunk: Chunk(raw: text))
            ChunkView(chunk: Chunk(raw: text))
            ChunkView(chunk: Chunk(raw: text))
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
                chunksView2(fileDiff.chunks)
                    .padding(.top, 8)
            }
        }
        .font(Font.system(.body, design: .monospaced))
    }

    private func chunksView2(_ chunks: [Chunk]) -> some View {
        ForEach(chunks) { chunk in
            ChunkView(chunk: chunk)
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
