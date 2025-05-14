//
//  RevisionRangeDiffView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/05/15.
//

import SwiftUI

struct RevisionRangeDiffView: View {
    var selectionLogID: String
    var subSelectionLogID: String

    var body: some View {
        Text(selectionLogID + subSelectionLogID)
            .onChange(of: selectionLogID + subSelectionLogID, initial: true) { oldValue, newValue in
                Task {
                    print("task")
                }
            }
    }
}
