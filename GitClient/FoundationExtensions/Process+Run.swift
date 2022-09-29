//
//  Process+Run.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import Foundation

struct ProcessError: Error, LocalizedError {
    static var unknown = ProcessError(description: "Unknown error.")

    private var description: String
    var errorDescription: String? {
        return description
    }

    init(description: String) {
        self.description = description
    }

    init(error: Error) {
        self.init(description: error.localizedDescription)
    }
}


extension Process {
    static func stdout(executableURL: URL, arguments: [String], currentDirectoryURL: URL?) async throws -> String {
        try run(executableURL: executableURL, arguments: arguments, currentDirectoryURL: currentDirectoryURL)
    }
    static func run(executableURL: URL, arguments: [String], currentDirectoryURL: URL?) throws -> String {
        let process = Process()
        let stdOutput = Pipe()
        let stdError = Pipe()
        process.executableURL = executableURL
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectoryURL
        process.standardOutput = stdOutput
        process.standardError = stdError
        try process.run()
        if let stdOut = String(data: stdOutput.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8), !stdOut.isEmpty {
            return stdOut
        }
        guard let errOut = String(data: stdError.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) else {
            throw ProcessError.unknown
        }
        guard errOut.isEmpty else {
            throw ProcessError(description: errOut)
        }
        return ""
    }

    static func run<G: Git>(_ git: G) throws -> G.OutputModel {
        let stdOut = try Self.run(executableURL: .git, arguments: git.arguments, currentDirectoryURL: git.directory)
        return git.parse(for: stdOut)
    }

    static func stdout<G: Git>(_ git: G) async throws -> G.OutputModel {
        let stdOut = try await Self.stdout(executableURL: .git, arguments: git.arguments, currentDirectoryURL: git.directory)
        return git.parse(for: stdOut)
    }
}
