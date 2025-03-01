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
                        .focusable(false)
                    }
                } footer: {
                    Text("""
Please enter the Secret Key, which can be created from the link https://platform.openai.com/api-keys.
Grant “Write” permission to the Secret Key for the “/v1/chat/completions” endpoint.
"""
                    )
                }
            }
            .padding(.vertical)
            HStack {
                Image(systemName: "sparkle")
                    .frame(width: 20)
                Text("You can use the OpenAI API to stage changes and generate commit messages.")
            }
            .padding(.vertical)
            HStack {
                Image(systemName: "dollarsign")
                    .frame(width: 20)
                Text("""
Each time the Generate button is clicked, a request for changes will be sent to the API(using GPT-4o mini). Using GPT-4o-mini via the API costs 15 cents per 1M input tokens and 60 cents per 1M output tokens (roughly the equivalent of 2500 pages in a standard book). You can check the costs associated with using the API here. https://platform.openai.com/usage
""")
            }
            .padding(.bottom)
            HStack {
                Image(systemName: "shield")
                    .frame(width: 20)
                Text("""
This Git client app and OpenAI API also do not use the inputs and outputs for model training. https://openai.com/enterprise-privacy
""")
            }
            .padding(.bottom)
        }
        .padding()
        .padding(.horizontal)
        .frame(minWidth: 300, maxWidth: 700, minHeight: 200, maxHeight: 600)
    }
}

#Preview {
    @Previewable @State var openAIAPISecretKey = ""
    SettingsView(openAIAPISecretKey: $openAIAPISecretKey)
}
