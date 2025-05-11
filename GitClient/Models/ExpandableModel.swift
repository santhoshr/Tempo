//
//  ExpandedModel.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/03/18.
//
import Foundation

struct ExpandableModel<Model: Hashable>: Hashable {
    var isExpanded: Bool
    var model: Model
}

extension Array where Element: Hashable {
    func withExpansionState(from old: [ExpandableModel<Element>]) -> [ExpandableModel<Element>] {
        self.map { model in
            if let oldModel = old.first(where: { $0.model == model }) {
                return ExpandableModel(isExpanded: oldModel.isExpanded, model: model)
            } else {
                return ExpandableModel(isExpanded: true, model: model)
            }
        }
    }
}
