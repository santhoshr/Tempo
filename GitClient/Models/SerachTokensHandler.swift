//
//  SerachTokensHandler.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/03.
//

struct SerachTokensHandler {
    static func newToken(old: [SearchToken], new: [SearchToken]) -> SearchToken? {
        new.first { !old.contains($0) }
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
                    default:
                        return token
                    }
                }
            case .s:
                return newTokens.filter { token in
                    switch token.kind {
                    case .grep, .grepAllMatch:
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
                    case .grep, .grepAllMatch:
                        return true
                    case .g:
                        return token == newToken
                    case .s:
                        return false
                    }
                }
            }
        } else {
            return newTokens
        }
    }
}
