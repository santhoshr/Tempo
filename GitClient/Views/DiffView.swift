//
//  DiffView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/01.
//

import SwiftUI

struct DiffView: View {
    var diff: String

    var body: some View {
        ScrollView {
            Text(diff)
                .font(Font.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}

struct DiffView_Previews: PreviewProvider {
    static var previews: some View {
        DiffView(diff: "hello")
    }
}
