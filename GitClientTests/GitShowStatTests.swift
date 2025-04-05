//
//  GitShowStatTests.swift
//  GitClientTests
//
//  Created by Makoto Aoyama on 2025/04/05.
//

import Testing
import Foundation
@testable import Tempo

struct GitShowStatTests {
    @Test func string() async throws {
        let stat = GitShowStat(directory: .testFixture!, object: "e129fc78f4a907d6977af32985071d773cd6f4fa")
        let string = try await Process.output(stat)
        #expect(string == " 4 files changed, 9 insertions(+), 9 deletions(-)")
    }
}
