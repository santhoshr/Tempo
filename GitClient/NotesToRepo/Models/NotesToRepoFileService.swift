//
//  NotesToRepoFileService.swift
//  GitClient
//
//  Created by Claude on 2025/08/31.
//

import Foundation
import Defaults

class NotesToRepoFileService {
    
    // MARK: - Note Creation
    
    static func createNewNote(settings: NotesToRepoSettings, folder: URL?, selectedNote: NoteFile?) -> (fileName: String, content: String, originalContent: String, isDirty: Bool) {
        let fileName = NoteFileManager.generateNewFileName(settings: settings, folder: folder, selectedNote: selectedNote)
        return (fileName: fileName, content: "", originalContent: "", isDirty: false)
    }
    
    // MARK: - Note Loading
    
    static func loadNoteContent(from noteFile: NoteFile) throws -> (content: String, originalContent: String, isDirty: Bool) {
        let content = try String(contentsOf: noteFile.url)
        return (content: content, originalContent: content, isDirty: false)
    }
    
    // MARK: - Note Saving
    
    static func saveNote(
        content: String,
        selectedNote: NoteFile?,
        newFileName: String,
        notesLocation: String,
        isCreatingNew: Bool
    ) throws -> (savedURL: URL, wasCreatingNew: Bool) {
        guard !notesLocation.isEmpty else {
            throw GenericError(errorDescription: "Notes location is not configured")
        }
        
        let notesURL = URL(fileURLWithPath: notesLocation)
        let fileURL: URL
        
        if let selectedNote = selectedNote {
            fileURL = selectedNote.url
        } else {
            fileURL = notesURL.appendingPathComponent(newFileName)
            
            // Ensure directory exists if the filename includes a path
            let directory = fileURL.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
        }
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return (savedURL: fileURL, wasCreatingNew: isCreatingNew)
    }
    
    // MARK: - Auto-commit Integration
    
    static func saveNoteWithAutoCommit(
        content: String,
        selectedNote: NoteFile?,
        newFileName: String,
        settings: NotesToRepoSettings,
        isCreatingNew: Bool,
        isGitRepo: Bool
    ) async throws -> (savedURL: URL, wasCreatingNew: Bool) {
        
        let result = try saveNote(
            content: content,
            selectedNote: selectedNote,
            newFileName: newFileName,
            notesLocation: settings.notesLocation,
            isCreatingNew: isCreatingNew
        )
        
        // Perform auto-commit if it's a git repository
        if isGitRepo {
            let notesURL = URL(fileURLWithPath: settings.notesLocation)
            let relativePath = result.savedURL.path.hasPrefix(notesURL.path + "/") ?
                String(result.savedURL.path.dropFirst(notesURL.path.count + 1)) :
                result.savedURL.lastPathComponent
            
            try await NotesToRepoGitService.performAutoCommit(
                for: relativePath,
                action: isCreatingNew ? "added" : "edited",
                notesURL: notesURL
            )
        }
        
        return result
    }
    
    // MARK: - Note Deletion
    
    static func deleteNote(_ noteFile: NoteFile) throws {
        try FileManager.default.removeItem(at: noteFile.url)
    }
    
    static func deleteNoteWithAutoCommit(
        _ noteFile: NoteFile,
        settings: NotesToRepoSettings,
        isGitRepo: Bool
    ) async throws {
        
        let notesURL = URL(fileURLWithPath: settings.notesLocation)
        let relativePath = noteFile.url.path.hasPrefix(notesURL.path + "/") ?
            String(noteFile.url.path.dropFirst(notesURL.path.count + 1)) :
            noteFile.url.lastPathComponent
        
        // Delete the file first
        try deleteNote(noteFile)
        
        // Perform auto-commit if it's a git repository
        if isGitRepo {
            try await NotesToRepoGitService.performAutoCommit(
                for: relativePath,
                action: "deleted",
                isDeleted: true,
                notesURL: notesURL
            )
        }
    }
    
    // MARK: - File State Management
    
    static func updateFileInList(
        _ noteFiles: inout [NoteFile],
        savedURL: URL,
        notesLocation: String,
        wasCreatingNew: Bool
    ) -> NoteFile? {
        
        let notesURL = URL(fileURLWithPath: notesLocation)
        
        if wasCreatingNew {
            // Create new note file entry
            guard let resourceValues = try? savedURL.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey]),
                  let creationDate = resourceValues.creationDate,
                  let modificationDate = resourceValues.contentModificationDate else {
                return nil
            }
            
            let relativePath = savedURL.path.replacingOccurrences(of: notesURL.path + "/", with: "")
            
            let newNote = NoteFile(
                id: savedURL.absoluteString,
                name: savedURL.lastPathComponent,
                relativePath: relativePath,
                url: savedURL,
                creationDate: creationDate,
                modificationDate: modificationDate
            )
            
            // Add to the beginning of the list (newest first)
            noteFiles.insert(newNote, at: 0)
            return newNote
            
        } else {
            // Update existing note in list
            guard let existingIndex = noteFiles.firstIndex(where: { $0.url == savedURL }) else {
                return nil
            }
            
            let existingNote = noteFiles[existingIndex]
            guard let resourceValues = try? savedURL.resourceValues(forKeys: [.contentModificationDateKey]),
                  let modificationDate = resourceValues.contentModificationDate else {
                return existingNote
            }
            
            let updatedNote = NoteFile(
                id: existingNote.id,
                name: existingNote.name,
                relativePath: existingNote.relativePath,
                url: existingNote.url,
                creationDate: existingNote.creationDate,
                modificationDate: modificationDate
            )
            
            noteFiles[existingIndex] = updatedNote
            return updatedNote
        }
    }
    
    // MARK: - Navigation Helpers
    
    static func findNavigationTarget(
        in noteFiles: [NoteFile],
        after deletedIndex: Int
    ) -> NoteFile? {
        guard !noteFiles.isEmpty else { return nil }
        
        var nextIndex = deletedIndex
        if nextIndex >= noteFiles.count {
            nextIndex = noteFiles.count - 1
        }
        
        if nextIndex >= 0 && nextIndex < noteFiles.count {
            return noteFiles[nextIndex]
        }
        
        return nil
    }
    
    // MARK: - File Restoration
    
    static func findFileToRestore(
        in noteFiles: [NoteFile],
        lastOpenedFileID: String?
    ) -> NoteFile? {
        guard let lastFileID = lastOpenedFileID,
              let fileToRestore = noteFiles.first(where: { $0.id == lastFileID }) else {
            return nil
        }
        
        // Check if file still exists on disk
        if FileManager.default.fileExists(atPath: fileToRestore.url.path) {
            return fileToRestore
        }
        
        return nil
    }
}