//
//  FileNameView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/06.
//

import SwiftUI

struct FileNameView: View {
    var toFilePath: String
    var filePathDisplay: String

    var body: some View {
        HStack {
            if let asset = Language.assetName(filePath: toFilePath) {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18)
            } else {
                Image(systemName: "doc")
                    .frame(width: 18, height: 18)
                    .fontWeight(.heavy)
            }
            Text(filePathDisplay)
                .fontWeight(.bold)
                .font(Font.system(.body, design: .default))
        }
    }
}

#Preview {
    HStack {
        FileNameView(
            toFilePath: "Sources/MyFeature/File.swift",
            filePathDisplay: "Sources/MyFeature/File.swift"
        )
        Spacer()
    }
    HStack {
        FileNameView(
            toFilePath: "Sources/MyFeature/File.py",
            filePathDisplay: "Sources/MyFeature/File.py"
        )
        Spacer()
    }
    HStack {
        FileNameView(
            toFilePath: "Sources/MyFeature/File.rb",
            filePathDisplay: "Sources/MyFeature/File.rb"
        )
        Spacer()
    }
    HStack {
        FileNameView(
            toFilePath: "Sources/MyFeature/File.rs",
            filePathDisplay: "Sources/MyFeature/File.rs"
        )
        Spacer()
    }
    HStack {
        FileNameView(
            toFilePath: "Sources/MyFeature/File.js",
            filePathDisplay: "Sources/MyFeature/File.js"
        )
        Spacer()
    }
    HStack {
        FileNameView(
            toFilePath: "Sources/MyFeature/File.ml",
            filePathDisplay: "Sources/MyFeature/File.ml"
        )
        Spacer()
    }
    HStack {
        FileNameView(
            toFilePath: "Sources/MyFeature/File.pbj",
            filePathDisplay: "Sources/MyFeature/File.pbj"
        )
        Spacer()
    }
}
