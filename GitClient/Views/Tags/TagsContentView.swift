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
            List(tags, id: \.self) { tag in
                Text(tag)
            }
        }
    }
}

#Preview {
    @Previewable @State var showingTags = false
    TagsContentView(folder: .init(url: URL(string: "file:///maoyama/Projects/")!), showingTags: $showingTags, onTapDeleteButton: { _ in })
}
