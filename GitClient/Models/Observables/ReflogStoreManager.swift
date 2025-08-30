//
//  ReflogStoreManager.swift
//  GitClient
//
//  Created by Claude on 2025/08/28.
//

import Foundation
import SwiftUI
import Defaults

@MainActor
class ReflogStoreManager: ObservableObject {
    static let shared = ReflogStoreManager()
    
    private var stores: [String: ReflogStore] = [:]
    
    private init() {}
    
    func store(for directory: URL) -> ReflogStore {
        let key = directory.absoluteString
        
        if let existingStore = stores[key] {
            // Update limit from settings
            existingStore.limit = Defaults[.reflogLimit]
            return existingStore
        }
        
        let newStore = ReflogStore()
        newStore.directory = directory
        newStore.limit = Defaults[.reflogLimit]
        stores[key] = newStore
        
        return newStore
    }
    
    func removeStore(for directory: URL) {
        let key = directory.absoluteString
        stores.removeValue(forKey: key)
    }
    
    func clearAll() {
        stores.removeAll()
    }
}