//
//  GitClientTests.swift
//  GitClientTests
//
//  Created by Makoto Aoyama on 2022/09/17.
//

import XCTest
@testable import GitClient

final class DiffTests: XCTestCase {
    let raw = """
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
diff --git a/GitBlamePR/View/DetailFooter.swift b/GitBlamePR/View/DetailFooter.swift
index ec290b6..46b0c19 100644
--- a/GitBlamePR/View/DetailFooter.swift
+++ b/GitBlamePR/View/DetailFooter.swift
@@ -6,6 +6,7 @@
//  Copyright © 2020 dev.aoyama. All rights reserved.
//

+// test
import SwiftUI

struct DetailFooter: View {
@@ -36,6 +37,9 @@ struct DetailFooter: View {
 }
}

+
+
+// test2
struct DetailFooter_Previews: PreviewProvider {
 static var previews: some View {
     Group {
"""

    func testDiffInit() throws {
        let diff = try Diff(raw: raw)
        XCTAssertEqual(diff.fileDiffs.count, 2)
        XCTAssertEqual(diff.fileDiffs.first!.raw, """
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
        XCTAssertEqual(diff.fileDiffs[1].raw, """
diff --git a/GitBlamePR/View/DetailFooter.swift b/GitBlamePR/View/DetailFooter.swift
index ec290b6..46b0c19 100644
--- a/GitBlamePR/View/DetailFooter.swift
+++ b/GitBlamePR/View/DetailFooter.swift
@@ -6,6 +6,7 @@
//  Copyright © 2020 dev.aoyama. All rights reserved.
//

+// test
import SwiftUI

struct DetailFooter: View {
@@ -36,6 +37,9 @@ struct DetailFooter: View {
 }
}

+
+
+// test2
struct DetailFooter_Previews: PreviewProvider {
 static var previews: some View {
     Group {
"""
        )
        XCTAssertEqual(raw, diff.raw)
        XCTAssertEqual(diff.raw, diff.fileDiffs[0].raw + "\n" + diff.fileDiffs[1].raw)
    }

    func testFileDiffInit() throws {
        let fileDiff = try FileDiff(raw: """
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
@@ -36,6 +37,9 @@ struct DetailFooter: View {
     }
 }

+
+
+// test2
 struct DetailFooter_Previews: PreviewProvider {
     static var previews: some View {
         Group {
"""
        )

        XCTAssertEqual(fileDiff.header, "diff --git a/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved b/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved")
        XCTAssertEqual(fileDiff.extendedHeaderLines.count, 1)
        XCTAssertEqual(fileDiff.extendedHeaderLines[0], "index ca7d6df..b9d9984 100644")
        XCTAssertEqual(fileDiff.fromFileToFileLines.count, 2)
        XCTAssertEqual(fileDiff.fromFileToFileLines[0], "--- a/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved")
        XCTAssertEqual(fileDiff.fromFileToFileLines[1], "+++ b/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved")
        XCTAssertEqual(fileDiff.chunks.count, 2)
        XCTAssertEqual(fileDiff.chunks[0].raw, """
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
        XCTAssertEqual(fileDiff.chunks[1].raw, """
@@ -36,6 +37,9 @@ struct DetailFooter: View {
     }
 }

+
+
+// test2
 struct DetailFooter_Previews: PreviewProvider {
     static var previews: some View {
         Group {
"""
        )
    }

    func testDiffInit2() throws {
        let raw = """
diff --git a/GitClient/Models/ShowMedium.swift b/GitClient/Models/ShowMedium.swift
index 88f91e0..1c7669c 100644
--- a/GitClient/Models/ShowMedium.swift
+++ b/GitClient/Models/ShowMedium.swift
@@ -16,6 +16,9 @@ struct ShowMedium {
     var diff: Diff?

     init(raw: String) throws {
+        guard !raw.isEmpty else {
+            throw GenericError(errorDescription: "raw is empty")
+        }
         let spliteDiff = raw.split(separator: "diff", maxSplits: 1)
         guard spliteDiff.count == 2 else {
             let commitInfo = raw

"""
        _ = try Diff(raw: raw)
    }

    func testFileDiffInit2() throws {
        let raw = """
diff --git a/GitClient/Views/DiffView.swift b/GitClient/Views/DiffView.swift
index 347796e..df0715b 100644
--- a/GitClient/Views/DiffView.swift
+++ b/GitClient/Views/DiffView.swift
@@ -59,7 +59,6 @@ struct DiffView: View {
  }
}

-
struct DiffView_Previews: PreviewProvider {
  static var previews: some View {

"""
        let fileDiff = try FileDiff(raw: raw)
        XCTAssertEqual(fileDiff.raw, raw)
    }

    func testChunkInit() {
        let chunk = Chunk(raw: """
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

        XCTAssertEqual(chunk.lines.count, 9)
        XCTAssertEqual(chunk.lines[0].kind, Chunk.Line.Kind.unchanged)
        XCTAssertEqual(chunk.lines[1].kind, Chunk.Line.Kind.unchanged)
        XCTAssertEqual(chunk.lines[2].kind, Chunk.Line.Kind.unchanged)
        XCTAssertEqual(chunk.lines[3].kind, Chunk.Line.Kind.unchanged)
        XCTAssertEqual(chunk.lines[4].kind, Chunk.Line.Kind.removed)
        XCTAssertEqual(chunk.lines[5].kind, Chunk.Line.Kind.added)
        XCTAssertEqual(chunk.lines[6].kind, Chunk.Line.Kind.unchanged)
        XCTAssertEqual(chunk.lines[7].kind, Chunk.Line.Kind.unchanged)
        XCTAssertEqual(chunk.lines[8].kind, Chunk.Line.Kind.unchanged)
    }

    func testStage() throws {
        var diff = try Diff(raw: raw)
        diff.fileDiffs.forEach { fileDiff in
            fileDiff.chunks.forEach { chunk in
                XCTAssertNil(chunk.stage)
            }
        }
        diff = diff.updateAll(stage: true)
        diff.fileDiffs.forEach { fileDiff in
            fileDiff.chunks.forEach { chunk in
                XCTAssertTrue(chunk.stage!)
            }
        }
        diff = diff.updateAll(stage: false)
        diff.fileDiffs.forEach { fileDiff in
            fileDiff.chunks.forEach { chunk in
                XCTAssertFalse(chunk.stage!)
            }
        }
    }

    func testStageStrings() throws {
        var diff = try Diff(raw: raw)
        XCTAssertEqual(diff.stageStrings().count, 3)
        diff.stageStrings().forEach {
            XCTAssertEqual($0, "n")
        }
        diff = diff.updateAll(stage: true)
        XCTAssertEqual(diff.stageStrings().count, 3)
        diff.stageStrings().forEach {
            XCTAssertEqual($0, "y")
        }
        diff = diff.updateAll(stage: false)
        XCTAssertEqual(diff.stageStrings().count, 3)
        diff.stageStrings().forEach {
            XCTAssertEqual($0, "n")
        }
    }

    func testToggleChunkStage() throws {
        let diff = try Diff(raw: raw).updateAll(stage: false)
        let newDiff = diff.toggleChunkStage(diff.fileDiffs.first!.chunks.first!, in: diff.fileDiffs.first!)
        XCTAssertFalse(diff.fileDiffs.first!.chunks.first!.stage!)
        XCTAssertTrue(newDiff.fileDiffs.first!.chunks.first!.stage!)
    }
}
