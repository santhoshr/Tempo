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
        fileDiffs = try raw.split(separator: "diff").map { fileDiffRaw in
            guard let fileDiff = FileDiff(raw: String(fileDiffRaw)) else { throw GenericError(errorDescription: "Parse error")}
            return fileDiff
        }
    }
}

struct FileDiff {
    var header: String
    var extendedHeaderLines: [String]
    var fromFileToFileLines: [String]
    var chunks: [Chunk]
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

    init?(raw: String) {
        self.raw = raw
        let splited = raw.split(separator: "\n").map { String($0) }
        let firstLine = splited.first
        guard let firstLine else { return nil }
        header = firstLine
        let fromFileIndex = splited.firstIndex { $0.hasPrefix("---") }
        guard let fromFileIndex else { return nil }
        extendedHeaderLines = splited[1...fromFileIndex].map { String($0) }
        let toFileIndex = splited.lastIndex { $0.hasPrefix("+++") }
        guard let toFileIndex else { return nil }
        fromFileToFileLines = splited[fromFileIndex...toFileIndex].map { String($0) }
        chunks = Self.extractChunks(from: splited).map { Chunk(raw: $0) }
    }
}

struct Chunk {
    struct Line {
        enum Kind {
            case removed, added, unchanged
        }
        
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

        init(raw: String) {
            self.raw = raw
        }
    }

    var lines: [Line]
    var raw: String

    init(raw: String) {
        self.raw = raw
        self.lines = raw.split(separator: "\n").map { Line(raw: String($0)) }
    }
}
