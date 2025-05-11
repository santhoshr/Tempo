//
//  CommitLogView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/23.
//

import SwiftUI

struct CommitLogView: View {
    @Environment(\.folder) private var folder
    @Binding var logStore: LogStore
    @Binding var selectionLogID: String?
    @Binding var subSelectionLogID: String?
    @Binding var showing: FolderViewShowing
    @Binding var isRefresh: Bool
    @Binding var error: Error?
    @State private var selectionLogIDs = Set<String>()

    var body: some View {
        List(logStore.logs(), selection: $selectionLogIDs) { log in
            logsRow(log)
                .task {
                    await logStore.logViewTask(log)
                }
        }
        .onChange(of: selectionLogIDs) { oldValue, newValue in
            if newValue.count <= 1 {
                selectionLogID = newValue.first
                subSelectionLogID = nil
            }
            if newValue.count > 1 {
                if let added = newValue.first(where: { !oldValue.contains($0) }) {
                    subSelectionLogID = added
                    selectionLogIDs = [selectionLogID!, subSelectionLogID!]
                }
            }
        }
        .onChange(of: selectionLogID ?? "") { oldValue, newValue in
            syncSelection(oldValue: oldValue, newValue: newValue)
        }
        .onChange(of: subSelectionLogID ?? "") { oldValue, newValue in
            syncSelection(oldValue: oldValue, newValue: newValue)
        }
    }

    fileprivate func syncSelection(oldValue: String, newValue: String) {
        selectionLogIDs.remove(oldValue)
        if !newValue.isEmpty {
            selectionLogIDs.insert(newValue)
        }
    }

    fileprivate func logsRow(_ log: Log) -> some View {
        return VStack {
            switch log {
            case .notCommitted:
                Text("Uncommitted Changes")
                    .foregroundStyle(Color.secondary)
            case .committed(let commit):
                CommitRowView(commit: commit)
                    .commitContextMenu(
                        folder: folder!,
                        commit: commit,
                        logStore: logStore,
                        isRefresh: $isRefresh,
                        showing: $showing,
                        bindingError: $error
                    )
            }
        }
    }

}
