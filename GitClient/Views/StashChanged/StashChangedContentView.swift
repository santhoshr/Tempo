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
    @State var selectionStashID: Int?
    @State private var error: Error?
    var onTapDropButton: ((Stash) -> Void)?

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
            VStack(spacing: 0) {
                if let selectionStashID {
                    StashChangedDetailView(index: selectionStashID, folder: folder)
                } else {
                    Spacer()
                    Text("No Selection")
                        .foregroundStyle(.secondary)
                        .padding()
                }
                Spacer(minLength: 0)
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
                                    showingStashChanged = false
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                        .keyboardShortcut(.init(.return))
                        .disabled(selectionStashID == nil)
                    }
                    .padding()
                    .background(.bar)
                }
            })
        }
        .frame(minWidth: 600, minHeight: 500)
        .errorAlert($error)
    }
}

#Preview {
    @State var showingStashChanged = false
    return StashChangedContentView(folder: .init(url: URL(string: "file:///maoyama/Projects/")!), showingStashChanged: $showingStashChanged)
}

