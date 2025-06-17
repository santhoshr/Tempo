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
    }

}
