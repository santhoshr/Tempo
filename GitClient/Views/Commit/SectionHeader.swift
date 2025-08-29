//
//  SectionHeader.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/08.
//

import SwiftUI

struct SectionHeader: View {
    var title: String
    var contextMenuOptions: [ContextMenuOption]? // Context menu options
    var onContextMenuAction: ((String) -> Void)? // Context menu action callback
    
    struct ContextMenuOption: Identifiable {
        let id = UUID()
        let title: String
        let systemImage: String
        let action: String
    }

    var body: some View {
        Menu {
            // Left-click: Flat menu
            if let contextMenuOptions, !contextMenuOptions.isEmpty {
                ForEach(contextMenuOptions) { option in
                    Button(action: {
                        onContextMenuAction?(option.action)
                    }) {
                        Label(option.title, systemImage: option.systemImage)
                    }
                }
            } else {
                Text("No navigation options available")
                    .foregroundStyle(.secondary)
            }
        } label: {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .textSelection(.disabled)
                .foregroundColor(.primary)
        }
        .menuStyle(.borderlessButton)
        .disabled(contextMenuOptions?.isEmpty != false)
        .contextMenu {
            // Right-click: Same options (flat for section headers)
            if let contextMenuOptions, !contextMenuOptions.isEmpty {
                ForEach(contextMenuOptions) { option in
                    Button(action: {
                        onContextMenuAction?(option.action)
                    }) {
                        Label(option.title, systemImage: option.systemImage)
                    }
                }
            } else {
                Text("No navigation options available")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    return SectionHeader(
        title: "Staged",
        contextMenuOptions: [
            SectionHeader.ContextMenuOption(
                title: "Unstaged Changes", 
                systemImage: "minus.circle", 
                action: "unstaged"
            ),
            SectionHeader.ContextMenuOption(
                title: "Untracked Files", 
                systemImage: "plus.circle", 
                action: "untracked"
            )
        ],
        onContextMenuAction: { action in
            print("Context menu action: \(action)")
        }
    )
}
