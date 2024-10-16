//
//  PreviewBadge.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/10/16.
//

import SwiftUI

struct PreviewBadge: View {
    @Environment(\.openURL) var openURL

    var body: some View {
        Button {
            openURL(URL(string: "https://maoyama.gumroad.com/l/iztwtl")!)
        } label : {
            Text("This is the preview version🌟\nSubscribe to access the full version!")
                .font(Font.system(.body, design: .rounded, weight: .regular))
                .padding()
                .foregroundStyle(.white)
                .background(in: RoundedRectangle(cornerSize: .init(width: 8, height: 8)))
                .backgroundStyle(Color.accentColor.gradient)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PreviewBadge()
}
