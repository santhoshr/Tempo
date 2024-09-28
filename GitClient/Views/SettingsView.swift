//
//  SettingsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/27.
//

import SwiftUI

struct SettingsView: View {
    @State private var openAIAPISecretKey = ""

    var body: some View {
        VStack(alignment: .leading) {
            Text("OpenAI API")
                .font(.title2)
                .fontWeight(.bold)
            Divider()
            Form {
                Section {
                    HStack {
                        SecureField(text: $openAIAPISecretKey) {
                            Text("SECRET KEY")
                        }
                    }
                } footer: {
                    Text("""
    You can generate a commit message from the staged hunk using the OpenAI API.

    Please enter the Secret Key, which can be created from the link https://platform.openai.com/api-keys.
    Grant “Write” permission to the Secret Key for the “/v1/chat/completions” endpoint.
    """)
                }
            }
        }
        .padding()
        .frame(minWidth: 300, maxWidth: 700, minHeight: 200, maxHeight: 600)
    }
}

#Preview {
    SettingsView()
}
