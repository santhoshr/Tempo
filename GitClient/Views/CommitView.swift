//
//  CommitView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/01.
//

import SwiftUI

struct CommitView: View {
    var folder: Folder
    @State private var cachedDiffRaw = ""
    @State private var diffRaw = ""
    @State private var cachedDiff: Diff?
    @State private var diff: Diff?
    @State private var status: Status?
    @State private var updateChangesError: Error?
    @State private var commitMessage = ""
    @State private var error: Error?
    @State private var isAmend = false
    @State private var amendCommit: Commit?
    @Binding var isRefresh: Bool
    var onCommit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if let cachedDiff, !cachedDiff.fileDiffs.isEmpty {
                    StagedView(
                        fileDiffs: cachedDiff.fileDiffs,
                        onSelectFileDiff: { fileDiff in
                            let newDiff = cachedDiff.updateFileDiffStage(fileDiff, stage: false)
                            restorePatch(newDiff)
                        },
                        onSelectChunk: { fileDiff, chunk in
                            let newDiff = cachedDiff.updateChunkStage(chunk, in: fileDiff, stage: false)
                            restorePatch(newDiff)
                        }
                    )
                }

                if let diff, !diff.fileDiffs.isEmpty {
                    NotStagedView(
                        fileDiffs: diff.fileDiffs,
                        untrackedFiles: status?.untrackedFiles ?? [],
                        onSelectFileDiff: { fileDiff in
                            let newDiff = diff.updateFileDiffStage(fileDiff, stage: true)
                            addPatch(newDiff)
                        },
                        onSelectChunk: { fileDiff, chunk in
                            let newDiff = diff.updateChunkStage(chunk, in: fileDiff, stage: true)
                            addPatch(newDiff)
                        },
                        onSelectUntrackedFile: { file in
                            Task {
                                do {
                                    try await Process.output(GitAddPathspec(directory: folder.url, pathspec: file))
                                    await updateChanges()
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                    )
                }

                if let updateChangesError {
                    Label(updateChangesError.localizedDescription, systemImage: "exclamationmark.octagon")
                    Text(cachedDiffRaw + diffRaw)
                        .padding()
                        .font(Font.system(.body, design: .monospaced))
                }
            }
            .safeAreaInset(edge: .top, spacing: 0, content: {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button("Stage All") {
                            Task {
                                do {
                                    try await Process.output(GitAdd(directory: folder.url))
                                    await updateChanges()
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                        .disabled(diffRaw.isEmpty)
                        Button("Unstage All") {
                            Task {
                                do {
                                    try await Process.output(GitRestore(directory: folder.url))
                                    await updateChanges()
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                        .disabled(cachedDiffRaw.isEmpty)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    Divider()
                }
                .background(Color(nsColor: .textBackgroundColor))
            })
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            .background(Color(NSColor.textBackgroundColor))
            Divider()
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    ZStack {
                            TextEditor(text: $commitMessage)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                            if commitMessage.isEmpty {
                                Text("Enter commit message here")
                                    .foregroundColor(.secondary)
                                    .allowsHitTesting(false)
                            }
                    }
                    .frame(height: 80)
                    CommitMessageSuggestionView()
                }
                Divider()
                VStack(spacing: 14) {
                    Button("Commit") {
                        Task {
                            do {
                                if isAmend {
                                    try await Process.output(GitCommitAmend(directory: folder.url, message: commitMessage))
                                } else {
                                    try await Process.output(GitCommit(directory: folder.url, message: commitMessage))
                                }
                                onCommit()
                            } catch {
                                self.error = error
                            }
                        }
                    }
                    .keyboardShortcut(.init(.return))
                    .disabled(cachedDiffRaw.isEmpty || commitMessage.isEmpty)
                    Toggle("Amend", isOn: $isAmend)
                        .font(.caption)
                        .padding(.trailing, 6)
                }
                .onChange(of: isAmend) {
                    if isAmend {
                        commitMessage = amendCommit?.rawBody ?? ""
                    } else {
                        commitMessage = ""
                    }
                }
                .padding()
            }
            .background(Color(NSColor.textBackgroundColor))
            .onReceive(NotificationCenter.default.publisher(for: .didSelectCommitMessageSnippetNotification), perform: { notification in
                if let commitMessage = notification.object as? String {
                    self.commitMessage = commitMessage
                }
            })
        }
        .onChange(of: isRefresh, { oldValue, newValue in
            if newValue {
                Task {
                    await updateChanges()
                }
            }
        })
        .task {
            await updateChanges()

            do {
                amendCommit = try await Process.output(GitLog(directory: folder.url)).first
            } catch {
                self.error = error
            }
        }
        .errorAlert($error)
    }

    private func updateChanges() async {
        do {
            cachedDiffRaw = try await Process.output(GitDiffCached(directory: folder.url))
            diffRaw = try await Process.output(GitDiff(directory: folder.url))
            cachedDiff = try Diff(raw: cachedDiffRaw)
            diff = try Diff(raw: diffRaw)
            status = try await Process.output(GitStatus(directory: folder.url))
        } catch {
            updateChangesError = error
        }
    }

    private func restorePatch(_ newDiff: Diff) {
        Task {
            do {
                try await Process.output(GitRestorePatch(directory: folder.url, inputs: newDiff.unstageStrings()))
                await updateChanges()
            } catch {
                self.error = error
            }
        }
    }

    private func addPatch(_ newDiff: Diff) {
        Task {
            do {
                try await Process.output(GitAddPatch(directory: folder.url, inputs: newDiff.stageStrings()))
                await updateChanges()
            } catch {
                self.error = error
            }
        }
    }
}

//struct CommitView_Previews: PreviewProvider {
//    static var previews: some View {
//        CommitView(diffRaw: """
//diff --git a/GitClient/Views/DiffView.swift b/GitClient/Views/DiffView.swift
//index 0cd5c16..114b4ae 100644
//--- a/GitClient/Views/DiffView.swift
//+++ b/GitClient/Views/DiffView.swift
//@@ -11,11 +11,25 @@ struct DiffView: View {
//     var diff: String
//
//     var body: some View {
//-        ScrollView {
//-            Text(diff)
//-                .font(Font.system(.body, design: .monospaced))
//-                .frame(maxWidth: .infinity, alignment: .leading)
//-                .padding()
//+        ZStack {
//+            ScrollView {
//+                Text(diff)
//+                    .textSelection(.enabled)
//+                    .font(Font.system(.body, design: .monospaced))
//+                    .frame(maxWidth: .infinity, alignment: .leading)
//+                    .padding()
//+            }
//+            VStack {
//+                Spacer()
//+                HStack {
//+                    Spacer()
//+                    Button("Commit") {
//+
//+                    }
//+                    .padding()
//+                }
//+                .background(.ultraThinMaterial)
//+            }
//         }
//     }
// }
//diff --git a/GitClient/Views/DiffView.swift b/GitClient/Views/DiffView.swift
//index 0cd5c16..114b4ae 100644
//--- a/GitClient/Views/DiffView.swift
//+++ b/GitClient/Views/DiffView.swift
//@@ -11,11 +11,25 @@ struct DiffView: View {
//     var diff: String
//
//     var body: some View {
//-        ScrollView {
//-            Text(diff)
//-                .font(Font.system(.body, design: .monospaced))
//-                .frame(maxWidth: .infinity, alignment: .leading)
//-                .padding()
//+        ZStack {
//+            ScrollView {
//+                Text(diff)
//+                    .textSelection(.enabled)
//+                    .font(Font.system(.body, design: .monospaced))
//+                    .frame(maxWidth: .infinity, alignment: .leading)
//+                    .padding()
//+            }
//+            VStack {
//+                Spacer()
//+                HStack {
//+                    Spacer()
//+                    Button("Commit") {
//+
//+                    }
//+                    .padding()
//+                }
//+                .background(.ultraThinMaterial)
//+            }
//         }
//     }
// }
//
//""", folder: .init(url: .init(string: "file:///maoyama")!), onCommit: {})
//    }
//}
