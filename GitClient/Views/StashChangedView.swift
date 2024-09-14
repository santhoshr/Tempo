//
//  StashChangedView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/14.
//

import SwiftUI

struct StashChangedView: View {
    @State var stashList: [Stash] = [
        .init(id: 0, message: "Hello"),
        .init(id: 1, message: "World"),
    ]

    var body: some View {
        NavigationSplitView {
            List(stashList) { stash in
                Text(stash.message)
            }
        } detail: {

        }
        .navigationTitle("Stash Changed")
        .frame(minWidth: 300, minHeight: 200)
    }
}

#Preview {
    StashChangedView(stashList: [
        .init(id: 0, message: "Hello"),
        .init(id: 1, message: "World"),
    ])
}
