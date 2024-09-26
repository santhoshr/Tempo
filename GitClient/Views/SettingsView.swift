//
//  SettingsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/27.
//

import SwiftUI

struct SettingsView: View {
    
    var body: some View {
        Form {
            Section(header: Text("OpenAI")) {
                HStack {
                    Text("Key")
                }
            }
        }
        .frame(maxWidth: 600, maxHeight: 500)
    }
}

#Preview {
    SettingsView()
}
