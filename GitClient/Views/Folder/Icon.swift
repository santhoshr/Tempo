//
//  IconView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/05/25.
//

import SwiftUI

struct Icon: View {
    enum Size {
        case small, medium
        var image: CGFloat {
            switch self {
            case .small:
                return 14
            case .medium:
                return 26
            }
        }
        var corner: CGSize {
            switch self {
            case .small:
                return .init(width: 3, height: 3)
            case .medium:
                return .init(width: 6, height: 6)
            }
        }
        var font: CGFloat {
            switch self {
            case .small:
                return 8
            case .medium:
                return 12
            }
        }
    }
    var size: Size
    var authorEmail: String
    var authorInitial: String

    var body: some View {
        AuthorInitialIcon(initial: authorInitial)
            .font(.system(size: size.font, weight: .medium))
            .frame(width: size.image, height: size.image)
            .clipShape(RoundedRectangle(cornerSize: size.corner, style: .circular))
    }
}

#Preview {
    Icon(size: .small, authorEmail: "", authorInitial: "makoto aoyama".initial)
}
