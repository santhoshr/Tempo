//
//  StashChangedView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/14.
//

import SwiftUI

struct StashChangedView: View {
    var folder: Folder
    @Binding var showingStashChanged: Bool
    @State var stashList: [Stash]?
    @State private var error: Error?

    var body: some View {
        StashChangedContentView(folder: folder, showingStashChanged: $showingStashChanged, stashList: stashList)
        .task {
            do {
               stashList = try await Process.output(GitStashList(directory: folder.url))
            } catch {
                self.error = error
            }
        }
        .errorAlert($error)
    }
}

private struct StashChangedContentView: View {
    var folder: Folder
    @Binding var showingStashChanged: Bool
    var stashList: [Stash]?

    var body: some View {
        NavigationSplitView {
            List {
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
                        }
                    }
                }
            }
        } detail: {

        }
        .frame(minWidth: 600, minHeight: 500)
        .safeAreaInset(edge: .bottom, content: {
            VStack (spacing: 0) {
                Divider()
                HStack {
                    Spacer()
                    Button("Cancel") {
                        showingStashChanged.toggle()
                    }
                    Button("Apply") {

                    }
                    .keyboardShortcut(.init(.return))
                }
                .padding()
            }
            .background(.bar)
        })
    }
}

#Preview {
    @State var showingStashChanged = false
    return StashChangedContentView(folder: .init(url: URL(string: "file:///maoyama/Projects/")!), showingStashChanged: $showingStashChanged)
}

