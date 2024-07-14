//
//  GitShowMediumView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/06/16.
//

import SwiftUI

struct GitShowMediumView: View {
    var showMedium: ShowMedium
    var body: some View {
        VStack (alignment: .leading) {
            Text(showMedium.commitHash)
            Text(showMedium.merge ?? "")
            Text(showMedium.author)
            Text(showMedium.date)
            Text(showMedium.commitMessage)
            Text(showMedium.diff?.raw ?? "")
        }
    }
}

#Preview("Single diff") {
    let model = try! ShowMedium(raw: """
commit 4396d158bfa68710f0fef091599e7d1cea310791
Author: Makoto Aoyama <m@aoyama.dev>
Date:   Sun May 26 17:57:42 2024 +0900

    Test comment

    message

diff --git a/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved b/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
index ca7d6df..b9d9984 100644
--- a/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
+++ b/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
@@ -24,7 +24,7 @@
         "repositoryURL": "https://github.com/onevcat/Kingfisher.git",
         "state": {
           "branch": null,
-          "revision": "7ccfb6cefdb6180cde839310e3dbd5b2d6fefee5",
+          "revision": "20d21b3fd7192a42851d7951453e96b41e4e1ed1",
           "version": "5.13.3"
         }
       }

"""
    )
    return GitShowMediumView(showMedium: model)
}

#Preview("Marge commit") {
    let model = try! ShowMedium(raw: """
commit 903d5f53d26752e2f87147ae98d326c2f8626e48
Merge: 850eba7 4351257
Author: Makoto Aoyama <m@aoyama.dev>
Date:   Sun Mar 31 12:18:30 2024 +0900

    Merge pull request #1 from maoyama/add-patch

    Add interactive git command

"""
    )
    return GitShowMediumView(showMedium: model)
}
