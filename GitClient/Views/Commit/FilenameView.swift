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
        HStack {
            Language.thumbnail(filePath: toFilePath)
                .resizable()
                .scaledToFit()
                .frame(width: 20)
            Text(filePathDisplay)
                .fontWeight(.bold)
                .font(Font.system(.body, design: .default))
        }
    }
}

#Preview {
    FilenameView(
        toFilePath: "Sources/MyFeature/File.swift",
        filePathDisplay: "Sources/MyFeature/File.swift"
    )
    FilenameView(
        toFilePath: "Sources/MyFeature/File.pbj",
        filePathDisplay: "Sources/MyFeature/File.pbj"
    )
}
