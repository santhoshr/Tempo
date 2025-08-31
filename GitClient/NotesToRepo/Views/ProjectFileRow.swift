//
//  ProjectFileRow.swift
//  GitClient
//
//  Created by Rovo Dev on 2025/08/31.
//

import SwiftUI

struct ProjectFileRow: View {
    let fileURL: URL
    let repoRoot: String
    let onReveal: () -> Void
    
    private var fileName: String { fileURL.lastPathComponent }
    private var relativePath: String {
        var path = fileURL.path
        if path.hasPrefix(repoRoot) {
            path.removeFirst(repoRoot.count)
        }
        return path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
    private var parentBadge: String? {
        let rel = relativePath
        guard rel.contains("/") else { return nil }
        let dir = (rel as NSString).deletingLastPathComponent
        return (dir as NSString).lastPathComponent
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(fileName)
                    .font(.system(.subheadline))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                Text(relativePath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if let badge = parentBadge {
                Text(badge)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(NSColor.controlAccentColor).opacity(0.15))
                    .foregroundColor(Color(NSColor.controlAccentColor))
                    .clipShape(Capsule())
                    .lineLimit(1)
            }
            
            Button(action: onReveal) {
                Image(systemName: "folder")
            }
            .buttonStyle(.bordered)
            .help("Reveal in Finder")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture { onReveal() }
    }
}

#Preview {
    ProjectFileRow(
        fileURL: URL(fileURLWithPath: "/tmp/repo/docs/README.md"),
        repoRoot: "/tmp/repo",
        onReveal: {}
    )
    .padding()
}
