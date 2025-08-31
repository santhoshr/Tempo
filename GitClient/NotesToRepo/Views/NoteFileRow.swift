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
    
    // Extract the final directory name from the relative path
    private var finalDirectoryName: String? {
        // Only show badge if file is in a subdirectory
        guard noteFile.relativePath != noteFile.name else { return nil }
        
        // Get the directory path by removing the filename
        let directoryPath = (noteFile.relativePath as NSString).deletingLastPathComponent
        
        // Return the final directory component if it exists
        return directoryPath.isEmpty ? nil : (directoryPath as NSString).lastPathComponent
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // File icon
            Image(systemName: "doc.text")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                // File name and directory badge
                HStack(spacing: 6) {
                    Text(noteFile.name)
                        .font(.system(.subheadline, weight: isSelected ? .medium : .regular))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    // Show directory badge if file is in a subdirectory
                    if let directoryName = finalDirectoryName {
                        Text(directoryName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(NSColor.controlAccentColor).opacity(0.15))
                            .foregroundColor(Color(NSColor.controlAccentColor))
                            .clipShape(Capsule())
                            .lineLimit(1)
                    }
                    
                    Spacer()
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
    VStack(spacing: 8) {
        // File in root directory (no badge)
        NoteFileRow(
            noteFile: NoteFile(
                id: "preview1",
                name: "Sample_Note.md",
                relativePath: "Sample_Note.md",
                url: URL(fileURLWithPath: "/tmp/Sample_Note.md"),
                creationDate: Date(),
                modificationDate: Date()
            ),
            isSelected: false,
            onSelect: {}
        )
        
        // File in subdirectory (shows badge)
        NoteFileRow(
            noteFile: NoteFile(
                id: "preview2",
                name: "Feature_Notes.md",
                relativePath: "repo/to/Feature_Notes.md",
                url: URL(fileURLWithPath: "/tmp/repo/to/Feature_Notes.md"),
                creationDate: Date(),
                modificationDate: Date()
            ),
            isSelected: true,
            onSelect: {}
        )
    }
    .padding()
}