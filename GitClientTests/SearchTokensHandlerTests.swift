//
//  SearchTokensHandlerTests.swift
//  GitClientTests
//
//  Created by Makoto Aoyama on 2025/04/03.
//

import Testing
@testable import Tempo

struct SearchTokensHandlerTests {
    @Test func handleGrep() async throws {
        let tokens: [SearchToken] = [.init(kind: .grepAllMatch, text: "a"), .init(kind: .grep, text: "b"),]
        let newTokens = SerachTokensHandler.handle(tokens)
        #expect(newTokens.first!.kind == .grep )
        #expect(newTokens.last!.kind == .grep )
    }

    @Test func handleGrepAllMath() async throws {
        let tokens: [SearchToken] = [.init(kind: .grep, text: "a"), .init(kind: .grepAllMatch, text: "b"),]
        let newTokens = SerachTokensHandler.handle(tokens)
        #expect(newTokens.first!.kind == .grepAllMatch )
        #expect(newTokens.last!.kind == .grepAllMatch )
    }

    @Test func handleS() async throws {
        let tokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .g, text: "a"), .init(kind: .s, text: "b"),]
        let newTokens = SerachTokensHandler.handle(tokens)
        #expect(newTokens.last!.kind == .s )
        #expect(newTokens.count == 2 )
    }

    @Test func handleG() async throws {
        let tokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .s, text: "a"), .init(kind: .g, text: "b"),]
        let newTokens = SerachTokensHandler.handle(tokens)
        #expect(newTokens.last!.kind == .g )
        #expect(newTokens.count == 2 )
    }
}
