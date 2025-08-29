//
//  StashChangedContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/16.
//

import SwiftUI

struct StashChangedContentView: View {
    var folder: Folder
    @Binding var showingStashChanged: Bool
    var stashList: [Stash]?
    @State private var selectionStashID: Int?
    @State private var fileDiffs: [ExpandableModel<FileDiff>] = []
    @State private var error: Error?
    var onTapDropButton: ((Stash) -> Void)?
    var onStashApplied: (() -> Void)?
    var onNavigateToUncommitted: (() -> Void)?

    var body: some View {
        NavigationSplitView {
            List(selection: $selectionStashID) {
                Text("Stash Changed")
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(2)
                if let stashList {
                    if stashList.isEmpty {
                        Text("No Content")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(stashList) { stash in
                            Text(stash.message)
                                .lineLimit(3)
                                .contextMenu {
                                    Button("Drop") {
                                        onTapDropButton?(stash)
                                        selectionStashID = nil
                                    }
                                }
                        }
                    }
                }
            }
        } detail: {
            ScrollView {
                VStack(spacing: 0) {
                    if selectionStashID != nil {
                        StashChangedDetailContentView(fileDiffs: $fileDiffs)
                    } else {
                        Spacer()
                        Text("No Selection")
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 250)
                    }
                    Spacer(minLength: 0)
                }
            }
            .safeAreaInset(edge: .bottom, content: {
                VStack (spacing: 0) {
                    Divider()
                    HStack {
                        Spacer()
                        Button("Cancel") {
                            showingStashChanged.toggle()
                        }
                        Button("Apply") {
                            Task {
                                do {
                                    try await Process.output(GitStashApply(directory: folder.url, index: selectionStashID!))
                                    onStashApplied?()
                                    showingStashChanged = false
                                    onNavigateToUncommitted?()
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.init(.defaultAction))
                        .disabled(selectionStashID == nil)
                        Button("Apply & Clear") {
                            Task {
                                do {
                                    try await Process.output(GitStashApply(directory: folder.url, index: selectionStashID!))
                                    try await Process.output(GitStashDrop(directory: folder.url, index: selectionStashID!))
                                    onStashApplied?()
                                    showingStashChanged = false
                                    onNavigateToUncommitted?()
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(selectionStashID == nil)
                    }
                    .padding()
                    .background(.bar)
                }
            })
        }
        .onChange(of: selectionStashID, {
            Task {
                await updateDiff()
            }
        })
        .frame(minWidth: 800, minHeight: 700)
        .errorSheet($error)
    }

    private func updateDiff() async {
        do {
            if let index = selectionStashID {
                let diff = try await Process.output(GitStashShowDiff(directory: folder.url, index: index))
                fileDiffs = try Diff(raw: diff).fileDiffs.map { ExpandableModel(isExpanded: true, model: $0) }
            } else {
                fileDiffs = []
            }
        } catch {
            self.error = error
        }
    }
}

#Preview {
    @Previewable @State var showingStashChanged = false
    return StashChangedContentView(folder: .init(url: URL(string: "file:///maoyama/Projects/")!), showingStashChanged: $showingStashChanged)
}

