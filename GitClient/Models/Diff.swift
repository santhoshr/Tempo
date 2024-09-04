//
//  CombinedDiff.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/04/07.
//

import Foundation

struct Diff {
    var fileDiffs: [FileDiff]
    var raw: String

    init(raw: String) throws {
        self.raw = raw
        guard !raw.isEmpty else {
            fileDiffs = []
            return
        }
        fileDiffs = try ("\n" + raw).split(separator: "\ndiff").map { fileDiffRaw in
            let fileDiff = try FileDiff(raw: String("diff" + fileDiffRaw))
            return fileDiff
        }
    }

    func updateAll(stage: Bool) -> Self {
        let newFileDiffs = fileDiffs.map { fileDiff in
            fileDiff.updateAll(stage: stage)
        }
        var new = self
        new.fileDiffs = newFileDiffs
        return new
    }

    func updateFileDiffStage(_ fileDiff: FileDiff, stage: Bool) -> Self {
        let fileDiffIndex = fileDiffs.firstIndex { $0.id == fileDiff.id }
        guard let fileDiffIndex  else { return self }
        var new = self
        new.fileDiffs[fileDiffIndex].stage = stage
        return new
    }

    func updateChunkStage(_ chunk: Chunk, in fileDiff: FileDiff, stage: Bool) -> Self {
        let fileDiffIndex = fileDiffs.firstIndex { $0.id == fileDiff.id }
        guard let fileDiffIndex  else { return self }
        let chunkIndex = fileDiffs[fileDiffIndex].chunks.firstIndex { $0.id == chunk.id }
        guard let chunkIndex else { return self }
        var new = self
        var newChunk = chunk
        newChunk.stage = stage
        new.fileDiffs[fileDiffIndex].chunks[chunkIndex] = newChunk
        return new
    }

    func stageStrings() -> [String] {
        Array(fileDiffs.map { $0.stageStrings() }.joined())
    }
}

struct FileDiff: Identifiable {
    var id: String { raw }
    var header: String
    var extendedHeaderLines: [String]
    var fromFileToFileLines: [String]
    var chunks: [Chunk]
    var stage: Bool?
    var stageString: String {
        if let stage, stage {
            return "y"
        }
        return "n"
    }
    var raw: String

    private static func extractChunks(from lines: [String]) -> [String] {
        var chunks: [String] = []
        var currentChunk: String?

        for line in lines {
            if line.starts(with: "@@") {
                if let hunk = currentChunk {
                    chunks.append(hunk)
                }
                currentChunk = line
            } else {
                currentChunk?.append("\n" + line)
            }
        }

        if let lastHunk = currentChunk {
            chunks.append(lastHunk)
        }

        return chunks
    }

    init(raw: String) throws {
        self.raw = raw
        let splited = raw.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        let firstLine = splited.first
        guard let firstLine else {
            throw GenericError(errorDescription: "Parse error for first line in FileDiff")
        }
        header = firstLine
        let fromFileIndex = splited.firstIndex { $0.hasPrefix("--- ") }
        guard let fromFileIndex else {
            extendedHeaderLines = splited[1..<splited.endIndex].map { String($0) }
            fromFileToFileLines = []
            chunks = []
            return
        }
        extendedHeaderLines = splited[1..<fromFileIndex].map { String($0) }
        let toFileIndex = splited.lastIndex { $0.hasPrefix("+++ ") }
        guard let toFileIndex else {
            throw GenericError(errorDescription: "Parse error for toFileIndex in FileDiff")
        }
        fromFileToFileLines = splited[fromFileIndex...toFileIndex].map { String($0) }
        chunks = Self.extractChunks(from: splited).map { Chunk(raw: $0) }
    }

    func updateAll(stage: Bool) -> Self {
        guard !chunks.isEmpty else {
            var newSelf = self
            newSelf.stage = stage
            return newSelf
        }
        let newChunks = chunks.map { chunk in
            var newChunk = chunk
            newChunk.stage = stage
            return newChunk
        }
        var new = self
        new.chunks = newChunks
        return new
    }

    func stageStrings() -> [String] {
        guard !chunks.isEmpty else {
            return [stageString]
        }
        return chunks.map { $0.stageString }
    }
}

struct Chunk: Identifiable {
    struct Line: Identifiable {
        enum Kind {
            case removed, added, unchanged
        }
        var id: Int
        var kind: Kind {
            switch raw.first {
            case "-":
                return .removed
            case "+":
                return .added
            case " ":
                return .unchanged
            default:
                return .unchanged
            }
        }
        var raw: String

        init(id: Int, raw: String) {
            self.id = id
            self.raw = raw
        }
    }
    var id: String { raw }
    var lines: [Line]
    var raw: String
    var stage: Bool?
    var stageString: String {
        if let stage, stage {
            return "y"
        }
        return "n"
    }

    init(raw: String) {
        self.raw = raw
        self.lines = raw.split(separator: "\n").enumerated().map { Line(id: $0.offset, raw: String($0.element)) }
    }
}
