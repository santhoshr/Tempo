//
//  FilenameView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/06.
//

import SwiftUI

struct FilenameView: View {
    var toFilePath: String
    var filePathDisplay: String

    var body: some View {
        Text(filePathDisplay)
            .fontWeight(.bold)
            .font(Font.system(.body, design: .default))
    }
}

#Preview {
    FilenameView(
        toFilePath: "Sources/MyFeature/File.swift",
        filePathDisplay: "Sources/MyFeature/File.swift"
    )
}
