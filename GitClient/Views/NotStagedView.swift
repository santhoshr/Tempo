//
//  DiffView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/05/26.
//

import SwiftUI

struct NotStagedView: View {
    var fileDiffs: [FileDiff]
    var untrackedFiles: [String]
    var onSelectFileDiff: ((FileDiff) -> Void)?
    var onSelectChunk: ((FileDiff, Chunk) -> Void)?
    var onSelectUntrackedFile: ((String) -> Void)?
    @State private var isExpanded = true

    var body: some View {
        LazyVStack(alignment: .leading, pinnedViews: .sectionHeaders) {
            Section (isExpanded: $isExpanded) {
                if fileDiffs.isEmpty && untrackedFiles.isEmpty {
                    LazyVStack(alignment: .center) {
                        Text("No Changed")
                            .foregroundStyle(.secondary)
                            .padding()
                            .padding(.trailing)
                            .padding(.trailing)
                            .padding(.bottom, 32)
                    }
                }

                ForEach(fileDiffs) { fileDiff in
                    HStack {
                        VStack(alignment: .leading) {
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
                        }
                        Spacer()
                        if fileDiff.chunks.isEmpty {
                            Button {
                                onSelectFileDiff?(fileDiff)
                            } label: {
                                Image(systemName: "plus.circle")
                            }
                            .buttonStyle(.accessoryBar)
                            .help("Stage this hunk")
                            .padding()
                        }
                    }

                    ForEach(fileDiff.chunks) { chunk in
                        HStack {
                            chunkView(chunk)
                            Spacer()
                            Button {
                                onSelectChunk?(fileDiff, chunk)
                            } label: {
                                Image(systemName: "plus.circle")
                            }
                            .buttonStyle(.accessoryBar)
                            .help("Stage this hunk")
                            .padding()
                        }
                    }
                }
                .font(Font.system(.body, design: .monospaced))
                .padding()

                if !untrackedFiles.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Divider()
                        Text("Untracked Files")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .padding(.bottom)

                        ForEach(untrackedFiles, id: \.self) { file in
                            HStack {
                                Text(file)
                                    .fontWeight(.bold)
                                Spacer()
                                Button {
                                    onSelectUntrackedFile?(file)
                                } label: {
                                    Image(systemName: "plus.circle")
                                }
                                .buttonStyle(.accessoryBar)
                                .help("Stage this file")
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            } header: {
                SectionHeader(title: "Not Staged", isExpanded: $isExpanded)
            }
        }
    }

    private func chunkView(_ chunk: Chunk) -> some View {
        chunk.lines.map { line in
            Text(line.raw)
                .foregroundStyle(chunkLineColor(line))
        }
        .reduce(Text("")) { partialResult, text in
            partialResult + text + Text("\n")
        }
    }

    private func chunkLineColor(_ line: Chunk.Line) -> Color {
        switch line.kind {
        case .removed:
            return .red
        case .added:
            return .green
        case .unchanged:
            return .primary
        }
    }
}

#Preview {
    let raw = """
diff --git a/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved b/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
index ca7d6df..b9d9984 100644
--- a/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
+++ b/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
@@ -24,7 +24,7 @@
     "repositoryURL": "https://github.com/onevcat/Kingfisher.git",
     "state": {
       "branch": null,
-          "revision": "7ccfb6cefdb6180cde839310e3dbd5b2d6fefee5",
+          "revision": "20d21b3fd7192a42851d7951453e96b41e4e1ed1",
       "version": "5.13.3"
     }
   }
diff --git a/GitBlamePR/View/DetailFooter.swift b/GitBlamePR/View/DetailFooter.swift
index ec290b6..46b0c19 100644
--- a/GitBlamePR/View/DetailFooter.swift
+++ b/GitBlamePR/View/DetailFooter.swift
@@ -6,6 +6,7 @@
//  Copyright © 2020 dev.aoyama. All rights reserved.
//

+// test
import SwiftUI

struct DetailFooter: View {
@@ -36,6 +37,9 @@ struct DetailFooter: View {
 }
}

+
+
+// test2
struct DetailFooter_Previews: PreviewProvider {
 static var previews: some View {
     Group {
diff --git a/testfile6.txt b/testfile6.txt
new file mode 100644
index 0000000..e69de29
"""
    let diff = try! Diff(raw: raw)
    return ScrollView {
        NotStagedView(
            fileDiffs: diff.fileDiffs,
            untrackedFiles: ["Projects/Files/Path.swift", "Projects/Files/Path1.swift"],
            onSelectFileDiff: { f in
                print(f)
            },
            onSelectChunk: { f, c in
                print(f, c)
            },
            onSelectUntrackedFile: { f in
                print(f)
            }
        )
    }
}
