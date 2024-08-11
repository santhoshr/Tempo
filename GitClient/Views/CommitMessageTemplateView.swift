//
//  CommitMessageTemplateView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/11.
//

import SwiftUI

struct CommitMessageTemplateView: View {
    @AppStorage (AppStorageKey.commitMessageTemplate.rawValue) var commitMessageTemplate: Data = AppStorageDefaults.commitMessageTemplate
    var decodedCommitMessageTemplates: Array<String> {
        do {
            return try JSONDecoder().decode(Array<String>.self, from: commitMessageTemplate)
        } catch {
            return []
        }
    }
    @State private var editCommitMessageTemplate: String = ""

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(decodedCommitMessageTemplates, id: \.self) { template in
                    HStack {
                        Button(template) {
                            NotificationCenter.default.post(name: .didSelectCommitMessageTemplateNotification, object: template)
                        }
                            .buttonStyle(.borderless)
                        Spacer()
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.secondary)
                    }
                    .contextMenu {
                        Button("Delete") {
                            var templates = decodedCommitMessageTemplates
                            templates.removeAll { $0 == template }
                            do {
                                commitMessageTemplate = try JSONEncoder().encode(templates)
                            } catch {
                                print(error)
                            }
                        }
                    }
                }
                .onMove(perform: { indices, newOffset in
                    var t = decodedCommitMessageTemplates
                    t.move(fromOffsets: indices, toOffset: newOffset)
                    do {
                        commitMessageTemplate = try JSONEncoder().encode(t)
                    } catch {
                        print(error)
                    }
                })
            }
            Divider()
            HStack(spacing: 0) {
                ZStack {
                    TextEditor(text: $editCommitMessageTemplate)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                    if editCommitMessageTemplate.isEmpty {
                        Text("Enter commit message template here")
                            .foregroundColor(.secondary)
                            .allowsHitTesting(false)
                    }
                }
                Divider()
                Button("Add") {
                    let newCommitMessageTemplates = decodedCommitMessageTemplates + [editCommitMessageTemplate]
                    do {
                        commitMessageTemplate = try JSONEncoder().encode(newCommitMessageTemplates)
                        editCommitMessageTemplate = ""
                    } catch {
                        print(error)
                    }
                }
                .keyboardShortcut(.init(.return))
                .disabled(editCommitMessageTemplate.isEmpty)
                .padding()

            }
            .frame(height: 80)
            .background(Color(NSColor.textBackgroundColor))
        }
    }
}

#Preview {
    CommitMessageTemplateView()
}
