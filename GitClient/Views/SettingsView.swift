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

Each time the Generate button is clicked, a request for changes will be sent to the API. You can check the costs associated with using the API here. https://platform.openai.com/usage

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
