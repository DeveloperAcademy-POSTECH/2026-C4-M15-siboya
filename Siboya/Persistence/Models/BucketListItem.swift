//
//  BucketListItem.swift
//  Siboya
//

import Foundation
import SwiftData

@Model
final class BucketListItem {
    @Attribute(.unique) var id: UUID
    var category: String
    var content: String
    var isCompleted: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        category: String,
        content: String,
        isCompleted: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.category = category
        self.content = content
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}
