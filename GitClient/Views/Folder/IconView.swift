//
//  IconView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/05/25.
//

import SwiftUI

struct IconView: View {
    enum Size {
        case s, m
        var image: CGFloat {
            switch self {
            case .s:
                return 14
            case .m:
                return 26
            }
        }
        var corner: CGSize {
            switch self {
            case .s:
                return .init(width: 3, height: 3)
            case .m:
                return .init(width: 6, height: 6)
            }
        }
        var font: CGFloat {
            switch self {
            case .s:
                return 8
            case .m:
                return 12
            }
        }
    }
    @Environment(\.openURL) private var openURL
    var size: Size
    var authorEmail: String
    var authorInitial: String

    var body: some View {
        AsyncImage(url: URL.gravater(email: authorEmail, size: size.image*3)) { phase in
            if let image = phase.image {
                image.resizable()
                    .onTapGesture {
                        guard let url = URL.gravater(email: authorEmail, size: 400) else { return }
                        openURL(url)
                    }

            } else if phase.error != nil {
                AuthorInitialIcon(initial: authorInitial)
                    .font(.system(size: size.font, weight: .medium))
            } else {
                RoundedRectangle(cornerSize: size.corner, style: .circular)
                    .foregroundStyle(.quinary)
            }
        }
            .frame(width: size.image, height: size.image)
            .clipShape(RoundedRectangle(cornerSize: size.corner, style: .circular))
    }
}

#Preview {
    IconView(size: .s, authorEmail: "", authorInitial: "AA")
}
