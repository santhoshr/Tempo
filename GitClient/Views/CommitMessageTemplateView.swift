//
//  CommitMessageTemplateView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/11.
//

import SwiftUI

struct CommitMessageTemplateView: View {
    @AppStorage (AppStorageKey.commitMessageTemplate.rawValue) var commitMessageTemplate: Data = AppStorageDefaults.commitMessageTemplate
    var decodedCommitMessageTemplates: Array<String> {
        do {
            return try JSONDecoder().decode(Array<String>.self, from: commitMessageTemplate)
        } catch {
            return []
        }
    }

    var body: some View {
        List {
            ForEach(decodedCommitMessageTemplates, id: \.self) {
                Text($0)
            }
            .onMove(perform: { indices, newOffset in
                var t = Array(decodedCommitMessageTemplates)
                t.move(fromOffsets: indices, toOffset: newOffset)
                do {
                    commitMessageTemplate = try JSONEncoder().encode(t)
                } catch {
                    print(error)
                }
            })
        }
    }
}

#Preview {
    CommitMessageTemplateView()
}
