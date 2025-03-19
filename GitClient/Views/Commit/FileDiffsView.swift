//
//  FileDiffsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/04.
//

import SwiftUI

struct FileDiffsView2: View {
    @Binding var expandableFileDiffs: [ExpandableModel<FileDiff>]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach($expandableFileDiffs, id: \.self) { $expandedFileDiff in
                FileDiffView(
                    expandableFileDiff: $expandedFileDiff,
                    onSelectAllExpanded: { isExpanded in
                        withAnimation {
                            expandableFileDiffs = expandableFileDiffs.map { .init(isExpanded: isExpanded, model: $0.model) }
                        }
                    }
                )
                .padding(.bottom)
            }
        }
        .font(Font.system(.body, design: .monospaced))
    }
}

struct FileDiffsView: View {
    @State var expandableFileDiffs: [ExpandableModel<FileDiff>]

    init(fileDiffs: [FileDiff]) {
        self.expandableFileDiffs = fileDiffs.map { .init(isExpanded: true, model: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach($expandableFileDiffs, id: \.self) { $expandedFileDiff in
                FileDiffView(
                    expandableFileDiff: $expandedFileDiff,
                    onSelectAllExpanded: { isExpanded in
                        withAnimation {
                            expandableFileDiffs = expandableFileDiffs.map { .init(isExpanded: isExpanded, model: $0.model) }
                        }
                    }
                )
                .padding(.bottom)
            }
        }
        .font(Font.system(.body, design: .monospaced))
    }
}
