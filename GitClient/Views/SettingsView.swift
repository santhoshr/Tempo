//
//  SettingsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/27.
//

import SwiftUI

struct SettingsView: View {
    @Binding var openAIAPISecretKey: String
    @Binding var openAIAPIURL: String
    @Binding var openAIAPIPrompt: String
    @Binding var openAIAPIModel: String
    @Binding var openAIAPIStagingPrompt: String

    var body: some View {
        TabView {
            OpenAISettingsView(
                openAIAPISecretKey: $openAIAPISecretKey,
                openAIAPIURL: $openAIAPIURL,
                openAIAPIPrompt: $openAIAPIPrompt,
                openAIAPIModel: $openAIAPIModel,
                openAIAPIStagingPrompt: $openAIAPIStagingPrompt
            )
            .tabItem {
                Label("OpenAI", systemImage: "sparkles")
            }
            
            GitRepoSettingsView()
                .tabItem {
                    Label("Repositories", systemImage: "folder.badge.gearshape")
                }
            
            TerminalSettingsView()
                .tabItem {
                    Label("Terminal", systemImage: "terminal")
                }
            
            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "gearshape.2")
                }
        }
        .frame(minWidth: 650, maxWidth: 650, minHeight: 500)
    }
}

struct OpenAISettingsView: View {
    @Binding var openAIAPISecretKey: String
    @Binding var openAIAPIURL: String
    @Binding var openAIAPIPrompt: String
    @Binding var openAIAPIModel: String
    @Binding var openAIAPIStagingPrompt: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("OpenAI API Settings")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Configure your OpenAI API integration for AI-powered Git operations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // API Configuration Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("API Configuration")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Secret Key
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Secret Key")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            SecureField("Enter your OpenAI API key", text: $openAIAPISecretKey)
                                .textFieldStyle(.roundedBorder)
                                .focusable(false)
                            Text("Create your API key at https://platform.openai.com/api-keys with 'Write' permission for /v1/chat/completions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // API URL
                        VStack(alignment: .leading, spacing: 6) {
                            Text("API URL")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("https://api.openai.com/v1/chat/completions", text: $openAIAPIURL)
                                .textFieldStyle(.roundedBorder)
                                .focusable(false)
                        }
                        
                        // Model
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Model")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("gpt-4o-mini", text: $openAIAPIModel)
                                .textFieldStyle(.roundedBorder)
                                .focusable(false)
                            Text("Examples: gpt-4o-mini, gpt-4, gpt-3.5-turbo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                
                // Prompts Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("AI Prompts")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Commit Message Prompt
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Commit Message Prompt")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextEditor(text: $openAIAPIPrompt)
                                .frame(minHeight: 80, maxHeight: 120)
                                .scrollContentBackground(.hidden)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                )
                            Text("Customize how the AI generates commit messages")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Staging Prompt
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Staging Prompt")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextEditor(text: $openAIAPIStagingPrompt)
                                .frame(minHeight: 120, maxHeight: 200)
                                .scrollContentBackground(.hidden)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                )
                            Text("Controls how the AI decides which changes to stage")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                
                // Information Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Important Information")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    VStack(spacing: 12) {
                        InfoRow(
                            icon: "sparkles",
                            iconColor: .blue,
                            text: "Use the OpenAI API to intelligently stage changes and generate meaningful commit messages."
                        )
                        
                        InfoRow(
                            icon: "dollarsign.circle",
                            iconColor: .orange,
                            text: "API usage costs: ~$0.15 per 1M input tokens, ~$0.60 per 1M output tokens. Monitor usage at https://platform.openai.com/usage"
                        )
                        
                        InfoRow(
                            icon: "shield.checkered",
                            iconColor: .green,
                            text: "Your data is not used for model training. Learn more: https://openai.com/enterprise-privacy"
                        )
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                }
            }
            .padding(24)
        }
        .frame(minWidth: 600, maxWidth: 600, minHeight: 400)
    }
}

struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 20, height: 20)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
    
    #Preview {
        @Previewable @State var openAIAPISecretKey = ""
        @Previewable @State var openAIAPIURL = "https://api.openai.com/v1/chat/completions"
        @Previewable @State var openAIAPIPrompt = "You are a good software engineer. Tell me commit title and message of these changes for git. Add a title starting with nature like feat, bugfix, fix, add, update, etc."
        @Previewable @State var openAIAPIModel = "gpt-4o-mini"
        @Previewable @State var openAIAPIStagingPrompt = """
You are a good software engineer.
The first message is the diff that has already been staged. The second message is the unstaged diff. The third message consists of untracked files, separated by new lines. Please advise on what changes should be committed next. It's fine if you think it is appropriate to commit everything together.

For the unstaged diff, please indicate which hunks should be committed by answering with booleans so that the response can be used as input for git add -p. For the untracked files, please also answer with booleans for each file.

Additionally, please provide a good commit message for committing the changes that should be staged.
"""
        SettingsView(
            openAIAPISecretKey: $openAIAPISecretKey,
            openAIAPIURL: $openAIAPIURL,
            openAIAPIPrompt: $openAIAPIPrompt,
            openAIAPIModel: $openAIAPIModel,
            openAIAPIStagingPrompt: $openAIAPIStagingPrompt
        )
    }
}
