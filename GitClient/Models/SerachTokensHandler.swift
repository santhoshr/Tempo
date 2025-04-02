//
//  SerachTokensHandler.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/03.
//

struct SerachTokensHandler {
    static func handle(_ newTokens: [SearchToken]) -> [SearchToken] {
        if let last = newTokens.last {
            switch last.kind {
            case .grep, .grepAllMatch:
                return newTokens.map { token in
                    switch token.kind {
                    case .grep, .grepAllMatch:
                        var newToken = token
                        newToken.kind = last.kind
                        return newToken
                    default:
                        return token
                    }
                }
            case .s:
                return newTokens.filter { token in
                    switch token.kind {
                    case .grep, .grepAllMatch, .s:
                        return true
                    case .g:
                        return false
                    }
                }
            case .g:
                return newTokens.filter { token in
                    switch token.kind {
                    case .grep, .grepAllMatch, .g:
                        return true
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
