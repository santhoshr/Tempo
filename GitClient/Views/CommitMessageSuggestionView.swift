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

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(messageTemplates) { template in
                        Button(template.message) {

                        }
                        .buttonStyle(.borderless)
                        if template != messageTemplates.last {
                            Text("|")
                                .foregroundStyle(.separator)

                        }
                    }
                }
                .padding(.leading, 14)
            }
            .frame(height: 44)
            Button(action: {

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
    CommitMessageSuggestionView()
}
