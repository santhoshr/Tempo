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
        let instructions = """
You are a good software engineer. When creating a commit message, it is not the initial commit. 
The output format of git diff is as follows:
```
diff --git a/filename b/filename
index abc1234..def5678 100644
--- a/filename
+++ b/filename
@@ -start,count +start,count @@ optional context or function name
- line that was removed
+ line that was added
  unchanged line (context)
```
"""
        let prompt = "Please provide an appropriate commit message for the following changes: \(stagedDiff)"
        let session = LanguageModelSession(instructions: instructions)
        return try await session.respond(to: prompt, generating: GeneratedCommitMessage.self).content.commitMessage
    }
    
    /// Toolを使っても特に精度は良くない。Toolを利用することでインプットする情報としては整理されていると思ったのだけど。。。
    func commitMessage(tools: [any Tool]) async throws -> String {
        let instructions = """
You are a good software engineer. When creating a commit message, it is not the initial commit.
"""
        let prompt = "Please provide an appropriate commit message for staged changes of uncommitted changes"
        let session = LanguageModelSession(tools: tools, instructions: instructions)
        return try await session.respond(to: prompt, generating: GeneratedCommitMessage.self).content.commitMessage
    }

}

@available(macOS 26.0, *)
struct UncommitedChangesTool: Tool {
    @Generable
    struct Arguments {}
    
    let name = "uncommitedChanges"
    let description: String = "Get a uncommitted changes"
    let directory: URL
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        let gitDiff = try await Process.output(GitDiff(directory: directory))
        let gitDiffCached = try await Process.output(GitDiffCached(directory: directory))
        let diff = try Diff(raw: gitDiff).fileDiffs.map { $0.raw }
        let cachedDiff = try Diff(raw: gitDiffCached).fileDiffs.map { $0.raw }
        return ToolOutput(GeneratedContent(properties: ["stagedChanges": cachedDiff, "unstagedChanges": diff]))
    }
}
