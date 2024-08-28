//
//  DiffView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/05/26.
//

import SwiftUI

struct NotCommittedDiffView: View {
    var fileDiffs: [FileDiff]
    var onTap: (FileDiff, Chunk) -> Void?

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
                ForEach(fileDiff.chunks) { chunk in
                    HStack {
                        Rectangle()
                            .frame(width: 8)
                            .frame(maxHeight: .infinity)
                            .foregroundColor(chunk.stage == true ? .accentColor : .secondary)
                            .onTapGesture {
                                onTap(fileDiff, chunk)
                            }
                            .clipShape(Capsule())
                        chunkView(chunk)
                    }
                }
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

//#Preview {
//    let text = """
//diff --git a/GitClient.xcodeproj/project.pbxproj b/GitClient.xcodeproj/project.pbxproj
//index 96134c5..46cd844 100644
//--- a/GitClient.xcodeproj/project.pbxproj
//+++ b/GitClient.xcodeproj/project.pbxproj
//@@ -41,7 +41,7 @@
//                61E290D328E1EFC600BCEB04 /* GitDiff.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61E290D228E1EFC600BCEB04 /* GitDiff.swift */; };
//                61E290D528E1F05000BCEB04 /* GitDiffCached.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61E290D428E1F05000BCEB04 /* GitDiffCached.swift */; };
//                61E290D728E5D84100BCEB04 /* GitPush.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61E290D628E5D84100BCEB04 /* GitPush.swift */; };
//-               61E290DB28E7C66300BCEB04 /* DiffView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61E290DA28E7C66200BCEB04 /* DiffView.swift */; };
//+               61E290DB28E7C66300BCEB04 /* CommitView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61E290DA28E7C66200BCEB04 /* CommitView.swift */; };
//                61EBD7CF28E922510009ED92 /* GitBranch.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61EBD7CE28E922510009ED92 /* GitBranch.swift */; };
//                61EBD7D128E940C30009ED92 /* Branch.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61EBD7D028E940C30009ED92 /* Branch.swift */; };
//                61EBD7D328E966190009ED92 /* GitSwitch.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61EBD7D228E966190009ED92 /* GitSwitch.swift */; };
//"""
//    return NotCommittedDiffView(fileDiffs: try! Diff(raw: text).updateAll(stage: true).fileDiffs)
//}
