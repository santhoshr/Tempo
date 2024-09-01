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
    @State private var createDiffError: Error?
    @State private var commitMessage = ""
    @State private var error: Error?
    @State private var isAmend = false
    @State private var amendCommit: Commit?
    var onCommit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if let cachedDiff, !cachedDiff.fileDiffs.isEmpty {
                    NotCommittedDiffView(title: "Staged", fileDiffs: cachedDiff.fileDiffs)
                }

                if let diff {
                    NotCommittedDiffView(title: "Not Staged",fileDiffs: diff.fileDiffs) { fileDiff, chunk in
                        self.diff = diff.toggleChunkStage(chunk, in: fileDiff)
                    }
                }

                if let createDiffError {
                    Label(createDiffError.localizedDescription, systemImage: "exclamationmark.octagon")
                    Text(cachedDiffRaw + diffRaw)
                        .padding()
                        .font(Font.system(.body, design: .monospaced))
                }
            }
            .safeAreaInset(edge: .top, spacing: 0, content: {
                VStack(spacing: 0) {
                    HStack {
                        Text("Header")
                        Spacer()
                        Button("Add All") {
                            Task {
                                do {
                                    try await Process.output(GitAdd(directory: folder.url))
                                    await updateDiffs()
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                        Button("Restore All") {
                            Task {
                                do {
                                    try await Process.output(GitRestore(directory: folder.url))
                                    await updateDiffs()
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                    }
                    .padding()
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
                    .disabled(commitMessage.isEmpty)
                    Toggle("Amend", isOn: $isAmend)
                        .font(.caption)
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
        .task {
            await updateDiffs()

            do {
                amendCommit = try await Process.output(GitLog(directory: folder.url)).first
            } catch {
                self.error = error
            }
        }
        .errorAlert($error)
    }

    private func updateDiffs() async {
        do {
            cachedDiffRaw = try await Process.output(GitDiffCached(directory: folder.url))
            diffRaw = try await Process.output(GitDiff(directory: folder.url))
            cachedDiff = try Diff(raw: cachedDiffRaw)
            diff = try Diff(raw: diffRaw)
        } catch {
            createDiffError = error
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
