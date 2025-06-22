//
//  SectionHeader.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/08.
//

import SwiftUI

struct SectionHeader: View {
    var title: String

    var body: some View {
        Text(title)
            .font(.title)
            .fontWeight(.bold)
            .textSelection(.disabled)
    }
}

#Preview {
    return SectionHeader(
        title: "Staged"
    )
}
