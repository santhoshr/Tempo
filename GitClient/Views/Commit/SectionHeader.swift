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
    var onSelectExpandedAll: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                ExpandingButton(
                    isExpanded: $isExpanded,
                    onSelectExpandedAll: onSelectExpandedAll
                )
            }
            .padding(.horizontal)
        }
        .textSelection(.disabled)
        .background(Color(NSColor.textBackgroundColor))
    }
}

#Preview {
    @Previewable @State var value: Bool = true
    return SectionHeader(
        title: "Staged",
        isExpanded: $value,
        onSelectExpandedAll: { _ in }
    )
}
