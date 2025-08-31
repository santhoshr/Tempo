//
//  DefaultsKeys.swift
//  GitClient
//
//  Created by Claude on 2025/08/30.
//

import Foundation
import Defaults

extension Defaults.Keys {
    // MARK: - Core App Settings
    static let folders = Key<[Folder]>("folders", default: [])
    static let gitRepoSettings = Key<GitRepoSettings>("gitRepoSettings", default: GitRepoSettings())
    static let terminalSettings = Key<TerminalSettings>("terminalSettings", default: TerminalSettings())
    static let allowExpertOptions = Key<Bool>("allowExpertOptions", default: false)
    static let reflogLimit = Key<Int>("reflogLimit", default: 100)
    
    // MARK: - Search and History
    static let searchTokenHistory = Key<[SearchToken]>("searchTokenHistory", default: [])
    static let commitMessageSnippets = Key<[String]>("commitMessageSnippets", default: [])
    
    // MARK: - Notes to Repo Settings
    static let notesToRepoSettings = Key<NotesToRepoSettings>("notesToRepoSettings", default: NotesToRepoSettings())
    static let notesToRepoAutoSave = Key<Bool>("notesToRepoAutoSave", default: true)
    static let notesToRepoAutoCommit = Key<Bool>("notesToRepoAutoCommit", default: false)
    static let notesToRepoFileListWidth = Key<Double>("notesToRepoFileListWidth", default: 300.0)
    static let notesToRepoLastOpenedFile = Key<String?>("notesToRepoLastOpenedFile", default: nil)
    static let notesToRepoFileListVisible = Key<Bool>("notesToRepoFileListVisible", default: true)
    static let notesToRepoStatusBarVisible = Key<Bool>("notesToRepoStatusBarVisible", default: true)
    // Project tab configuration
    static let notesToRepoProjectFileExtensions = Key<[String]>("notesToRepoProjectFileExtensions", default: ["md", "txt"]) // lowercase extensions, no dots
    static let notesToRepoProjectInitialLoad = Key<Int>("notesToRepoProjectInitialLoad", default: 25)
    
    // MARK: - AI Service Settings (replacing Keychain)
    static let openAIAPIKey = Key<String>("openAIAPIKey", default: "")
    static let openAIAPIURL = Key<String>("openAIAPIURL", default: "https://api.openai.com/v1/chat/completions")
    static let openAIAPIPrompt = Key<String>("openAIAPIPrompt", default: "You are a helpful assistant that generates concise, meaningful Git commit messages based on the provided diff. Focus on what changed and why it matters.")
    static let openAIAPIModel = Key<String>("openAIAPIModel", default: "gpt-4o-mini")
    static let openAIAPIStagingPrompt = Key<String>("openAIAPIStagingPrompt", default: "You are a helpful assistant that suggests which changes to stage for a Git commit. Analyze the diff and recommend logical groupings of changes.")
    static let aiServiceEnabled = Key<Bool>("aiServiceEnabled", default: false)
}

// MARK: - Defaults Conformance Extensions

extension Folder: Defaults.Serializable {}
extension GitRepoSettings: Defaults.Serializable {}
extension TerminalSettings: Defaults.Serializable {}
extension SearchToken: Defaults.Serializable {}
extension NotesToRepoSettings: Defaults.Serializable {}