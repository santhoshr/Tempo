//
//  DiffTabView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/05/18.
//

import SwiftUI

struct DiffTabView: View {
    @Binding var tab: Int

    var body: some View {
        HStack {
            Spacer()
            Picker("", selection: $tab) {
                Text("Commits").tag(0)
                Text("Files Changed").tag(1)
            }
            .frame(maxWidth:400)
            .pickerStyle(.segmented)
            Spacer()
        }
    }
}
