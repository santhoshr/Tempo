//
//  ShowMediumTest.swift
//  GitClientTests
//
//  Created by Makoto Aoyama on 2024/05/26.
//

import XCTest
@testable import Tempo

final class ShowMediumTest: XCTestCase {
    func testInit() throws {
        let showMedium = try ShowMedium(raw: """
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
        XCTAssertEqual(showMedium.commitHashWithLabel, "commit 4396d158bfa68710f0fef091599e7d1cea310791")
        XCTAssertEqual(showMedium.commitHash, "4396d158bfa68710f0fef091599e7d1cea310791")
        XCTAssertEqual(showMedium.author, "Author: Makoto Aoyama <m@aoyama.dev>")
        XCTAssertEqual(showMedium.date, "Date:   Sun May 26 17:57:42 2024 +0900")
        XCTAssertEqual(showMedium.commitMessage, """

    Test comment

    message

"""
        )
        XCTAssertEqual(showMedium.diff?.raw, """
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
    }

    func testInitForMarge() throws {
        let raw = """
commit da82a43b5d274fecbf8e02b64b4e6298caab8709
Merge: 1506e13 b842015
Author: Makoto Aoyama <m@aoyama.dev>
Date:   Fri Mar 1 23:54:45 2024 +0900

    Merge branch 'main' of github.com:maoyama/GitClient

"""
        let showMedium = try ShowMedium(raw: raw)
        XCTAssertEqual(showMedium.commitHashWithLabel, "commit da82a43b5d274fecbf8e02b64b4e6298caab8709")
        XCTAssertEqual(showMedium.author, "Author: Makoto Aoyama <m@aoyama.dev>")
        XCTAssertEqual(showMedium.date, "Date:   Fri Mar 1 23:54:45 2024 +0900")
        XCTAssertEqual(showMedium.commitMessage, """

    Merge branch 'main' of github.com:maoyama/GitClient

"""
        )
        XCTAssertNil(showMedium.diff)
    }
}
