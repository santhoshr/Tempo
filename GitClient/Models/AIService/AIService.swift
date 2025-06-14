//
//  AIService.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/29.
//

import Foundation
import os

struct AIService {
    private struct Schema<T: Codable>: Codable {
        var type = "object"
        var properties: T
        var required: [String]
        var additionalProperties = false
    }
    private struct JSONSchema<T: Codable>: Codable {
        var name: String
        var schema: Schema<T>
        var strict = true
    }
    private struct ResponseFormat<T: Codable>: Codable {
        var type = "json_schema"
        var jsonSchema: JSONSchema<T>

        enum CodingKeys: String, CodingKey {
            case type
            case jsonSchema = "json_schema"
        }
    }
    private struct Message: Codable {
        var role: String
        var content: String
    }
    private struct RequestBody<T: Codable>: Codable {
        var model = "gpt-4o-mini"
        var messages: [Message]
        var responseFormat: ResponseFormat<T>

        enum CodingKeys: String, CodingKey {
            case model
            case messages
            case responseFormat = "response_format"
        }
    }
    private struct Choice: Codable, CustomStringConvertible {
        var description: String { "Choice(message: \(message)"}

        struct Message: Codable {
            var content: String
            var refusal: String?
        }
        var message: Message
    }
    private struct Response: Codable, CustomStringConvertible {
        var description: String {
            "Response(choices: \(choices)"
        }

        var choices: [Choice]
    }

    var bearer: String
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private var jsonEncoder: JSONEncoder {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        return jsonEncoder
    }

    private func callEndpint<SchemaProperties: Codable, DecodeType: Codable>(requestBody: RequestBody<SchemaProperties>) async throws -> DecodeType {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AIService")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        let bodyData = try jsonEncoder.encode(requestBody)
        request.httpBody = bodyData
        if let jsonString = String(data: bodyData, encoding: .utf8) {
            logger.debug("Body data: \(jsonString, privacy: .public)")
        }
        let data = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(Response.self, from: data.0)
        logger.debug("Response: \(response, privacy: .public)")
        guard response.choices.count > 0 else {
            throw GenericError(errorDescription: "OpenAI API response error")
        }
        if let refusal = response.choices[0].message.refusal, !refusal.isEmpty {
            throw GenericError(errorDescription: "OpenAI API refusal error: " + refusal)
        }
        guard let contentData = response.choices[0].message.content.data(using: .utf8) else {
            throw GenericError(errorDescription: "API Response handling error")
        }
        return try JSONDecoder().decode(DecodeType.self, from: contentData)
    }

    func commitMessage(stagedDiff: String) async throws -> String {
        let body = RequestBody(
            messages: [
                .init(role: "system", content: "You are good software engineer. Tell me commit message of this changes for git."),
                .init(role: "user", content: stagedDiff)
            ],
            responseFormat: .init(
                jsonSchema: .init(
                    name: "generated_git_commit_message",
                    schema: Schema(properties: CommitMessageProperties(), required: ["commitMessage"])
                )
            )
        )
        let message: GeneratedCommiMessage = try await callEndpint(requestBody: body)
        return message.commitMessage
    }

    func stagingChanges(stagedDiff: String, notStagedDiff: String, untrackedFiles: [String]) async throws  -> StagingChanges {
        let body = RequestBody(
            messages: [
                .init(role: "system", content:"""
You are a good software engineer.
The first message is the diff that has already been staged. The second message is the unstaged diff. The third message consists of untracked files, separated by new lines. Please advise on what changes should be committed next. It's fine if you think it is appropriate to commit everything together.

For the unstaged diff, please indicate which hunks should be committed by answering with booleans so that the response can be used as input for git add -p. For the untracked files, please also answer with booleans for each file.

Additionally, please provide a good commit message for committing the changes that should be staged.
"""),
                .init(role: "user", content: stagedDiff),
                .init(role: "user", content: notStagedDiff),
                .init(role: "user", content: untrackedFiles.joined(separator: "\n"))
            ],
            responseFormat: .init(
                jsonSchema: .init(
                    name: "stage_changes",
                    schema: Schema(properties: StagingChangesProperties(), required: ["hunksToStage", "filesToStage", "commitMessage"])
                )
            )
        )
        return try await callEndpint(requestBody: body)
    }
}
