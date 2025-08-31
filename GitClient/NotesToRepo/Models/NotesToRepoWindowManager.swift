//
//  NotesToRepoWindowManager.swift
//  GitClient
//
//  Created by Claude on 2025/08/31.
//

import Foundation
import AppKit
import SwiftUI

class NotesToRepoWindowManager {
    private static var openWindows: [String: NSWindowController] = [:]
    
    /// Opens or activates a Notes to Repo window for the specified folder
    static func openWindow(for folderURL: URL) {
        let folderPath = folderURL.path
        
        // Check if window is already open for this directory
        if let existingController = openWindows[folderPath],
           let window = existingController.window,
           !window.isReleasedWhenClosed {
            // Window exists and is still valid, just bring it to front
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create new window
        let windowController = createWindowController(for: folderURL)
        
        // Store reference
        openWindows[folderPath] = windowController
        
        // Set up cleanup when window closes
        if let window = windowController.window {
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { _ in
                openWindows.removeValue(forKey: folderPath)
            }
        }
        
        // Show window
        windowController.showWindow(nil)
        windowController.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private static func createWindowController(for folderURL: URL) -> NSWindowController {
        let windowController = NSWindowController(window: NotesToRepoWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        ))
        
        windowController.window?.setFrameAutosaveName("NotesToRepoWindow")
        
        // Only center the window if no saved frame exists
        if !windowController.window!.setFrameUsingName("NotesToRepoWindow") {
            windowController.window?.center()
        }
        windowController.window?.contentView = NSHostingView(
            rootView: NotesToRepoPopupView()
                .environment(\.folder, folderURL)
        )
        
        let folderName = folderURL.lastPathComponent
        windowController.window?.title = "Repository Notes - \(folderName)"
        
        return windowController
    }
    
    /// Closes window for the specified folder if it exists
    static func closeWindow(for folderURL: URL) {
        let folderPath = folderURL.path
        if let windowController = openWindows[folderPath] {
            windowController.close()
            openWindows.removeValue(forKey: folderPath)
        }
    }
    
    /// Returns true if a window is open for the specified folder
    static func isWindowOpen(for folderURL: URL) -> Bool {
        let folderPath = folderURL.path
        return openWindows[folderPath] != nil
    }
}