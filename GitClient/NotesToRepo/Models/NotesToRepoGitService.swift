//
//  NotesToRepoGitService.swift
//  GitClient
//
//  Created by Claude on 2025/08/31.
//

import Foundation

class NotesToRepoGitService {
    
    // MARK: - Git Repository Detection
    
    static func isGitRepository(at path: String) -> Bool {
        guard !path.isEmpty else { return false }
        
        let notesURL = URL(fileURLWithPath: path)
        let gitPath = notesURL.appendingPathComponent(".git")
        
        // Check for regular git directory or git worktree file
        let isDirectory = FileManager.default.fileExists(atPath: gitPath.path) && 
                         (try? gitPath.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
        let isFile = FileManager.default.fileExists(atPath: gitPath.path) && 
                    (try? gitPath.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == false
        
        let result = isDirectory || isFile
        print("DEBUG: Git repo check - path: \(gitPath.path), isDirectory: \(isDirectory), isFile: \(isFile), result: \(result)")
        return result
    }
    
    // MARK: - Git Status Operations
    
    static func checkGitStatus(at notesURL: URL) async -> (hasChanges: Bool, currentFileChanges: Bool, relativePath: String?) {
        do {
            let gitStatus = GitStatus(directory: notesURL)
            let status = try await Process.output(gitStatus)
            
            let hasChanges = !status.untrackedFiles.isEmpty || 
                           !status.unmergedFiles.isEmpty || 
                           !status.modifiedFiles.isEmpty || 
                           !status.addedFiles.isEmpty ||
                           !status.deletedFiles.isEmpty
            
            return (hasChanges: hasChanges, currentFileChanges: false, relativePath: nil)
        } catch {
            print("DEBUG: Git status check failed: \(error)")
            return (hasChanges: false, currentFileChanges: false, relativePath: nil)
        }
    }
    
    static func checkCurrentFileGitStatus(file: NoteFile?, notesURL: URL) async -> Bool {
        guard let file = file else { return false }
        
        do {
            let gitStatus = GitStatus(directory: notesURL)
            let status = try await Process.output(gitStatus)
            
            // Get relative path of current file more reliably
            let relativePath: String
            if file.url.path.hasPrefix(notesURL.path + "/") {
                relativePath = String(file.url.path.dropFirst(notesURL.path.count + 1))
            } else {
                relativePath = file.url.lastPathComponent
            }
            
            // Check if current file has any uncommitted changes
            let hasChanges = status.untrackedFiles.contains(relativePath) ||
                           status.unmergedFiles.contains(relativePath) ||
                           status.modifiedFiles.contains(relativePath) ||
                           status.addedFiles.contains(relativePath) ||
                           status.deletedFiles.contains(relativePath)
            
            return hasChanges
        } catch {
            print("DEBUG: Current file git status check failed: \(error)")
            return false
        }
    }
    
    // MARK: - Auto-commit Operations
    
    static func performAutoCommit(for filePath: String, action: String, isDeleted: Bool = false, notesURL: URL) async throws {
        let commitMessage = "\(filePath) \(action)\n\n🤖 Generated with [Claude Code](https://claude.ai/code)\n\nCo-Authored-By: Claude <noreply@anthropic.com>"
        
        print("DEBUG: === AUTOCOMMIT START ===")
        print("DEBUG: File: \(filePath), Action: \(action), isDeleted: \(isDeleted)")
        print("DEBUG: Notes URL: \(notesURL.path)")
        print("DEBUG: Commit message: \(commitMessage)")
        
        do {
            // Pre-flight checks
            try await validateGitRepository(at: notesURL)
            
            // Check if there are actually changes to commit
            let hasChanges = try await checkForChanges(in: notesURL)
            guard hasChanges else {
                print("DEBUG: No changes detected, skipping commit")
                return
            }
            
            // Add files with better error handling
            try await addFilesToGit(directory: notesURL, specificFile: filePath, isDeleted: isDeleted)
            
            print("DEBUG: Files added successfully, attempting commit")
            
            // Commit changes with validation
            try await commitChanges(directory: notesURL, message: commitMessage)
            
            print("DEBUG: Auto commit successful for: \(filePath)")
            
        } catch {
            print("DEBUG: === AUTOCOMMIT FAILED ===")
            print("DEBUG: Error type: \(type(of: error))")
            print("DEBUG: Error: \(error)")
            print("DEBUG: Error description: \(error.localizedDescription)")
            
            if let processError = error as? ProcessError {
                print("DEBUG: ProcessError details: \(processError.errorDescription ?? "No description")")
            }
            
            throw GenericError(errorDescription: "Auto-commit failed for \(filePath): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Git Helper Methods
    
    private static func validateGitRepository(at directory: URL) async throws {
        // Check if directory exists
        guard FileManager.default.fileExists(atPath: directory.path) else {
            throw GenericError(errorDescription: "Notes directory does not exist: \(directory.path)")
        }
        
        // Check if it's a git repository
        let gitPath = directory.appendingPathComponent(".git")
        let isGitDir = FileManager.default.fileExists(atPath: gitPath.path)
        
        // Also check for git worktree (single .git file)
        let gitFile = directory.appendingPathComponent(".git")
        let isGitFile = FileManager.default.fileExists(atPath: gitFile.path) && !isGitDir
        
        guard isGitDir || isGitFile else {
            throw GenericError(errorDescription: "Directory is not a git repository: \(directory.path)")
        }
        
        // Check git user configuration - common cause of commit failures
        do {
            print("DEBUG: Checking git user configuration...")
            let gitConfigName = Process()
            gitConfigName.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            gitConfigName.arguments = ["config", "user.name"]
            gitConfigName.currentDirectoryURL = directory
            
            let gitConfigEmail = Process()
            gitConfigEmail.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            gitConfigEmail.arguments = ["config", "user.email"]
            gitConfigEmail.currentDirectoryURL = directory
            
            let namePipe = Pipe()
            let emailPipe = Pipe()
            gitConfigName.standardOutput = namePipe
            gitConfigEmail.standardOutput = emailPipe
            
            try gitConfigName.run()
            try gitConfigEmail.run()
            
            gitConfigName.waitUntilExit()
            gitConfigEmail.waitUntilExit()
            
            let nameData = namePipe.fileHandleForReading.readDataToEndOfFile()
            let emailData = emailPipe.fileHandleForReading.readDataToEndOfFile()
            
            let userName = String(data: nameData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let userEmail = String(data: emailData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            print("DEBUG: Git user name: '\(userName)'")
            print("DEBUG: Git user email: '\(userEmail)'")
            
            if userName.isEmpty || userEmail.isEmpty {
                throw GenericError(errorDescription: "Git user not configured. Run: git config user.name 'Your Name' && git config user.email 'your@email.com'")
            }
            
        } catch {
            print("DEBUG: Git user config check failed: \(error)")
            throw GenericError(errorDescription: "Git user configuration required for commits: \(error.localizedDescription)")
        }
        
        print("DEBUG: Git repository validation passed")
    }
    
    private static func checkForChanges(in directory: URL) async throws -> Bool {
        do {
            let gitStatus = GitStatus(directory: directory)
            let status = try await Process.output(gitStatus)
            
            let hasChanges = !status.untrackedFiles.isEmpty || 
                           !status.modifiedFiles.isEmpty || 
                           !status.addedFiles.isEmpty ||
                           !status.deletedFiles.isEmpty ||
                           !status.unmergedFiles.isEmpty
            
            print("DEBUG: Change detection - untracked: \(status.untrackedFiles.count), modified: \(status.modifiedFiles.count), added: \(status.addedFiles.count), deleted: \(status.deletedFiles.count)")
            
            return hasChanges
        } catch {
            print("DEBUG: Failed to check git status, assuming changes exist: \(error)")
            return true // Assume changes exist if we can't check
        }
    }
    
    private static func addFilesToGit(directory: URL, specificFile: String, isDeleted: Bool = false) async throws {
        print("DEBUG: addFilesToGit called with directory: \(directory.path), specificFile: \(specificFile), isDeleted: \(isDeleted)")
        
        // For deleted files, we need to use git add . to stage the deletion
        // because git add <specific-file> will fail when the file doesn't exist
        if isDeleted {
            print("DEBUG: File was deleted, using git add . to stage deletion")
            let gitAddAll = GitAdd(directory: directory)
            print("DEBUG: Executing git command: \(gitAddAll.arguments.joined(separator: " ")) in \(directory.path)")
            try await Process.output(gitAddAll)
            print("DEBUG: Successfully staged deletion via git add .")
            return
        }
        
        // For existing files, try to add the specific file first
        do {
            let gitAddFile = GitAddPathspec(directory: directory, pathspec: specificFile)
            print("DEBUG: Executing git command: \(gitAddFile.arguments.joined(separator: " ")) in \(directory.path)")
            try await Process.output(gitAddFile)
            print("DEBUG: Successfully added specific file: \(specificFile)")
        } catch {
            print("DEBUG: Failed to add specific file \(specificFile), error: \(error)")
            print("DEBUG: Error type: \(type(of: error))")
            
            if let processError = error as? ProcessError {
                print("DEBUG: ProcessError description: \(processError.errorDescription ?? "None")")
            }
            
            print("DEBUG: Trying fallback to add all files...")
            
            // Fallback to adding all files
            let gitAddAll = GitAdd(directory: directory)
            print("DEBUG: Executing fallback git command: \(gitAddAll.arguments.joined(separator: " ")) in \(directory.path)")
            try await Process.output(gitAddAll)
            print("DEBUG: Successfully added all files via fallback")
        }
    }
    
    private static func commitChanges(directory: URL, message: String) async throws {
        print("DEBUG: commitChanges called with directory: \(directory.path)")
        print("DEBUG: Commit message: \(message)")
        
        // Check if there are staged changes before committing
        do {
            let gitStatus = GitStatus(directory: directory)
            print("DEBUG: Checking git status before commit...")
            let status = try await Process.output(gitStatus)
            
            print("DEBUG: Git status - addedFiles: \(status.addedFiles.count), modifiedFiles: \(status.modifiedFiles.count), unmergedFiles: \(status.unmergedFiles.count)")
            print("DEBUG: addedFiles: \(status.addedFiles)")
            print("DEBUG: modifiedFiles: \(status.modifiedFiles)")
            print("DEBUG: unmergedFiles: \(status.unmergedFiles)")
            
            let hasStagedChanges = !status.addedFiles.isEmpty ||
                                 !status.modifiedFiles.isEmpty ||
                                 !status.deletedFiles.isEmpty ||
                                 !status.unmergedFiles.isEmpty
            
            print("DEBUG: hasStagedChanges: \(hasStagedChanges)")
            
            guard hasStagedChanges else {
                throw GenericError(errorDescription: "No staged changes to commit")
            }
        } catch let statusError {
            print("DEBUG: Could not check staged changes, proceeding with commit: \(statusError)")
        }
        
        // Perform the commit
        let gitCommit = GitCommit(directory: directory, message: message)
        print("DEBUG: Executing commit command: \(gitCommit.arguments.joined(separator: " ")) in \(directory.path)")
        try await Process.output(gitCommit)
        print("DEBUG: Commit completed successfully")
    }
}