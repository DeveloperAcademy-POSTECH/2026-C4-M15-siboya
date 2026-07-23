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

    func ensureBabyProfile(nickname: String, gestationalWeek: Int) async throws {
        guard try fetchBabyProfile() == nil else { return }

        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNickname.isEmpty else { throw TaedamRepositoryError.emptyNickname }

        let profile = BabyProfile(nickname: trimmedNickname, gestationalWeek: gestationalWeek)
        modelContext.insert(profile)
        try modelContext.save()
    }

    func updateNickname(_ nickname: String) async throws {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNickname.isEmpty else { throw TaedamRepositoryError.emptyNickname }

        guard let profile = try fetchBabyProfile() else {
            throw TaedamRepositoryError.babyProfileNotFound
        }
        profile.updateNickname(trimmedNickname)
        try modelContext.save()
    }
    
    func updateGestationalWeek(_ gestationalWeek: Int) async throws {
            guard let profile = try fetchBabyProfile() else {
                throw TaedamRepositoryError.babyProfileNotFound
            }
            profile.updateGestationalWeek(gestationalWeek)
            try modelContext.save()
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
        item.updateContent(content)
        try modelContext.save()
    }

    func toggleCompletion(bucketListItemID: UUID) async throws {
        guard let item = try fetchItem(id: bucketListItemID) else {
            throw TaedamRepositoryError.bucketListItemNotFound
        }
        item.toggleCompletion()
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
