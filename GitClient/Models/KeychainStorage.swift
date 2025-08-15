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
    
    @Published var error: Error?
    private let apiKeyDB = Keychain(service: Bundle.main.bundleIdentifier! + ".openai-api-secret-key")
    private let apiURLDB = Keychain(service: Bundle.main.bundleIdentifier! + ".openai-api-url")
    private let apiPromptDB = Keychain(service: Bundle.main.bundleIdentifier! + ".openai-api-prompt")
    private let apiKeyKey = "OpenAIAPISecretKey"
    private let apiURLKey = "OpenAIAPIURL"
    private let apiPromptKey = "OpenAIAPIPrompt"

    init() {
        do {
            let secretKey = try apiKeyDB.get(apiKeyKey)
            self.openAIAPISecretKey = secretKey ?? ""
            
            let apiURL = try apiURLDB.get(apiURLKey)
            self.openAIAPIURL = apiURL ?? "https://api.openai.com/v1/chat/completions"
            
            let apiPrompt = try apiPromptDB.get(apiPromptKey)
            self.openAIAPIPrompt = apiPrompt ?? "You are a good software engineer. Tell me commit title and message of these changes for git. Add a title starting with nature like feat, bugfix, fix, add, update, etc."
        } catch {
            self.openAIAPISecretKey = ""
            self.openAIAPIURL = "https://api.openai.com/v1/chat/completions"
            self.openAIAPIPrompt = "You are a good software engineer. Tell me commit title and message of these changes for git. Add a title starting with nature like feat, bugfix, fix, add, update, etc."
            self.error = error
        }
    }
}
