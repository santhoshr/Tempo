//
//  GitDiffNumStatTests.swift
//  GitClientTests
//
//  Created by Makoto Aoyama on 2024/09/07.
//

import XCTest
@testable import GitClient

final class GitDiffNumStatTests: XCTestCase {
    func testParse() throws {
        let c = GitDiffNumStat(directory: URL(string: "file:///maoyama/Projects/")!)
        let stat = c.parse(for: """
3       0       Jot/HistoryDetailNote.swift
0       20      Jot/Note.swift
20      0       Jot/Note.wift
3       0       testfile5.swif
-       -       testfile6.bin
""")
        XCTAssertEqual(
            stat.files,
            ["Jot/HistoryDetailNote.swift", "Jot/Note.swift", "Jot/Note.wift", "testfile5.swif", "testfile6.bin"]
        )
        XCTAssertEqual(
            stat.insertions,
            [3, 0, 20, 3, 0]
        )
        XCTAssertEqual(
            stat.deletions,
            [0, 20, 0, 0, 0]
        )
    }
}
