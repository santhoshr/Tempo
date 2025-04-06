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
        onSelectAllExpanded: { isExpanded in
            print("Select all expanded: \(isExpanded)")
        }
    )
}
