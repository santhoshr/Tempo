//
//  FileDiffHeader.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/06.
//

import SwiftUI

struct FileDiffHeader: View {
    @Binding var isExpanded: Bool
    var toFilePath: String
    var filePathDisplay: String
    var header: String
    var extendedHeaderLines: [String]
    var fromFileToFileLines: [String]
    var onSelectAllExpanded: ((Bool) -> Void)

    var body: some View {
        HStack {
            FileNameView(toFilePath: toFilePath, filePathDisplay: filePathDisplay)
            Spacer()
            ExpandingButton(
                isExpanded: $isExpanded,
                onSelectExpandedAll: onSelectAllExpanded
            )
            .padding(.vertical)
        }
        .background(Color(NSColor.textBackgroundColor).opacity(0.98))
    }
}

#Preview {
    FileDiffHeader(
        isExpanded: .constant(true),
        toFilePath: "Sources/MyFeature/File.swift",
        filePathDisplay: "Sources/MyFeature/File.swift",
        header: "diff --git a/Sources/MyFeature/File.swift b/Sources/MyFeature/File.swift",
        extendedHeaderLines: [
            "index 83db48d..f735e1c 100644",
            "--- a/Sources/MyFeature/File.swift",
            "+++ b/Sources/MyFeature/File.swift"
        ],
        fromFileToFileLines: [
            "--- a/Sources/MyFeature/File.swift",
            "+++ b/Sources/MyFeature/File.swift"
        ],
        onSelectAllExpanded: { isExpanded in
            print("Select all expanded: \(isExpanded)")
        }
    )
}
