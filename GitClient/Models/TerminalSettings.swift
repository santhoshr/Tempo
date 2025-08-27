//
//  TerminalSettings.swift
//  GitClient
//
//  Created by Kiro on 2025/08/27.
//

import Foundation
import AppKit

struct TerminalApp: Codable, Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    let executableName: String
    let appURL: URL?
    let defaultArguments: String
    let launchType: LaunchType
    
    // Known terminal applications with their bundle identifiers and default arguments
    private static let knownTerminals: [(name: String, bundleId: String, executable: String, defaultArgs: String, launchType: LaunchType)] = [
        ("Terminal", "com.apple.Terminal", "Terminal", "cd '{REPO_PATH}'", .applescript("Terminal", "do script")),
        ("iTerm2", "com.googlecode.iterm2", "iTerm", "cd '{REPO_PATH}'", .applescript("iTerm", "create window with default profile")),
        ("Alacritty", "org.alacritty", "Alacritty", "--working-directory '{REPO_PATH}'", .openCommand("Alacritty")),
        ("Kitty", "net.kovidgoyal.kitty", "kitty", "--directory '{REPO_PATH}' -- /bin/zsh -l", .openCommand("kitty")),
        ("Tabby", "org.tabby", "Tabby", "--working-directory '{REPO_PATH}'", .openCommand("Tabby")),
        ("WezTerm", "com.github.wez.wezterm", "WezTerm", "start --cwd '{REPO_PATH}'", .openCommand("WezTerm")),
        ("Rio", "com.raphamorim.rio", "Rio", "--working-directory '{REPO_PATH}'", .openCommand("Rio")),
        ("Ghostty", "com.mitchellh.ghostty", "Ghostty", "'{REPO_PATH}'", .openCommand("Ghostty")),
        ("Contour", "org.contourterminal.contour", "Contour", "--working-directory '{REPO_PATH}'", .openCommand("Contour"))
    ]
    
    enum LaunchType: Codable, Hashable {
        case applescript(String, String) // app name, command
        case openCommand(String) // app name
    }
    
    static var availableTerminals: [TerminalApp] {
        var terminals: [TerminalApp] = []
        
        // Check known terminals first (these are guaranteed to be terminals)
        for (name, bundleId, executable, defaultArgs, launchType) in knownTerminals {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                terminals.append(TerminalApp(
                    name: name,
                    bundleIdentifier: bundleId,
                    executableName: executable,
                    appURL: appURL,
                    defaultArguments: defaultArgs,
                    launchType: launchType
                ))
            }
        }
        
        return terminals.sorted { $0.name < $1.name }
    }
    
    var isInstalled: Bool {
        appURL != nil
    }
    
    private func parseShellArguments(_ string: String) -> [String] {
        var arguments: [String] = []
        var currentArg = ""
        var inSingleQuote = false
        var inDoubleQuote = false
        var escaped = false
        
        for char in string {
            if escaped {
                currentArg.append(char)
                escaped = false
            } else if char == "\\" && !inSingleQuote {
                escaped = true
            } else if char == "'" && !inDoubleQuote {
                inSingleQuote.toggle()
            } else if char == "\"" && !inSingleQuote {
                inDoubleQuote.toggle()
            } else if char == " " && !inSingleQuote && !inDoubleQuote {
                if !currentArg.isEmpty {
                    arguments.append(currentArg)
                    currentArg = ""
                }
            } else {
                currentArg.append(char)
            }
        }
        
        if !currentArg.isEmpty {
            arguments.append(currentArg)
        }
        
        return arguments
    }
    
    private func executeDirectCommand(_ executable: String, arguments: [String]) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: executable)
        task.arguments = arguments
        
        do {
            try task.run()
        } catch {
            print("Failed to execute command: \(error)")
        }
    }
    
    func openTerminal(at path: URL, customArguments: String? = nil) {
        let arguments = customArguments ?? defaultArguments
        let pathString = path.path
        
        print("=== DEBUG: Opening terminal ===")
        print("Terminal: \(name)")
        print("Path: \(pathString)")
        print("Arguments template: \(arguments)")
        print("Launch type: \(launchType)")
        
        switch launchType {
        case .applescript(let appName, let command):
            // For AppleScript commands - handle Terminal.app and iTerm2 specially
            if appName == "Terminal" {
                // Special Terminal.app handling with fallback mechanism
                // Try opening Terminal with the working directory using open command
                let openArgs = ["-na", "Terminal.app", "--args", pathString]
                print("Trying open command first: open \(openArgs.joined(separator: " "))")
                
                let openTask = Process()
                openTask.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                openTask.arguments = openArgs
                
                do {
                    try openTask.run()
                    openTask.waitUntilExit()
                    
                    // If that doesn't work, fall back to AppleScript
                    if openTask.terminationStatus != 0 {
                        let escapedPath = pathString.replacingOccurrences(of: "\"", with: "\\\"")
                        let fullScript = """
tell application "Terminal"
    activate
    do script "cd \"\(escapedPath)\"; clear; pwd"
end tell
"""
                        print("Open failed, trying AppleScript: \(fullScript)")
                        
                        let task = Process()
                        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                        task.arguments = ["-e", fullScript]
                        
                        try task.run()
                        task.waitUntilExit()
                    }
                } catch {
                    print("Failed to execute Terminal command: \(error)")
                }
                return
            }
            
            if appName == "iTerm" {
                // Special iTerm2 handling - open with working directory directly
                let fullScript = """
tell application "iTerm"
    activate
    set newWindow to (create window with default profile)
    tell current session of newWindow
        write text "cd '\(pathString)' && clear"
    end tell
end tell
"""
                print("Executing iTerm2 AppleScript: \(fullScript)")
                
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                task.arguments = ["-e", fullScript]
                
                do {
                    try task.run()
                    task.waitUntilExit()
                } catch {
                    print("Failed to execute iTerm2 AppleScript: \(error)")
                }
                return
            }
            
            // For other terminals using AppleScript
            let scriptCommand = arguments.replacingOccurrences(of: "{REPO_PATH}", with: pathString)
            let fullScript = "tell application \"\(appName)\"\n\tactivate\n\t\(command) \"\(scriptCommand)\"\nend tell"
            
            print("Executing AppleScript: \(fullScript)")
            
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            task.arguments = ["-e", fullScript]
            
            do {
                try task.run()
            } catch {
                print("Failed to execute AppleScript: \(error)")
            }
            
        case .openCommand(let appName):
            // Improved argument handling with proper quoting
            let processedArgs = arguments.replacingOccurrences(of: "'{REPO_PATH}'", with: pathString)
                .replacingOccurrences(of: "{REPO_PATH}", with: pathString)
            
            // Parse shell arguments properly instead of splitting by spaces
            let argComponents = parseShellArguments(processedArgs)
            var openArgs = ["-na", appName, "--args"]
            openArgs.append(contentsOf: argComponents)
            
            print("Final open args: \(openArgs)")
            print("Executing open command: open \(openArgs.joined(separator: " "))")
            executeDirectCommand("/usr/bin/open", arguments: openArgs)
        }
    }
    

}

struct TerminalSettings: Codable {
    var preferredTerminal: String // Bundle identifier
    var customCommands: [String: String] = [:] // Bundle identifier -> custom command
    
    init() {
        // Default to Terminal.app if available, otherwise first available
        self.preferredTerminal = TerminalApp.availableTerminals.first?.bundleIdentifier ?? "com.apple.Terminal"
    }
    
    var selectedTerminal: TerminalApp? {
        return TerminalApp.availableTerminals.first { $0.bundleIdentifier == preferredTerminal }
    }
    
    func customArguments(for bundleId: String) -> String? {
        return customCommands[bundleId]
    }
    
    mutating func setCustomArguments(_ arguments: String?, for bundleId: String) {
        if let arguments = arguments, !arguments.isEmpty {
            customCommands[bundleId] = arguments
        } else {
            customCommands.removeValue(forKey: bundleId)
        }
    }
    
    static var allOptions: [(name: String, bundleId: String)] {
        let terminals = TerminalApp.availableTerminals
        return terminals.map { ($0.name, $0.bundleIdentifier) }
    }
}