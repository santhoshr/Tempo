//
//  Process+Run.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import Foundation
import os

struct ProcessError: Error, LocalizedError {
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
    struct Output: CustomStringConvertible {
        var standardOutput: String
        var standartError: String
        var description: String {
            "Output(standardOutput: \(standardOutput), standardError: \(standartError))"
        }
    }

    static private func output(arguments: [String], currentDirectoryURL: URL?, inputs: [String]=[]) async throws -> Output {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "process")
        logger.debug("Process run: arguments: \(arguments), currentDirectoryURL: \(currentDirectoryURL?.description ?? ""), inputs: \(inputs)")
        do {
            let output = try run(arguments: arguments, currentDirectoryURL: currentDirectoryURL, inputs: inputs)
            logger.debug("Process output: \(output.standardOutput + output.standartError)")
            return output
        } catch {
            logger.error("Process error: \(error)")
            throw error
        }
    }

    private static func run(arguments: [String], currentDirectoryURL: URL?, inputs: [String]=[]) throws -> Output {
        let process = Process()
        let stdOutput = Pipe()
        let stdError = Pipe()
        let stdInput = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectoryURL
        process.standardOutput = stdOutput
        process.standardError = stdError
        process.standardInput = stdInput

        try process.run()

        if !inputs.isEmpty, let writeData = inputs.joined(separator: "\n").data(using: .utf8) {
            try stdInput.fileHandleForWriting.write(contentsOf: writeData)
            try stdInput.fileHandleForWriting.close()
        }

        let stdOut = String(data: stdOutput.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        let errOut = String(data: stdError.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)

        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let errorMessageWhen = "An error occurred while executing the \"" + arguments.joined(separator: " ") + "\"\n\n"
            throw ProcessError(
                description: errorMessageWhen + (stdOut ?? "") + "\n" + (errOut ?? "")
            )
        }
        return .init(standardOutput: stdOut ?? "", standartError: errOut ?? "")
    }

    static func output<G: Git>(_ git: G) async throws -> G.OutputModel {
        let output = try await Self.output(arguments: git.arguments, currentDirectoryURL: git.directory)
        return try git.parse(for: output.standardOutput)
    }

    static func output<G: InteractiveGit>(_ git: G) async throws -> G.OutputModel {
        let output = try await Self.output(arguments: git.arguments, currentDirectoryURL: git.directory, inputs: git.inputs)
        return try git.parse(for: output.standardOutput)
    }

}
