//
//  TagsContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/21.
//

import SwiftUI

struct TagsContentView: View {
    var folder: Folder
    @Binding var showingTags: Bool
    var tags: [String]?
    var onTapDeleteButton: (String) -> Void

    var body: some View {
        if let tags {
            if tags.isEmpty {
                VStack {
                    Text("No Content")
                        .foregroundStyle(.secondary)
                }
            } else {
                List(tags, id: \.self) { tag in
                    Text(tag)
                }
                .scrollContentBackground(.hidden)
            }
        }
    }
}

#Preview {
    @Previewable @State var showingTags = false
    TagsContentView(folder: .init(url: URL(string: "file:///maoyama/Projects/")!), showingTags: $showingTags, tags: ["v1.0.0", "v1.1.0", "v2.0.0"], onTapDeleteButton: { _ in })
        .frame(width: 300, height: 660)
}

#Preview("No Content") {
    @Previewable @State var showingTags = false
    TagsContentView(folder: .init(url: URL(string: "file:///maoyama/Projects/")!), showingTags: $showingTags, tags: [], onTapDeleteButton: { _ in })
        .frame(width: 300, height: 660)
}
