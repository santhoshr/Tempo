//
//  DiffView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/05/26.
//

import SwiftUI

struct DiffView: View {
    var diff: Diff

    var body: some View {
        FileDiffsView(fileDiffs: diff.fileDiffs)
    }
}

#Preview {
    let text = """
diff --git a/GitClient.xcodeproj/project.pbxproj b/GitClient.xcodeproj/project.pbxproj
index 96134c5..46cd844 100644
--- a/GitClient.xcodeproj/project.pbxproj
+++ b/GitClient.xcodeproj/project.pbxproj
@@ -41,7 +41,7 @@
                61E290D328E1EFC600BCEB04 /* GitDiff.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61E290D228E1EFC600BCEB04 /* GitDiff.swift */; };
                61E290D528E1F05000BCEB04 /* GitDiffCached.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61E290D428E1F05000BCEB04 /* GitDiffCached.swift */; };
                61E290D728E5D84100BCEB04 /* GitPush.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61E290D628E5D84100BCEB04 /* GitPush.swift */; };
-               61E290DB28E7C66300BCEB04 /* DiffView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61E290DA28E7C66200BCEB04 /* DiffView.swift */; };
+               61E290DB28E7C66300BCEB04 /* CommitView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61E290DA28E7C66200BCEB04 /* CommitView.swift */; };
                61EBD7CF28E922510009ED92 /* GitBranch.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61EBD7CE28E922510009ED92 /* GitBranch.swift */; };
                61EBD7D128E940C30009ED92 /* Branch.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61EBD7D028E940C30009ED92 /* Branch.swift */; };
                61EBD7D328E966190009ED92 /* GitSwitch.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61EBD7D228E966190009ED92 /* GitSwitch.swift */; };
"""
    return DiffView(diff: try! Diff(raw: text))
}
