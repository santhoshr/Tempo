//
//  FileDiffHeader.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/06.
//

import SwiftUI

struct FileDiffHeader: View {
    @Binding var expandableFileDiff: ExpandableModel<FileDiff>
    var onSelectAllExpanded: ((Bool) -> Void)

    var body: some View {
        HStack {
            Text(expandableFileDiff.model.filePathDisplay)
                .fontWeight(.bold)
                .help(expandableFileDiff.model.header + "\n" + (expandableFileDiff.model.extendedHeaderLines + expandableFileDiff.model.fromFileToFileLines).joined(separator: "\n"))
                .font(Font.system(.body, design: .default))
            Spacer()
            ExpandingButton(
                isExpanded: $expandableFileDiff.isExpanded,
                onSelectExpandedAll: onSelectAllExpanded
            )
            .padding(.vertical)
        }
        .background(Color(NSColor.textBackgroundColor).opacity(0.98))
    }
}

#Preview {
//    FileDiffHeader()
}
