//
//  Folders.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/18.
//

import Foundation

struct Folder: Hashable, Codable {
    var url: URL
    var displayName: String {
        url.path.components(separatedBy: "/").filter{ !$0.isEmpty }.last ?? ""
    }
    
    /// Returns a display name that includes parent directory context when needed to disambiguate
    func displayName(amongFolders folders: [Folder]) -> String {
        let baseName = self.displayName
        
        // Check if there are other folders with the same base name
        let conflictingFolders = folders.filter { folder in
            folder.displayName == baseName && folder.url != self.url
        }
        
        // If no conflicts, return the simple name
        guard !conflictingFolders.isEmpty else {
            return baseName
        }
        
        // Find the minimum number of path components needed to make this unique
        let pathComponents = url.path.components(separatedBy: "/").filter { !$0.isEmpty }
        
        for componentCount in 2...min(pathComponents.count, 3) {
            let candidateName = pathComponents.suffix(componentCount).joined(separator: "/")
            
            // Check if this candidate name is unique among all conflicting folders
            let stillConflicting = conflictingFolders.contains { folder in
                let otherPathComponents = folder.url.path.components(separatedBy: "/").filter { !$0.isEmpty }
                let otherCandidateName = otherPathComponents.suffix(componentCount).joined(separator: "/")
                return otherCandidateName == candidateName
            }
            
            if !stillConflicting {
                return candidateName
            }
        }
        
        // If still conflicting after 3 components, show the full path
        return url.path
    }
    
    /// Returns the parent directory name for badge display
    func parentDirectoryForBadge(amongFolders folders: [Folder]) -> String? {
        let baseName = self.displayName
        
        // Check if there are other folders with the same base name
        let conflictingFolders = folders.filter { folder in
            folder.displayName == baseName && folder.url != self.url
        }
        
        // If no conflicts, no badge needed
        guard !conflictingFolders.isEmpty else {
            return nil
        }
        
        // Return the parent directory name
        let pathComponents = url.path.components(separatedBy: "/").filter { !$0.isEmpty }
        if pathComponents.count >= 2 {
            return pathComponents[pathComponents.count - 2]
        }
        
        return nil
    }
}
