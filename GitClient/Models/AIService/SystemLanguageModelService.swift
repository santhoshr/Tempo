//
//  SystemLanguageModelService.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/06/17.
//

import Foundation
import FoundationModels

@available(macOS 26.0, *)
@Generable
struct GeneratedCommitMessage {
    @Guide(description: "The commit message")
    var commitMessage: String
}

@available(macOS 26.0, *)
struct SystemLanguageModelService {
    func commitMessage(stagedDiff: String) async throws -> String {
        let instructions = "You are a good software engineer. I'll provide the result of git diff as a prompt, so please return only the commit message."
        let session = LanguageModelSession(instructions: instructions)
        return try await session.respond(to: stagedDiff, generating: GeneratedCommitMessage.self).content.commitMessage
    }
}
