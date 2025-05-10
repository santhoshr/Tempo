//
//  SerachTokensHandler.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/03.
//

struct SearchTokensHandler {
    static private func newToken(old: [SearchToken], new: [SearchToken]) -> SearchToken? {
        new.first { !old.contains($0) }
    }

    static func searchTokenHistory(currentHistory: [SearchToken], old: [SearchToken], new: [SearchToken]) -> [SearchToken] {
        guard let newToken = SearchTokensHandler.newToken(old: old, new: new) else { return currentHistory }
        var history = currentHistory
        history.removeAll { $0 == newToken }
        history.insert(newToken, at: 0)
        return Array(history.prefix(10))
    }

    static func handle(oldTokens: [SearchToken], newTokens: [SearchToken]) -> [SearchToken] {
        if let newToken = newToken(old: oldTokens, new: newTokens) {
            switch newToken.kind {
            case .grep, .grepAllMatch:
                return newTokens.map { token in
                    switch token.kind {
                    case .grep, .grepAllMatch:
                        var updateToken = token
                        updateToken.kind = newToken.kind
                        return updateToken
                    case .s, .g, .author, .revisionRange, .untoken:
                        return token
                    }
                }
            case .s:
                return newTokens.filter { token in
                    switch token.kind {
                    case .grep, .grepAllMatch, .author, .revisionRange, .untoken:
                        return true
                    case .s:
                        return token == newToken
                    case .g:
                        return false
                    }
                }
            case .g:
                return newTokens.filter { token in
                    switch token.kind {
                    case .grep, .grepAllMatch, .author, .revisionRange, .untoken:
                        return true
                    case .g:
                        return token == newToken
                    case .s:
                        return false
                    }
                }
            case .author:
                return newTokens.filter { token in
                    switch token.kind {
                    case .grep, .grepAllMatch, .g, .s, .revisionRange, .untoken:
                        return true
                    case .author:
                        return token == newToken
                    }
                }
            case .revisionRange:
                return newTokens.filter { token in
                    switch token.kind {
                    case .grep, .grepAllMatch, .g, .s, .author, .untoken:
                        return true
                    case .revisionRange:
                        return token == newToken
                    }
                }
            case .untoken:
                return newTokens
            }
        } else {
            return newTokens
        }
    }
}
