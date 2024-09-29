//
//  AIService.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/29.
//

import Foundation

struct AIService {
    struct Message: Codable {
        var role: String
        var content: String
    }
    struct RequestBody: Codable {
        var model = "gpt-4o-mini"
        var messages: [Message]
    }

    var bearer: String
    let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    func commitMessage(stagedDiff: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        let body = RequestBody(messages: [
            .init(role: "system", content: "Tell me commit message of this changes for git."),
            .init(role: "user", content: stagedDiff)
        ])
        let bodyData = try JSONEncoder().encode(body)
        request.httpBody = bodyData
        let data = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data.0))
        return ""
    }
}
