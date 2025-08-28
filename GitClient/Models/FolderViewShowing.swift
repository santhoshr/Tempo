//
//  FolderViewShowing.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/23.
//

import Foundation

struct FolderViewShowing {
    var branches = false
    var createNewBranchFrom: Branch?
    var renameBranch: Branch?
    var stashChanged = false
    var stashMenu = false
    var tags = false
    var reflog = false
    var createNewTagAt: Commit?
    var amendCommitAt: Commit?
    var confirmSoftReset: Commit?
    var confirmMixedReset: Commit?
    var confirmHardReset: Commit?
    var confirmDiscardAll = false
    var confirmCleanFiles = false
    var confirmCleanFilesAndDirs = false
    var confirmCleanIgnored = false
}

