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
        let oldTokens: [SearchToken] = [.init(kind: .grepAllMatch, text: "a")]
        let newTokens: [SearchToken] = [.init(kind: .grepAllMatch, text: "a"), .init(kind: .grep, text: "b")]
        let handledTokens = SearchTokensHandler.handle(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens.first!.kind == .grep )
        #expect(handledTokens.last!.kind == .grep )
    }

    @Test func handleGrepInEdit() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .grepAllMatch, text: "a"), .init(kind: .grepAllMatch, text: "b")]
        let newTokens: [SearchToken] = [.init(kind: .grep, text: "a"), .init(kind: .grepAllMatch, text: "b")]
        let handledTokens = SearchTokensHandler.handle(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens.first!.kind == .grep )
        #expect(handledTokens.last!.kind == .grep )
    }

    @Test func handleGrepAllMath() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .grep, text: "a")]
        let newTokens: [SearchToken] = [.init(kind: .grep, text: "a"), .init(kind: .grepAllMatch, text: "b")]
        let handledTokens = SearchTokensHandler.handle(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens.first!.kind == .grepAllMatch )
        #expect(handledTokens.last!.kind == .grepAllMatch )
    }

    @Test func handleGrepAllMathInEdit() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .grep, text: "a"), .init(kind: .grep, text: "b")]
        let newTokens: [SearchToken] = [.init(kind: .grep, text: "a"), .init(kind: .grepAllMatch, text: "b")]
        let handledTokens = SearchTokensHandler.handle(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens.first!.kind == .grepAllMatch )
        #expect(handledTokens.last!.kind == .grepAllMatch )
    }

    @Test func handleS() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .g, text: "a")]
        let newTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .g, text: "a"), .init(kind: .s, text: "b"),]
        let handledTokens = SearchTokensHandler.handle(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens.last!.kind == .s )
        #expect(handledTokens.count == 2 )
    }

    @Test func handleS2() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .s, text: "a")]
        let newTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .s, text: "a"), .init(kind: .s, text: "b"),]
        let handledTokens = SearchTokensHandler.handle(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens == [.init(kind: .grep, text: "c"), .init(kind: .s, text: "b"),] )

    }

    @Test func handleSInEdit() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .g, text: "a"), .init(kind: .grep, text: "c")]
        let newTokens: [SearchToken] = [.init(kind: .s, text: "a"), .init(kind: .grep, text: "c")]
        let handledTokens = SearchTokensHandler.handle(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens == newTokens )
    }

    @Test func handleG() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .s, text: "a")]
        let newTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .s, text: "a"), .init(kind: .g, text: "b")]
        let handledTokens = SearchTokensHandler.handle(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens.last!.kind == .g )
        #expect(handledTokens.count == 2 )
    }

    @Test func handleG2() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .g, text: "a")]
        let newTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .g, text: "a"), .init(kind: .g, text: "b")]
        let handledTokens = SearchTokensHandler.handle(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens == [.init(kind: .grep, text: "c"), .init(kind: .g, text: "b")])
    }

    @Test func handleGInEdit() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .s, text: "a"), .init(kind: .grep, text: "c")]
        let newTokens: [SearchToken] = [.init(kind: .g, text: "a"), .init(kind: .grep, text: "c")]
        let handledTokens = SearchTokensHandler.handle(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens == newTokens )
    }

    @Test func handleAuthor() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .s, text: "a")]
        let newTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .s, text: "a"), .init(kind: .author, text: "a")]
        let handledTokens = SearchTokensHandler.handle(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens == [.init(kind: .grep, text: "c"), .init(kind: .s, text: "a"), .init(kind: .author, text: "a")] )
    }

    @Test func handleAuthor2() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .author, text: "a")]
        let newTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .author, text: "a"), .init(kind: .author, text: "b")]
        let handledTokens = SearchTokensHandler.handle(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens == [.init(kind: .grep, text: "c"), .init(kind: .author, text: "b")] )
    }

    @Test func handleAuhorInEdit() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .author, text: "a"), .init(kind: .grep, text: "c")]
        let newTokens: [SearchToken] = [.init(kind: .author, text: "a"), .init(kind: .author, text: "c")]
        let handledTokens = SearchTokensHandler.handle(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens == [.init(kind: .author, text: "c")] )
    }

    @Test func testSaveAndRetrieveSearchHistory() async throws {
        let handler = SearchTokensHandler()

        // テスト用のトークンを作成
        let token1 = SearchToken(name: "Test1", kind: .grep)
        let token2 = SearchToken(name: "Test2", kind: .author)
        let token3 = SearchToken(name: "Test3", kind: .g)

        // トークンを保存
        handler.saveSearchToken(token1)
        handler.saveSearchToken(token2)
        handler.saveSearchToken(token3)

        // 保存された履歴を取得
        let history = handler.getSearchHistory()

        // 検証
        #expect(history.count == 3)
        #expect(history[0].name == "Test3")
        #expect(history[1].name == "Test2")
        #expect(history[2].name == "Test1")

        // 最大件数を超える場合のテスト
        let token4 = SearchToken(name: "Test4", kind: .s)
        let token5 = SearchToken(name: "Test5", kind: .grepAllMatch)
        let token6 = SearchToken(name: "Test6", kind: .revisionRange)

        handler.saveSearchToken(token4)
        handler.saveSearchToken(token5)
        handler.saveSearchToken(token6)

        let updatedHistory = handler.getSearchHistory()

        // 最大5件に制限されていることを確認
        #expect(updatedHistory.count == 5)
        #expect(updatedHistory[0].name == "Test6")
        #expect(updatedHistory[4].name == "Test2")
    }
}
