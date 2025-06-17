//
//  SystemLanguageModelServiceTests.swift
//  GitClientTests
//
//  Created by Makoto Aoyama on 2025/06/17.
//

import Testing
@testable import Tempo

struct SystemLanguageModelServiceTests {

    @available(macOS 26.0, *)
    @Test func commitMessage() async throws {
        let message = try await SystemLanguageModelService().commitMessage(stagedDiff: """
            diff --git a/GitClient/Views/Folder/CommitGraphView.swift b/GitClient/Views/Folder/CommitGraphView.swift
            index 5f79207..4660cf4 100644
            --- a/GitClient/Views/Folder/CommitGraphView.swift
            +++ b/GitClient/Views/Folder/CommitGraphView.swift
            @@ -51,7 +51,6 @@ struct CommitGraphView: View {
                             .padding(.bottom, 22)
                         }
                     }
            -        .background(Color(NSColor.textBackgroundColor))
                     .focusable()
                     .focusEffectDisabled()
                     .onMoveCommand { direction in
            """)
        print(message)
        #expect(!message.isEmpty)

        let message2 = try await SystemLanguageModelService().commitMessage(stagedDiff: """
            diff --git a/GitClient/Models/Observables/LogStore.swift b/GitClient/Models/Observables/LogStore.swift
            index 8a43562..226c84e 100644
            --- a/GitClient/Models/Observables/LogStore.swift
            +++ b/GitClient/Models/Observables/LogStore.swift
            @@ -147,6 +147,24 @@ import Observation
                     }
                 }
             
            +    func nextLogID(logID: String) -> String? {
            +        if logID == Log.notCommitted.id {
            +            return commits.first?.id
            +        }
            +        let commit = commits.first { $0.id == logID }
            +        guard let commit else { return nil }
            +        return commit.parentHashes.last
            +    }
            +
            +    func previousLogID(logID: String) -> String? {
            +        if logID == Log.notCommitted.id {
            +            return nil
            +        }
            +        let index = commits.firstIndex { $0.id == logID }
            +        guard let index, index != 0 else { return nil }
            +        return commits[index - 1].id
            +    }
            +
                 private func notCommited(directory: URL) async throws -> NotCommitted {
                     let gitDiff = try await Process.output(GitDiff(directory: directory))
                     let gitDiffCached = try await Process.output(GitDiffCached(directory: directory))
            """)
        print(message2)
        #expect(!message2.isEmpty)

    }

}
