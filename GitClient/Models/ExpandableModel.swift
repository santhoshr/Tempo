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
