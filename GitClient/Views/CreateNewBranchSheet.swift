//
//  CreateNewBranchSheet.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/08.
//

import SwiftUI

struct CreateNewBranchSheet: View {
    var folder: Folder
    var from: Branch
    @Binding var isShowing: Branch?
    var onCreate: (() -> Void)
    @State private var newBranchName = ""
    @State private var error: Error?

    var body: some View {
        VStack {
            Text("Create new branch")
                .font(.headline)
            VStack(alignment: .leading) {
                HStack {
                    Text("from:  \(isShowing?.name ?? "")")
                }
                HStack {
                    Text("    to:")
                    TextField("New Branch name", text: $newBranchName)
                }
                HStack {
                    Spacer()
                    Button("Cancel") {
                        isShowing = nil
                    }
                    Button("Create") {
                        Task {
                            do {
                                print(try await Process.stdout(
                                    GitSwitch(directory: folder.url, branchName: isShowing!.name)
                                ))
                                print(try await Process.stdout(
                                    GitCheckoutB(directory: folder.url, newBranchName: newBranchName)))
                                isShowing = nil
                                onCreate()
                            } catch {
                                self.error = error // error occurs even if the created.
                                isShowing = nil
                                onCreate()
                            }
                        }
                    }
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
            from: .init(name: "main", isCurrent: true),
            isShowing: $isShowing)
            {

        }
    }
}
