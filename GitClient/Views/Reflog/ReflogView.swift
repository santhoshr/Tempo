//
//  ReflogView.swift
//  GitClient
//
//  Created by Claude on 2025/08/28.
//

import SwiftUI
import AppKit

struct ReflogView: View {
    var folder: Folder
    var onPreview: ((ReflogEntry) -> Void)
    var onCheckout: ((ReflogEntry) -> Void)
    @State private var reflogEntries: [ReflogEntry] = []
    @State private var error: Error?
    @State private var selectedEntry: ReflogEntry?
    @State private var filterText: String = ""
    
    private var filteredEntries: [ReflogEntry] {
        guard !filterText.isEmpty else { return reflogEntries }
        return reflogEntries.filter { entry in
            entry.message.lowercased().contains(filterText.lowercased()) ||
            entry.refName.lowercased().contains(filterText.lowercased()) ||
            entry.hash.lowercased().contains(filterText.lowercased())
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease")
                TextField(text: $filterText) {
                    Text("Filter")
                }
            }
            .padding(.top, 4)
            .padding([.horizontal, .bottom])
            Divider()
                .background(.ultraThinMaterial)
            List(filteredEntries) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.shortHash)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                        Text(entry.refName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        ForEach(entry.branchNames, id: \.self) { branchName in
                            Text(branchName)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                    Text(entry.message)
                        .lineLimit(2)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onCheckout(entry)
                }
                .contextMenu {
                    Button("Show Commit Preview") {
                        onPreview(entry)
                    }
                    Divider()
                    Button("Copy Hash") {
                        let pasteboard = NSPasteboard.general
                        pasteboard.declareTypes([.string], owner: nil)
                        pasteboard.setString(entry.hash, forType: .string)
                    }
                    Button("Copy Short Hash") {
                        let pasteboard = NSPasteboard.general
                        pasteboard.declareTypes([.string], owner: nil)
                        pasteboard.setString(entry.shortHash, forType: .string)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .task {
            await loadReflog()
        }
        .errorSheet($error)
    }
    
    private func loadReflog() async {
        do {
            var entries = try await Process.output(GitReflog(directory: folder.url))
            var seenBranches: Set<String> = []
            
            // Load branch information efficiently - only for first occurrence of each branch
            for i in entries.indices {
                let branches = try await Process.output(GitBranchPointsAt(directory: folder.url, object: entries[i].hash))
                let branchNames = branches.map { $0.name }
                
                // Only show badge for first occurrence of each branch
                entries[i].branchNames = branchNames.filter { branchName in
                    if seenBranches.contains(branchName) {
                        return false
                    } else {
                        seenBranches.insert(branchName)
                        return true
                    }
                }
            }
            
            reflogEntries = entries
        } catch {
            self.error = error
        }
    }
}