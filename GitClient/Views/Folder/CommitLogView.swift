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
                syncSelection()
                return
            }
            if selectionLogID == nil {
                subSelectionLogID = nil
                syncSelection()
                return
            }
            if newValue.count < 4 {
                if let added = newValue.first(where: { !oldValue.contains($0) }) {
                    subSelectionLogID = added
                    syncSelection()
                }
            } else {
                syncSelection()
            }
        }
        .onChange(of: selectionLogID ?? "") {
            syncSelection()
        }
        .onChange(of: subSelectionLogID ?? "") {
            syncSelection()
        }
    }

    fileprivate func syncSelection() {
        var newValues =  Set<String>()
        if let selectionLogID {
            newValues.insert(selectionLogID)
        }
        if let subSelectionLogID {
            newValues.insert(subSelectionLogID)
        }
        DispatchQueue.main.async {
            selectionLogIDs = newValues
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
