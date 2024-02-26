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
    struct Output {
        var standardOutput: String
        var standartError: String
    }

    static func output(arguments: [String], currentDirectoryURL: URL?) async throws -> Output {
        try run(arguments: arguments, currentDirectoryURL: currentDirectoryURL)
    }
    static func run(arguments: [String], currentDirectoryURL: URL?) throws -> Output {
        let process = Process()
        let stdOutput = Pipe()
        let stdError = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectoryURL
        process.standardOutput = stdOutput
        process.standardError = stdError
        try process.run()
        let stdOut = String(data: stdOutput.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        let errOut = String(data: stdError.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            if let errOut = errOut {
                throw ProcessError(description: errOut)
            }
            throw ProcessError.unknown
        }
        return .init(standardOutput: stdOut ?? "", standartError: errOut ?? "")
    }

    static func output<G: Git>(_ git: G, verbose: Bool=false) async throws -> G.OutputModel {
        if verbose {
            print(git)
        }
        let output = try await Self.output(arguments: git.arguments, currentDirectoryURL: git.directory)
        if verbose {
            print(output)
        }
        return try git.parse(for: output.standardOutput)
    }
}
