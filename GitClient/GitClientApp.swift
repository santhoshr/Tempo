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
    @AppStorage (UserDefaults.Key.initialConfigurationIsComplete.rawValue) var initialConfigurationIsComplete = false
    @AppStorage (UserDefaults.Key.messageTemplate.rawValue) var messageTemplate: Data?

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
            if let data = messageTemplate, let templates = try? MessageTemplateStore.messageTemplates(data: data) {
                List {
                    ForEach(templates) {
                        Text($0.message)
                    }
                    .onMove(perform: { indices, newOffset in
                        print(indices)
                        print(newOffset)
                        var t = Array(templates)
                        t.move(fromOffsets: indices, toOffset: newOffset)
                        try? MessageTemplateStore.save(OrderedSet(t))
                    })
                }
            }
        }
    }
}
