//
//  MessageTemplateSuggestionView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/10.
//

import SwiftUI
import Collections

struct CommitMessageSuggestionView: View {
    @State private var messageTemplates = OrderedSet<MessageTemplate>()
    @State private var error: Error?
    @State private var isPresenting = false
    var onSelect: (String) -> Void
    @Environment(\.openWindow) private var openWindow
    @AppStorage (UserDefaults.Key.messageTemplate.rawValue) var messageTemplate: Data?
    var commitMessageTemplate: OrderedSet<MessageTemplate> {
        guard let messageTemplate = messageTemplate else { return [] }
        guard let m = try? MessageTemplateStore.messageTemplates(data: messageTemplate) else { return [] }
        return m
    }

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(commitMessageTemplate) { template in
                        Button(template.message) {
                            onSelect(template.message)
                        }
                        .buttonStyle(.borderless)
                        if template != commitMessageTemplate.last {
                            Text("|")
                                .foregroundStyle(.separator)
                        }
                    }
                }
                .padding(.leading, 14)
            }
            .frame(height: 44)
            Button(action: {
                openWindow(id: "messageTemplate")
            }, label: {
                Image(systemName: "list.dash")
            })
            .padding([.horizontal], 14)
        }
        .onAppear {
            do {
                messageTemplates = try MessageTemplateStore.messageTemplates()
            } catch {
                self.error = error
            }
        }
        .errorAlert($error)
    }
}

#Preview {
    CommitMessageSuggestionView { print($0) }
}
