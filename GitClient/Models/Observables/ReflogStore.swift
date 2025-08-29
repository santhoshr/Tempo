//
//  ReflogStore.swift
//  GitClient
//
//  Created by Claude on 2025/08/28.
//

import Foundation
import Observation

@MainActor
@Observable class ReflogStore {
    var directory: URL?
    var entries: [ReflogEntry] = []
    var hasMoreEntries: Bool = true
    var branchInfoLoaded: Set<String> = []
    var error: Error?
    var limit: Int = 100
    
    func refresh() async {
        guard let directory else {
            entries = []
            branchInfoLoaded = []
            hasMoreEntries = true
            return
        }
        
        do {
            if entries.isEmpty {
                // Initial load - use loadInitial to maintain consistency
                await loadInitial()
                return
            }
            
            // Progressive batch refresh: compare batch by batch until we find a match
            let totalLoaded = entries.count
            let totalBatches = (totalLoaded + limit - 1) / limit // Ceiling division
            var refreshedEntries: [ReflogEntry] = []
            var batchesProcessed = 0
            
            for batchIndex in 0..<totalBatches {
                let skip = batchIndex * limit
                let currentBatch = Array(entries.dropFirst(skip).prefix(limit))
                
                if currentBatch.isEmpty { break }
                
                // Fetch the corresponding batch from git
                let latestBatch = try await Process.output(GitReflog(directory: directory, limit: limit, skip: skip))
                
                // Compare this batch with our cached batch
                let batchMatches = latestBatch.count == currentBatch.count &&
                                 zip(latestBatch, currentBatch).allSatisfy { $0.hash == $1.hash }
                
                if batchMatches {
                    // This batch matches, we can stop here
                    break
                } else {
                    // This batch is different, add it to refreshed entries and continue
                    refreshedEntries.append(contentsOf: latestBatch)
                    batchesProcessed += 1
                    
                    // Clear branch info for entries we're replacing
                    for entry in currentBatch {
                        branchInfoLoaded.remove(entry.hash)
                    }
                }
            }
            
            if !refreshedEntries.isEmpty {
                // Keep entries that weren't refreshed
                let unchangedEntries = Array(entries.dropFirst(batchesProcessed * limit))
                entries = refreshedEntries + unchangedEntries
                
                // Load branch info for the refreshed entries only
                await loadBranchesForNewEntries(startIndex: 0, count: refreshedEntries.count)
            }
        } catch {
            self.error = error
        }
    }
    
    func loadInitial() async {
        guard let directory else {
            entries = []
            branchInfoLoaded = []
            hasMoreEntries = true
            return
        }
        
        do {
            let newEntries = try await Process.output(GitReflog(directory: directory, limit: limit))
            entries = newEntries
            hasMoreEntries = newEntries.count == limit
            
            // Load branch information for initial entries
            await loadBranchesForNewEntries(startIndex: 0)
        } catch {
            self.error = error
        }
    }
    
    func loadMore() async {
        guard let directory, hasMoreEntries else { return }
        
        do {
            let currentCount = entries.count
            let newEntries = try await Process.output(GitReflog(directory: directory, limit: limit, skip: currentCount))
            
            if newEntries.isEmpty {
                hasMoreEntries = false
            } else {
                entries.append(contentsOf: newEntries)
                hasMoreEntries = newEntries.count == limit
                
                // Load branch info only for the new entries
                await loadBranchesForNewEntries(startIndex: currentCount)
            }
        } catch {
            self.error = error
        }
    }
    
    func loadAll() async {
        guard let directory else {
            entries = []
            branchInfoLoaded = []
            hasMoreEntries = true
            return
        }
        
        do {
            // Load all reflog entries (no limit)
            let allEntries = try await Process.output(GitReflog(directory: directory, limit: 0))
            entries = allEntries
            hasMoreEntries = false // No more entries to load
            
            // Clear existing branch info since we're reloading everything
            branchInfoLoaded.removeAll()
            for i in entries.indices {
                entries[i].branchNames = []
            }
            
            // Load branch information for all entries using proper badge logic
            await loadBranchesForAllEntries()
        } catch {
            self.error = error
        }
    }
    
    func removeAll() {
        entries = []
        branchInfoLoaded = []
        hasMoreEntries = true
    }
    
    private func loadBranchesForAllEntries() async {
        guard let directory else { return }
        
        var globalSeenBranches: Set<String> = []
        
        // Process all entries to ensure proper badge assignment
        for i in entries.indices {
            // Skip if we already loaded branch info for this hash
            if branchInfoLoaded.contains(entries[i].hash) {
                continue
            }
            
            do {
                let branches = try await Process.output(GitBranchPointsAt(directory: directory, object: entries[i].hash))
                let branchNames = branches.map { $0.name }
                
                // Only show badge for first occurrence of each branch
                let filteredBranches = branchNames.filter { branchName in
                    if globalSeenBranches.contains(branchName) {
                        return false
                    } else {
                        globalSeenBranches.insert(branchName)
                        return true
                    }
                }
                
                // Update entry with branch names
                entries[i].branchNames = filteredBranches
                branchInfoLoaded.insert(entries[i].hash)
                
                // Add a small delay to avoid overwhelming the system
                if i % 10 == 0 && i > 0 {
                    try await Task.sleep(nanoseconds: 10_000_000) // 10ms delay every 10 entries
                }
            } catch {
                // Continue processing other entries if one fails
                continue
            }
        }
    }
    
    private func loadBranchesForNewEntries(startIndex: Int, count: Int? = nil) async {
        // Load branch info only for up to 10 new entries for performance
        let maxEntries = count ?? 10
        let endIndex = min(startIndex + maxEntries, entries.count)
        
        for i in startIndex..<endIndex {
            // Skip if we already loaded branch info for this hash
            if branchInfoLoaded.contains(entries[i].hash) {
                continue
            }
            
            do {
                guard let directory else { continue }
                let branches = try await Process.output(GitBranchPointsAt(directory: directory, object: entries[i].hash))
                let branchNames = branches.map { $0.name }
                
                // Track global seen branches to avoid duplicates
                var globalSeenBranches: Set<String> = []
                for entry in entries[0..<i] {
                    globalSeenBranches.formUnion(entry.branchNames)
                }
                
                // Only show badge for first occurrence of each branch
                let filteredBranches = branchNames.filter { branchName in
                    !globalSeenBranches.contains(branchName)
                }
                
                // Update entry with branch names
                entries[i].branchNames = filteredBranches
                branchInfoLoaded.insert(entries[i].hash)
            } catch {
                // Continue processing other entries if one fails
                continue
            }
        }
    }
}