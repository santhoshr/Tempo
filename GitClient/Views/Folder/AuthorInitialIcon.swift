//
//  AuthorInitialIcon.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/05/25.
//

import SwiftUI

struct AuthorInitialIcon: View {
    var initial: String
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0, style: .circular)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(white: 0.65), Color(white: 0.50)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Text(initial)
                .fontDesign(.rounded)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    AuthorInitialIcon(initial: "A")
        .frame(width: 40, height: 40)
}

#Preview {
    AuthorInitialIcon(initial: "AA")
        .frame(width: 40, height: 40)
}

#Preview {
    AuthorInitialIcon(initial: "AAAAAAAAA")
        .frame(width: 40, height: 40)
}
