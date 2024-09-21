//
//  CreateNewTagSheet.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/21.
//

import SwiftUI

struct CreateNewTagSheet: View {
    var folder: Folder
    @Binding var showingCreateNewTagAt: Commit?
    var onCreate: (() -> Void)
    @State private var newTagname = ""
    @State private var error: Error?

    var body: some View {
        VStack {
            Text("Create new tag")
                .font(.headline)
            VStack(alignment: .leading) {
                HStack {
                    Text("commit: \(showingCreateNewTagAt?.hash ?? "")")
                        .textSelection(.enabled)
                }
                HStack {
                    Text("tagname:")
                    TextField("New Tagname", text: $newTagname)
                }
                HStack {
                    Spacer()
                    Button("Cancel") {
                        showingCreateNewTagAt = nil
                    }
                    Button("Create") {
                        Task {
                            do {
                                try await Process.output(
                                    GitTagCreate(
                                        directory: folder.url,
                                        tagname: newTagname,
                                        object: showingCreateNewTagAt!.hash
                                    )
                                )
                                onCreate()
                                showingCreateNewTagAt = nil
                            } catch {
                                self.error = error
                            }
                        }
                    }
                    .disabled(newTagname.isEmpty)
                    Button("Create & Push") {
                        Task {
                            do {
                                try await Process.output(
                                    GitTagCreate(
                                        directory: folder.url,
                                        tagname: newTagname,
                                        object: showingCreateNewTagAt!.hash
                                    )
                                )
                                try await Process.output(
                                    GitPush(directory: folder.url, refspec: newTagname)
                                )
                                onCreate()
                                showingCreateNewTagAt = nil
                            } catch {
                                self.error = error
                            }
                        }
                    }
                    .keyboardShortcut(.init(.return))
                    .disabled(newTagname.isEmpty)
                }
                .padding(.top)
            }
            .frame(width: 400)
            .padding()
        }
        .padding()
        .cornerRadius(8)
        .errorAlert($error)
    }
}
