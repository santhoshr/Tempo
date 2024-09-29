//
//  AIService.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/29.
//

import Foundation

struct AIService {
    struct CommitMessageSchema: Codable {
        struct Properties: Codable {
            struct CommitMessage: Codable {
                var type = "string"
            }
            var commitMessage = CommitMessage()
        }
        var type = "object"
        var properties = Properties()
        var required = ["commitMessage"]
        var additionalProperties = false
    }

    struct Message: Codable {
        var role: String
        var content: String
    }
    struct JSONSchema: Codable {
        var name = "generated_git_commit_message"
        var schema = CommitMessageSchema()
        var strict = true
    }
    struct ResponseFormat: Codable {
        var type = "json_schema"
        var jsonSchema = JSONSchema()

        enum CodingKeys: String, CodingKey {
            case type
            case jsonSchema = "json_schema"
        }
    }
    struct RequestBody: Codable {
        var model = "gpt-4o-mini"
        var messages: [Message]
        var responseFormat = ResponseFormat()

        enum CodingKeys: String, CodingKey {
            case model
            case messages
            case responseFormat = "response_format"
        }
    }

    var bearer: String
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private var jsonEncoder: JSONEncoder {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        return jsonEncoder
    }

    func commitMessage(stagedDiff: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        let body = RequestBody(messages: [
            .init(role: "system", content: "Tell me commit message of this changes for git."),
            .init(role: "user", content: stagedDiff)
        ])
        let bodyData = try jsonEncoder.encode(body)
        request.httpBody = bodyData
        if let jsonString = String(data: bodyData, encoding: .utf8) {
            print(jsonString)
        }
        let data = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data.0))
        return ""
    }
}
