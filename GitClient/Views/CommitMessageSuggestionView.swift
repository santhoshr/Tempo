//
//  MessageSnippetSuggestionView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/10.
//

import SwiftUI

struct CommitMessageSuggestionView: View {
    @State private var error: Error?
    @State private var isPresenting = false
    @Environment(\.openWindow) private var openWindow
    @AppStorage (AppStorageKey.commitMessageSnippet.rawValue) var commitMessageSnippet: Data = AppStorageDefaults.commitMessageSnippets
    var decodedCommitMessageSnippet: Array<String> {
        do {
            do {
                return try JSONDecoder().decode(Array<String>.self, from: commitMessageSnippet)
            } catch {
                return []
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(decodedCommitMessageSnippet, id: \.self) { snippet in
                        Button(snippet) {
                            NotificationCenter.default.post(name: .didSelectCommitMessageSnippetNotification, object: snippet)
                        }
                        .buttonStyle(.borderless)
                        if snippet != decodedCommitMessageSnippet.last {
                            Text("|")
                                .foregroundStyle(.separator)
                        }
                    }
                }
                .padding(.leading, 14)
            }
            .frame(height: 44)
            Button(action: {
                openWindow(id: WindowID.commitMessageSnippets.rawValue)
            }, label: {
                Image(systemName: "list.dash")
            })
            .padding([.horizontal], 14)
        }
        .errorAlert($error)
    }
}

#Preview {
    CommitMessageSuggestionView()
}
