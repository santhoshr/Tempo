//
//  GitClientApp.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/17.
//

import SwiftUI

@main
struct GitClientApp: App {
    @AppStorage (UserDefaults.Key.initialConfigurationIsComplete.rawValue) var initialConfigurationIsComplete = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    guard !initialConfigurationIsComplete else { return }
                    try? MessageTemplateStore.save([
                        .init(message: "Tweaks"),
                        .init(message: "Fix lint warnings")
                    ])
                    initialConfigurationIsComplete = true
                }
        }
        Window("Commit Message Template", id: "messageTemplate") {
            Text("Hello")
        }
    }
}
