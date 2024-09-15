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
        NavigationSplitView {
            if let stashList {
                if stashList.isEmpty {
                    List {
                        Text("No Content")
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                } else {
                    List(stashList) { stash in
                        Text(stash.message)
                            .lineLimit(3)
                    }
                }
            } else {
                List {}
            }
        } detail: {

        }
        .navigationTitle("Stash Changed")
        .frame(minWidth: 500, minHeight: 400)
        .task {
            do {
               stashList = try await Process.output(GitStashList(directory: folder.url))
            } catch {
                self.error = error
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

                    }
                    .keyboardShortcut(.init(.return))
                }
                .padding()
            }
            .background(.bar)
        })
        .errorAlert($error)
    }
}
