//
//  GitClientApp.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/17.
//

import SwiftUI
import Collections

@main
struct GitClientApp: App {
    @AppStorage (AppStorageKey.commitMessageTemplate.rawValue) var commitMessageTemplate: Data = AppStorageDefaults.commitMessageTemplate
    var decodedCommitMessageTemplates: OrderedSet<String> {
        do {
            return try JSONDecoder().decode(OrderedSet<String>.self, from: commitMessageTemplate)
        } catch {
            return []
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        Window("Commit Message Template", id: "messageTemplate") {
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
}
