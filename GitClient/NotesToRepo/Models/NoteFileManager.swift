//
//  NoteFileManager.swift
//  GitClient
//
//  Created by Claude on 2025/08/31.
//

import Foundation

class NoteFileManager: ObservableObject {
    
    // MARK: - File Loading
    
    static func loadNoteFiles(for folder: URL?, settings: NotesToRepoSettings) -> [NoteFile] {
        guard folder != nil,
              !settings.notesLocation.isEmpty else { return [] }
        
        let repoName = getRepositoryName(for: folder)
        let notesURL = URL(fileURLWithPath: settings.notesLocation)
        
        // Use recursive enumeration to find files in subdirectories
        let fileURLs = FileManager.default.enumerator(
                at: notesURL,
                includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey, .isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )?.compactMap { element -> URL? in
                guard let url = element as? URL else { return nil }
                
                // Only include files, not directories
                let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey])
                let isDirectory = resourceValues?.isDirectory ?? false
                
                return isDirectory ? nil : url
            } ?? []
            
        return fileURLs
            .filter { $0.pathExtension == "md" }
            .filter { fileURL in
                // Get the full relative path from notes directory
                let relativePath = fileURL.path.replacingOccurrences(of: notesURL.path + "/", with: "")
                
                // Check if the path contains the repo name in various patterns:
                // 1. Flat: {REPO_NAME}_DDMMYYYYHHMMSS.md
                // 2. Nested: {REPO_NAME}/dummy_folder/{REPO_NAME}_DDMMYYYYHHMMSS.md
                // 3. Timestamped: DDMMYYYYHHMMSS/{REPO_NAME}/DDMMYYYYHHMMSS.md
                // 4. Any path component contains repo name
                
                let fileName = fileURL.lastPathComponent
                let nameWithoutExtension = String(fileName.dropLast(3)) // Remove .md
                let pathComponents = relativePath.components(separatedBy: "/")
                
                // STRICT filename matching - only exact patterns
                let fileNameMatches = nameWithoutExtension.hasPrefix(repoName + "_") || 
                                     nameWithoutExtension == repoName
                
                // STRICT path component matching - only exact repo name as folder
                let pathContainsRepo = pathComponents.contains(repoName)
                
                // Additional strict check: if filename contains repo name, it must be at word boundaries
                let strictFileNameMatch = isRepoNameInFileName(fileName: nameWithoutExtension, repoName: repoName)
                
                return fileNameMatches || pathContainsRepo || strictFileNameMatch
            }
            .compactMap { url in
                guard let resourceValues = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey]),
                      let creationDate = resourceValues.creationDate,
                      let modificationDate = resourceValues.contentModificationDate else {
                    return nil
                }
                // Calculate relative path for display
                let relativePath = url.path.replacingOccurrences(of: notesURL.path + "/", with: "")
                
                return NoteFile(
                    id: url.absoluteString,
                    name: url.lastPathComponent,
                    relativePath: relativePath,
                    url: url,
                    creationDate: creationDate,
                    modificationDate: modificationDate
                )
            }
            .sorted { $0.creationDate > $1.creationDate }
    }
    
    private static func isRepoNameInFileName(fileName: String, repoName: String) -> Bool {
        // Check if repo name appears as a complete word in filename
        // This prevents "Tempo" from matching "TempoSTC"
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: repoName))\\b"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: fileName.utf16.count)
        return regex?.firstMatch(in: fileName, options: [], range: range) != nil
    }
    
    // MARK: - Repository Name Detection
    
    static func getRepositoryName(for folder: URL?) -> String {
        guard let folder = folder else { return "Unknown" }
        
        // Check if this is a git worktree first
        if let worktreeRepoName = getWorktreeRepositoryName(folder: folder) {
            return worktreeRepoName
        }
        
        // Try to get the actual repository name from git remote origin URL
        let gitConfigURL = folder.appendingPathComponent(".git/config")
        
        if FileManager.default.fileExists(atPath: gitConfigURL.path) {
            do {
                let gitConfig = try String(contentsOf: gitConfigURL)
                
                // Look for remote origin URL (same logic as existing app)
                let lines = gitConfig.components(separatedBy: .newlines)
                var inOriginSection = false
                
                for line in lines {
                    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                    
                    if trimmedLine == "[remote \"origin\"]" {
                        inOriginSection = true
                        continue
                    }
                    
                    if trimmedLine.hasPrefix("[") && trimmedLine != "[remote \"origin\"]" {
                        inOriginSection = false
                        continue
                    }
                    
                    if inOriginSection && trimmedLine.hasPrefix("url = ") {
                        let urlString = String(trimmedLine.dropFirst(6))
                        return extractRepoNameFromGitURL(urlString, fallbackFolder: folder)
                    }
                }
            } catch {
                // If we can't read git config, fall back to folder name
            }
        }
        
        // Fallback to folder name if git config method fails
        return folder.lastPathComponent
    }
    
    private static func getWorktreeRepositoryName(folder: URL) -> String? {
        let gitPath = folder.appendingPathComponent(".git")
        
        // Check if .git is a file (worktree) instead of a directory
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: gitPath.path, isDirectory: &isDirectory)
        
        if exists && !isDirectory.boolValue {
            // This is a worktree - .git is a file containing path to main repo
            do {
                let gitFileContent = try String(contentsOf: gitPath)
                
                // Parse the gitdir line: "gitdir: /path/to/main/repo/.git/worktrees/branch-name"
                for line in gitFileContent.components(separatedBy: .newlines) {
                    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                    if trimmedLine.hasPrefix("gitdir: ") {
                        let gitDirPath = String(trimmedLine.dropFirst(8))
                        
                        // Navigate to main repository's .git/config
                        // From: /path/to/main/repo/.git/worktrees/branch-name
                        // To:   /path/to/main/repo/.git/config
                        let gitDirURL = URL(fileURLWithPath: gitDirPath)
                        let mainGitDir = gitDirURL.deletingLastPathComponent().deletingLastPathComponent()
                        let mainConfigURL = mainGitDir.appendingPathComponent("config")
                        
                        if FileManager.default.fileExists(atPath: mainConfigURL.path) {
                            let mainConfig = try String(contentsOf: mainConfigURL)
                            return extractRepoNameFromConfig(mainConfig, fallbackFolder: folder)
                        }
                    }
                }
            } catch {
                print("Failed to read worktree git file: \(error)")
            }
        }
        
        return nil
    }
    
    private static func extractRepoNameFromConfig(_ gitConfig: String, fallbackFolder: URL) -> String? {
        let lines = gitConfig.components(separatedBy: .newlines)
        var inOriginSection = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine == "[remote \"origin\"]" {
                inOriginSection = true
                continue
            }
            
            if trimmedLine.hasPrefix("[") && trimmedLine != "[remote \"origin\"]" {
                inOriginSection = false
                continue
            }
            
            if inOriginSection && trimmedLine.hasPrefix("url = ") {
                let urlString = String(trimmedLine.dropFirst(6))
                return extractRepoNameFromGitURL(urlString, fallbackFolder: fallbackFolder)
            }
        }
        
        return nil
    }
    
    private static func extractRepoNameFromGitURL(_ urlString: String, fallbackFolder: URL) -> String {
        var cleanURL = urlString
        
        // Remove .git suffix if present
        if cleanURL.hasSuffix(".git") {
            cleanURL = String(cleanURL.dropLast(4))
        }
        
        // Extract repo name from different URL formats:
        // https://github.com/user/repo
        // git@github.com:user/repo
        // https://gitlab.com/user/repo
        
        if let lastSlash = cleanURL.lastIndex(of: "/") {
            return String(cleanURL[cleanURL.index(after: lastSlash)...])
        } else if cleanURL.contains(":") {
            // Handle SSH format like git@github.com:user/repo
            let parts = cleanURL.components(separatedBy: ":")
            if let lastPart = parts.last, let lastSlash = lastPart.lastIndex(of: "/") {
                return String(lastPart[lastPart.index(after: lastSlash)...])
            } else if let lastPart = parts.last {
                return lastPart
            }
        }
        
        // If all else fails, return the folder name
        return fallbackFolder.lastPathComponent
    }
    
    // MARK: - File Name Generation
    
    static func generateNewFileName(settings: NotesToRepoSettings, folder: URL?, selectedNote: NoteFile?) -> String {
        let repoName = getRepositoryName(for: folder)
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMyyyyHHmmss"
        let timestamp = formatter.string(from: Date())
        
        // If there's a selected note, use its directory path and create a simpler filename
        if let selectedNote = selectedNote {
            let selectedDirectory = selectedNote.url.deletingLastPathComponent()
            let notesBaseURL = URL(fileURLWithPath: settings.notesLocation)
            
            // Only use the selected note's directory if it's within the notes location
            if selectedDirectory.path.hasPrefix(notesBaseURL.path) {
                let relativePath = selectedDirectory.path.replacingOccurrences(of: notesBaseURL.path, with: "").trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                
                if !relativePath.isEmpty {
                    // Create a simpler filename since we're in a directory context
                    // Use just timestamp or a simple pattern to avoid double repo names
                    let simpleFileName = settings.noteNameFormat.contains("{REPO_NAME}") ? 
                        timestamp + ".md" : 
                        settings.noteNameFormat.replacingOccurrences(of: "DDMMYYYYHHMMSS", with: timestamp) + ".md"
                    
                    return relativePath + "/" + simpleFileName
                }
            }
        }
        
        // For root directory, use the full template with repo name
        let fileName = settings.noteNameFormat
            .replacingOccurrences(of: "{REPO_NAME}", with: repoName)
            .replacingOccurrences(of: "DDMMYYYYHHMMSS", with: timestamp) + ".md"
        
        return fileName
    }
}