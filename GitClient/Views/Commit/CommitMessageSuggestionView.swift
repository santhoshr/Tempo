//
//  MessageSnippetSuggestionView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/10.
//

import SwiftUI
import Defaults

struct CommitMessageSuggestionView: View {
    @State private var error: Error?
    @State private var isPresenting = false
    @Environment(\.openWindow) private var openWindow
    @Default(.commitMessageSnippets) var commitMessageSnippets
    var decodedCommitMessageSnippet: Array<String> {
        return commitMessageSnippets
    }

    var body: some View {
        HStack {
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(decodedCommitMessageSnippet, id: \.self) { snippet in
                        Button(snippet) {
                            NotificationCenter.default.post(name: .didSelectCommitMessageSnippetNotification, object: snippet)
                        }
                        .buttonStyle(.accessoryBar)
                        if snippet != decodedCommitMessageSnippet.last {
                            Text("|")
                                .foregroundStyle(.separator)
                        }
                    }
                }
                .font(.callout)
                .padding(.leading, 12)
            }
            .frame(height: 40)
            Button(action: {
                openWindow(id: WindowID.commitMessageSnippets.rawValue)
            }, label: {
                Image(systemName: "list.dash")
            })
        }
        .errorSheet($error)
    }
}

#Preview {
    CommitMessageSuggestionView()
}
