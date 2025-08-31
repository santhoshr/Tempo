//
//  NoteFileRow.swift
//  GitClient
//
//  Created by Claude on 2025/08/31.
//

import SwiftUI

struct NoteFileRow: View {
    let noteFile: NoteFile
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // File icon
            Image(systemName: "doc.text")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                // File name
                Text(noteFile.name)
                    .font(.system(.subheadline, weight: isSelected ? .medium : .regular))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                // Show relative path if file is in a subdirectory
                if noteFile.relativePath != noteFile.name {
                    Text(noteFile.relativePath)
                        .font(.caption2)
                        .foregroundColor(Color(NSColor.tertiaryLabelColor))
                        .lineLimit(1)
                }
                
                // Creation date
                Text(noteFile.creationDate.timeIntervalSince1970 == 0 ? "No date" : noteFile.creationDate.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .redacted(reason: noteFile.creationDate.timeIntervalSince1970 == 0 ? .placeholder : [])
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
}

#Preview {
    NoteFileRow(
        noteFile: NoteFile(
            id: "preview",
            name: "Sample_Note.md",
            relativePath: "Sample_Note.md",
            url: URL(fileURLWithPath: "/tmp/Sample_Note.md"),
            creationDate: Date(),
            modificationDate: Date()
        ),
        isSelected: true,
        onSelect: {}
    )
}