//
//  SwiftDataTaedamRepository.swift
//  Siboya
//

import Foundation
import SwiftData

/// ModelContext는 스레드 바운드라 mainContext는 항상 메인 액터에서만 호출해야 한다.
final class SwiftDataTaedamRepository: TaedamRepository, @unchecked Sendable {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchBabyProfile() throws -> BabyProfile? {
        var descriptor = FetchDescriptor<BabyProfile>()
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func save(command: SaveBucketListCommandDTO) async throws -> SavedBucketListDTO {
        let category = command.category.trimmingCharacters(in: .whitespacesAndNewlines)
        let content = command.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !category.isEmpty else { throw TaedamRepositoryError.emptyCategory }
        guard !content.isEmpty else { throw TaedamRepositoryError.emptyContent }

        let item = BucketListItem(category: category, content: content)
        modelContext.insert(item)
        try modelContext.save()
        return SavedBucketListDTO(bucketListItemID: item.id)
    }

    func updateContent(command: UpdateBucketListContentCommandDTO) async throws {
        let content = command.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { throw TaedamRepositoryError.emptyContent }

        guard let item = try fetchItem(id: command.bucketListItemID) else {
            throw TaedamRepositoryError.bucketListItemNotFound
        }
        item.content = content
        try modelContext.save()
    }

    func toggleCompletion(bucketListItemID: UUID) async throws {
        guard let item = try fetchItem(id: bucketListItemID) else {
            throw TaedamRepositoryError.bucketListItemNotFound
        }
        item.isCompleted.toggle()
        try modelContext.save()
    }

    func delete(bucketListItemID: UUID) async throws {
        guard let item = try fetchItem(id: bucketListItemID) else {
            throw TaedamRepositoryError.bucketListItemNotFound
        }
        modelContext.delete(item)
        try modelContext.save()
    }

    private func fetchItem(id: UUID) throws -> BucketListItem? {
        let descriptor = FetchDescriptor<BucketListItem>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
}
