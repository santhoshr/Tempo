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
    @State private var selectedEntry: ReflogEntry?
    @State private var filterText: String = ""
    @State private var isLoading: Bool = false
    @State private var reflogStore: ReflogStore?
    
    private var filteredEntries: [ReflogEntry] {
        guard let store = reflogStore else { return [] }
        guard !filterText.isEmpty else { return store.entries }
        return store.entries.filter { entry in
            entry.message.lowercased().contains(filterText.lowercased()) ||
            entry.refName.lowercased().contains(filterText.lowercased()) ||
            entry.hash.lowercased().contains(filterText.lowercased())
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease")
                TextField(text: $filterText) {
                    Text("Filter")
                }
                
                Button(action: refreshEntries) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.secondary)
                }
                .disabled(isLoading)
                .help("Refresh latest entries")
                
                Button(action: loadAllEntries) {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.secondary)
                }
                .disabled(isLoading)
                .help("Load all reflog entries")
            }
            .padding(.top, 4)
            .padding([.horizontal, .bottom])
            Divider()
                .background(.ultraThinMaterial)
            List {
                ForEach(filteredEntries) { entry in
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
                
                if filterText.isEmpty && reflogStore?.hasMoreEntries == true {
                    HStack {
                        Spacer()
                        Button(action: loadMoreEntries) {
                            HStack(spacing: 4) {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.down.circle")
                                }
                                Text(isLoading ? "Loading..." : "Load More")
                            }
                        }
                        .disabled(isLoading)
                        .padding(.vertical, 8)
                        Spacer()
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .task {
            // Initialize store for this folder
            reflogStore = ReflogStoreManager.shared.store(for: folder.url)
            await loadInitialEntries()
        }
        .errorSheet(.constant(reflogStore?.error))
    }
    
    private func loadInitialEntries() async {
        guard let store = reflogStore else { return }
        
        // If store already has entries, no need to reload
        if !store.entries.isEmpty {
            return
        }
        
        await store.loadInitial()
    }
    
    private func loadMoreEntries() {
        guard let store = reflogStore else { return }
        
        Task {
            isLoading = true
            defer { isLoading = false }
            
            await store.loadMore()
        }
    }
    
    private func refreshEntries() {
        guard let store = reflogStore else { return }
        
        Task {
            isLoading = true
            defer { isLoading = false }
            
            await store.refresh()
        }
    }
    
    private func loadAllEntries() {
        guard let store = reflogStore else { return }
        
        Task {
            isLoading = true
            defer { isLoading = false }
            
            await store.loadAll()
        }
    }
}