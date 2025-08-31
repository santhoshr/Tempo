//
//  NotesToRepoWindow.swift
//  GitClient
//
//  Created by Claude on 2025/08/31.
//

import AppKit
import SwiftUI

class NotesToRepoWindow: NSWindow {
    
    override func keyDown(with event: NSEvent) {
        // Handle Cmd+N specifically for Notes to Repo
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "n" {
            // Send notification that a new note should be created
            NotificationCenter.default.post(name: NSNotification.Name("CreateNewNoteFromWindow"), object: nil)
            return
        }
        
        // For all other keys, use default behavior
        super.keyDown(with: event)
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Handle Cmd+N at the key equivalent level (higher priority)
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "n" {
            NotificationCenter.default.post(name: NSNotification.Name("CreateNewNoteFromWindow"), object: nil)
            return true
        }
        
        return super.performKeyEquivalent(with: event)
    }
}