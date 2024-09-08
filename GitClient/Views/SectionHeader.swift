//
//  SectionHeader.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/08.
//

import SwiftUI

struct SectionHeader: View {
    var title: String
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            HStack {
                Text(title)
                    .fontWeight(.bold)
                Spacer()
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
            .padding(.vertical, 9)
            .padding(.horizontal)
            Divider()
        }
        .textSelection(.disabled)
        .background(Color(nsColor: .quaternarySystemFill))
        .background(Color(nsColor: .textBackgroundColor))
    }
}

#Preview {
    @State var value: Bool = true
    return SectionHeader(title: "Staged", isExpanded: $value)
}
