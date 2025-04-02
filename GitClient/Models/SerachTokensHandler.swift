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
                return newTokens.map { value in
                    switch value.kind {
                    case .grep, .grepAllMatch:
                        var newValue = value
                        newValue.kind = last.kind
                        return newValue
                    default:
                        return value
                    }
                }
            default:
                break
            }
        }
        return newTokens
    }
}
