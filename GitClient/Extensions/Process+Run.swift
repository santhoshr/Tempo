//
//  Process+Run.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import Foundation

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
    struct Output {
        var standardOutput: String
        var standartError: String
    }

    static func output(arguments: [String], currentDirectoryURL: URL?, inputs: [String]=[]) async throws -> Output {
        try run(arguments: arguments, currentDirectoryURL: currentDirectoryURL, inputs: inputs)
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
        print(currentDirectoryURL)
        print(process.environment)
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

    static func output<G: InteractiveGit>(_ git: G, verbose: Bool=false) async throws -> G.OutputModel {
        if verbose {
            print(git)
        }
        let output = try await Self.output(arguments: git.arguments, currentDirectoryURL: git.directory, inputs: git.inputs)
        if verbose {
            print(output)
        }
        return try git.parse(for: output.standardOutput)
    }

}
