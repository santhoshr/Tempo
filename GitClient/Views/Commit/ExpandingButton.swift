//
//  ExpandingButton.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/03/16.
//

import SwiftUI

struct ExpandingButton: View {
    @Binding var isExpanded: Bool

    var body: some View {
        Button {
            withAnimation {
                isExpanded.toggle()
            }
        } label: {
            if isExpanded {
                Image(systemName: "chevron.down")
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: "chevron.right")
                    .frame(width: 20, height: 20)
            }
        }
        .buttonStyle(.accessoryBar)
    }
}
