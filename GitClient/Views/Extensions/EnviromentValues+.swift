//
//  EnviromentValues+.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/29.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var openAIAPISecretKey: String = ""
    @Entry var openAIAPIURL: String = ""
    @Entry var openAIAPIPrompt: String = ""
    @Entry var openAIAPIModel: String = ""
    @Entry var openAIAPIStagingPrompt: String = ""
    @Entry var folder: URL?
    @Entry var expandAllFiles: UUID?
    @Entry var collapseAllFiles: UUID?
}
