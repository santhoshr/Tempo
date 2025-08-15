//
//  KeychainStorage.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/28.
//

import Foundation
import KeychainAccess

final class KeychainStorage: ObservableObject {
    @Published var openAIAPISecretKey: String {
        didSet {
            do {
                try apiKeyDB.label("OpenAI API Secret Key for Tempo.app").comment("The secret key used for AI-powered staging and commit message generation.").set(openAIAPISecretKey, key: apiKeyKey)
            } catch {
                self.error = error
            }
        }
    }
    
    @Published var openAIAPIURL: String {
        didSet {
            do {
                try apiURLDB.label("OpenAI API URL for Tempo.app").comment("The API endpoint URL used for AI-powered staging and commit message generation.").set(openAIAPIURL, key: apiURLKey)
            } catch {
                self.error = error
            }
        }
    }
    
    @Published var openAIAPIPrompt: String {
        didSet {
            do {
                try apiPromptDB.label("OpenAI API Prompt for Tempo.app").comment("The system prompt used for AI-powered staging and commit message generation.").set(openAIAPIPrompt, key: apiPromptKey)
            } catch {
                self.error = error
            }
        }
    }
    
    @Published var openAIAPIModel: String {
        didSet {
            do {
                try apiModelDB.label("OpenAI API Model for Tempo.app").comment("The AI model used for staging and commit message generation.").set(openAIAPIModel, key: apiModelKey)
            } catch {
                self.error = error
            }
        }
    }
    
    @Published var openAIAPIStagingPrompt: String {
        didSet {
            do {
                try apiStagingPromptDB.label("OpenAI API Staging Prompt for Tempo.app").comment("The system prompt used for AI-powered staging changes.").set(openAIAPIStagingPrompt, key: apiStagingPromptKey)
            } catch {
                self.error = error
            }
        }
    }
    
    @Published var error: Error?
    private let apiKeyDB = Keychain(service: Bundle.main.bundleIdentifier! + ".openai-api-secret-key")
    private let apiURLDB = Keychain(service: Bundle.main.bundleIdentifier! + ".openai-api-url")
    private let apiPromptDB = Keychain(service: Bundle.main.bundleIdentifier! + ".openai-api-prompt")
    private let apiModelDB = Keychain(service: Bundle.main.bundleIdentifier! + ".openai-api-model")
    private let apiStagingPromptDB = Keychain(service: Bundle.main.bundleIdentifier! + ".openai-api-staging-prompt")
    private let apiKeyKey = "OpenAIAPISecretKey"
    private let apiURLKey = "OpenAIAPIURL"
    private let apiPromptKey = "OpenAIAPIPrompt"
    private let apiModelKey = "OpenAIAPIModel"
    private let apiStagingPromptKey = "OpenAIAPIStagingPrompt"

    init() {
        do {
            let secretKey = try apiKeyDB.get(apiKeyKey)
            self.openAIAPISecretKey = secretKey ?? ""
            
            let apiURL = try apiURLDB.get(apiURLKey)
            self.openAIAPIURL = apiURL ?? "https://api.openai.com/v1/chat/completions"
            
            let apiPrompt = try apiPromptDB.get(apiPromptKey)
            self.openAIAPIPrompt = apiPrompt ?? "You are a good software engineer. Tell me commit title and message of these changes for git. Add a title starting with nature like feat, bugfix, fix, add, update, etc."
            
            let apiModel = try apiModelDB.get(apiModelKey)
            self.openAIAPIModel = apiModel ?? "gpt-4o-mini"
            
            let apiStagingPrompt = try apiStagingPromptDB.get(apiStagingPromptKey)
            self.openAIAPIStagingPrompt = apiStagingPrompt ?? """
You are a good software engineer.
The first message is the diff that has already been staged. The second message is the unstaged diff. The third message consists of untracked files, separated by new lines. Please advise on what changes should be committed next. It's fine if you think it is appropriate to commit everything together.

For the unstaged diff, please indicate which hunks should be committed by answering with booleans so that the response can be used as input for git add -p. For the untracked files, please also answer with booleans for each file.

Additionally, please provide a good commit message for committing the changes that should be staged.
"""
        } catch {
            self.openAIAPISecretKey = ""
            self.openAIAPIURL = "https://api.openai.com/v1/chat/completions"
            self.openAIAPIPrompt = "You are a good software engineer. Tell me commit title and message of these changes for git. Add a title starting with nature like feat, bugfix, fix, add, update, etc."
            self.openAIAPIModel = "gpt-4o-mini"
            self.openAIAPIStagingPrompt = """
You are a good software engineer.
The first message is the diff that has already been staged. The second message is the unstaged diff. The third message consists of untracked files, separated by new lines. Please advise on what changes should be committed next. It's fine if you think it is appropriate to commit everything together.

For the unstaged diff, please indicate which hunks should be committed by answering with booleans so that the response can be used as input for git add -p. For the untracked files, please also answer with booleans for each file.

Additionally, please provide a good commit message for committing the changes that should be staged.
"""
            self.error = error
        }
    }
}
