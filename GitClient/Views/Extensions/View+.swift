//
//  View+.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import SwiftUI

extension View {
    func errorSheet(_ error: Binding<Error?>) -> some View {
        sheet(isPresented: .constant(error.wrappedValue != nil)) {
            ErrorTextSheet(error: error)
        }
    }
}
