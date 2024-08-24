//
//  CreateNewBranchSheet.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/08.
//

import SwiftUI

struct CreateNewBranchSheet: View {
    var folder: Folder
    @Binding var showingCreateNewBranchFrom: Branch?
    var onCreate: (() -> Void)
    @State private var newBranchName = ""
    @State private var error: Error?

    var body: some View {
        VStack {
            Text("Create new branch")
                .font(.headline)
            VStack(alignment: .leading) {
                HStack {
                    Text("from:  \(showingCreateNewBranchFrom?.name ?? "")")
                        .textSelection(.enabled)
                }
                HStack {
                    Text("    to:")
                    TextField("New Branch name", text: $newBranchName)
                }
                HStack {
                    Spacer()
                    Button("Cancel") {
                        showingCreateNewBranchFrom = nil
                    }
                    Button("Create") {
                        Task {
                            do {
                                try await Process.output(
                                    GitCheckoutB(directory: folder.url, newBranchName: newBranchName, startPoint: showingCreateNewBranchFrom!.name)
                                )
                                showingCreateNewBranchFrom = nil
                                onCreate()
                            } catch {
                                self.error = error
                            }
                        }
                    }
                    .keyboardShortcut(.init(.return))
                    .disabled(newBranchName.isEmpty)
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

struct CreateNewBranchSheet_Previews: PreviewProvider {
    @State private static var isShowing: Branch? = Branch(name: "hoge", isCurrent: false)

    static var previews: some View {
        CreateNewBranchSheet(
            folder: .init(url: .init(string: "file:///projects/")!),
            showingCreateNewBranchFrom: $isShowing)
            {

        }
    }
}
