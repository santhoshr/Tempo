//
//  BarBackButton.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/05/20.
//

import SwiftUI

struct BarBackButton: View {
    @Binding var path: [String]

    var body: some View {
        HStack {
            Button {
                path = path.dropLast()
            } label: {
                Image(systemName: "chevron.backward")
            }
            .background(Color(NSColor.textBackgroundColor).opacity(1))
            .padding(.horizontal)
            .padding(.vertical, 8)
            Spacer()
        }
        .background(Color(NSColor.textBackgroundColor).opacity(0.98))    }
}
