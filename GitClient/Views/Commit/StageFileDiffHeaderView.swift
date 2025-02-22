//
//  StageFileDiffHeaderView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/02/22.
//

import SwiftUI

struct StageFileDiffHeaderView: View {
    var fileDiff: FileDiff
    var onSelectFileDiff: ((FileDiff) -> Void)?

    var body: some View {
        HStack {
            Text(fileDiff.filePathDisplay)
                .fontWeight(.bold)
                .help(fileDiff.header + "\n" + (fileDiff.extendedHeaderLines + fileDiff.fromFileToFileLines).joined(separator: "\n"))
                .font(Font.system(.body, design: .default))
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
    }
}
