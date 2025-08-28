//
//  AdvancedSettingsView.swift
//  GitClient
//
//  Created by Claude on 2025/08/28.
//

import SwiftUI

struct AdvancedSettingsView: View {
    @AppStorage(AppStorageKey.allowExpertOptions.rawValue) private var allowExpertOptions = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Advanced Settings")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Configure advanced options and potentially destructive operations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Expert Options Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Expert Options")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 12) {
                            Toggle("Allow expert options", isOn: $allowExpertOptions)
                                .toggleStyle(.checkbox)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Enable advanced Git operations")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("This enables access to potentially destructive operations:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("• Reflog navigation and recovery")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("• Reset operations (soft, mixed, hard)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("• Discard all changes")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("• Clean untracked files")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.leading, 8)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                
                // Warning Section
                if allowExpertOptions {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("⚠️ Warning")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                        
                        VStack(spacing: 12) {
                            InfoRow(
                                icon: "exclamationmark.triangle",
                                iconColor: .red,
                                text: "These operations can permanently delete data and potentially corrupt your repository."
                            )
                            
                            InfoRow(
                                icon: "shield.checkered",
                                iconColor: .orange,
                                text: "Always ensure you have backups or are working on a non-critical branch."
                            )
                            
                            InfoRow(
                                icon: "info.circle",
                                iconColor: .blue,
                                text: "Use with caution and only if you understand the implications of each operation."
                            )
                        }
                        .padding(16)
                        .background(Color.red.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(8)
                    }
                }
            }
            .padding(24)
        }
        .frame(minWidth: 600, maxWidth: 600, minHeight: 400)
    }
}

#Preview {
    AdvancedSettingsView()
}