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
        let instructions = "You are a good software engineer."
        let prompt = "Please provide an appropriate commit message for the following git diff output:\(stagedDiff)"
        let session = LanguageModelSession(instructions: instructions)
        return try await session.respond(to: prompt, generating: GeneratedCommitMessage.self).content.commitMessage
    }
}
