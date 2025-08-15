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
        var model: String
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
    var apiURL: String
    var systemPrompt: String
    var model: String
    var stagingPrompt: String
    private var endpoint: URL {
        URL(string: apiURL)!
    }
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
            model: model,
            messages: [
                .init(role: "system", content: systemPrompt),
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
            model: model,
            messages: [
                .init(role: "system", content: stagingPrompt),
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
