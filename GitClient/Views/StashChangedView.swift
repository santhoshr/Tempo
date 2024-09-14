//
//  StashChangedView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/14.
//

import SwiftUI

struct StashChangedView: View {
    @State var stashList: [Stash] = [
        .init(index: 0, raw: "stash@{0}: On checkoutmain: Hello \nworld"),
        .init(index: 1, raw: "stash@{1}: WIP on add-widget: 3f04a57 Merge pull request #20 from maoyama/add-screenshot-text"),
    ]

    var body: some View {
        NavigationSplitView {
            List(stashList) { stash in
                Text(stash.message)
                    .lineLimit(3)
            }
        } detail: {

        }
        .navigationTitle("Stash Changed")
        .frame(minWidth: 300, minHeight: 200)
    }
}

#Preview {
    StashChangedView(stashList: [
        .init(index: 0, raw: "stash@{0}: On checkoutmain: Hello \nworld"),
        .init(index: 1, raw: "stash@{1}: WIP on add-widget: 3f04a57 Merge pull request #20 from maoyama/add-screenshot-text"),
    ])
}
