//
//  TerminalSettingsView.swift
//  GitClient
//
//  Created by Kiro on 2025/08/27.
//

import SwiftUI
import Defaults

struct TerminalSettingsView: View {
    @Default(.terminalSettings) private var terminalSettings
    @State private var error: Error?
    @State private var refreshTrigger = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Terminal Settings")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Configure your preferred terminal application for opening project directories")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                

                // Terminal Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Preferred Terminal")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Terminal Application:")
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Picker("Terminal", selection: $terminalSettings.preferredTerminal) {
                                ForEach(TerminalSettings.allOptions, id: \.1) { option in
                                    Text(option.0).tag(option.1)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(minWidth: 200)
                            .onChange(of: terminalSettings.preferredTerminal) {
                                // Settings automatically saved via Defaults
                            }
                        }
                        
                        // Show current selection info
                        if let selectedTerminal = terminalSettings.selectedTerminal {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Selected: \(selectedTerminal.name)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(selectedTerminal.bundleIdentifier)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                
                                // Custom launch arguments section - hide for Apple Terminal
                                if selectedTerminal.bundleIdentifier != "com.apple.Terminal" {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Launch Arguments:")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text("Use {REPO_PATH} as placeholder for the repository directory. Only terminal-specific arguments are allowed.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        TextField("Launch arguments", text: Binding(
                                            get: {
                                                terminalSettings.customArguments(for: selectedTerminal.bundleIdentifier) ?? selectedTerminal.defaultArguments
                                            },
                                            set: { newValue in
                                                terminalSettings.setCustomArguments(newValue == selectedTerminal.defaultArguments ? nil : newValue, for: selectedTerminal.bundleIdentifier)
                                                // Settings automatically saved via Defaults
                                            }
                                        ))
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                        
                                        HStack {
                                            Button("Reset to Default") {
                                                terminalSettings.setCustomArguments(nil, for: selectedTerminal.bundleIdentifier)
                                                // Settings automatically saved via Defaults
                                            }
                                            .buttonStyle(.bordered)
                                            .disabled(terminalSettings.customArguments(for: selectedTerminal.bundleIdentifier) == nil)
                                            
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        } else {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Selected terminal is not installed")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                .id(refreshTrigger)
                

                // Refresh Button
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Terminal Detection")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Button("Refresh") {
                            refreshTrigger.toggle()
                            // Settings automatically loaded via Defaults
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Text("Terminal applications are automatically detected from your Applications folder. Click 'Refresh' to scan for newly installed terminals.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(16)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                }
            }
            .padding(24)
        }
        .frame(minWidth: 600, maxWidth: 600, minHeight: 400)
        .errorSheet($error)
    }
}

#Preview {
    TerminalSettingsView()
}