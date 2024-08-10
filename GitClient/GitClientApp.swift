//
//  GitClientApp.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/17.
//

import SwiftUI

@main
struct GitClientApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        Window("Commit Message Template", id: "messageTemplate") {
            CommitMessageTemplateView()
        }
    }
}
