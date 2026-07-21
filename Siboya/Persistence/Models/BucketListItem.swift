//
//  BucketListItem.swift
//  Siboya
//

import Foundation
import SwiftData

@Model
final class BucketListItem {
    @Attribute(.unique) var id: UUID
    private(set) var category: String
    private(set) var content: String
    private(set) var isCompleted: Bool
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

    func updateContent(_ newContent: String) {
        content = newContent
    }

    func toggleCompletion() {
        isCompleted.toggle()
    }
}
