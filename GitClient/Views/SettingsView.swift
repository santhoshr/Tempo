//
//  SettingsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/27.
//

import SwiftUI

struct SettingsView: View {
    @Binding var openAIAPISecretKey: String

    var body: some View {
        VStack(alignment: .leading) {
            Text("OpenAI API")
                .font(.title2)
                .fontWeight(.bold)
            Divider()
            HStack {
                Image(systemName: "sparkle")
                Text("You can use the OpenAI API to stage changes and generate commit messages.")
            }
            .padding(.vertical)
            Form {
                Section {
                    HStack {
                        SecureField(text: $openAIAPISecretKey) {
                            Text("SECRET KEY")
                        }
                    }
                } footer: {
                    Text("""
Please enter the Secret Key, which can be created from the link https://platform.openai.com/api-keys.
Grant “Write” permission to the Secret Key for the “/v1/chat/completions” endpoint.

Each time the Generate button is clicked, a request for changes will be sent to the API(using GPT-4o mini). You can check the costs associated with using the API here. https://platform.openai.com/usage

This Git client app and OpenAI API also do not use the inputs and outputs for model training. https://openai.com/enterprise-privacy
"""
                    )
                }
            }
        }
        .padding()
        .frame(minWidth: 300, maxWidth: 700, minHeight: 200, maxHeight: 600)
    }
}

#Preview {
    @Previewable @State var openAIAPISecretKey = ""
    SettingsView(openAIAPISecretKey: $openAIAPISecretKey)
}
