//
//  View+.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import SwiftUI

extension View {
    func errorAlert(_ error: Binding<Error?>) -> some View {
        alert(
            error.wrappedValue?.localizedDescription ?? "",
            isPresented: .constant(error.wrappedValue != nil)) {
            Button("OK", role: .cancel) {
                error.wrappedValue = nil
            }
        }
    }
}
