//
//  FileDiffsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/04.
//

import SwiftUI

struct FileDiffsView: View {
    var fileDiffs: [FileDiff]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(fileDiffs) { fileDiff in
                FileDiffView(fileDiff: fileDiff)
                .padding(.bottom)
            }
        }
        .font(Font.system(.body, design: .monospaced))
    }
}
