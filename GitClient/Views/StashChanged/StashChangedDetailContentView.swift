//
//  StashChangedDetailContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/15.
//

import SwiftUI

struct StashChangedDetailContentView: View {
    @Binding var fileDiffs: [ExpandableModel<FileDiff>]

    var body: some View {
        VStack {
            FileDiffsView2(expandableFileDiffs: $fileDiffs)
                    .padding()
        }
        .textSelection(.enabled)
    }
}

