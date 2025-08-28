//
//  ReflogStoreManager.swift
//  GitClient
//
//  Created by Claude on 2025/08/28.
//

import Foundation
import SwiftUI

@MainActor
class ReflogStoreManager: ObservableObject {
    static let shared = ReflogStoreManager()
    
    private var stores: [String: ReflogStore] = [:]
    
    private init() {}
    
    func store(for directory: URL) -> ReflogStore {
        let key = directory.absoluteString
        
        if let existingStore = stores[key] {
            // Update limit from settings
            existingStore.limit = UserDefaults.standard.object(forKey: AppStorageKey.reflogLimit.rawValue) as? Int ?? 100
            return existingStore
        }
        
        let newStore = ReflogStore()
        newStore.directory = directory
        newStore.limit = UserDefaults.standard.object(forKey: AppStorageKey.reflogLimit.rawValue) as? Int ?? 100
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