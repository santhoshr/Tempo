//
//  StageFileDiffHeaderView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/02/22.
//

import SwiftUI

struct StageFileDiffHeaderView: View {
    var fileDiff: FileDiff

    var body: some View {
        HStack {
            Text(fileDiff.filePathDisplay)
                .fontWeight(.bold)
                .help(fileDiff.header + "\n" + (fileDiff.extendedHeaderLines + fileDiff.fromFileToFileLines).joined(separator: "\n"))
                .font(Font.system(.body, design: .default))
            Spacer()
        }
        .background(Color(NSColor.textBackgroundColor).opacity(0.98))
    }
}
