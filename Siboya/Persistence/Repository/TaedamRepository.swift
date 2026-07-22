//
//  TaedamRepository.swift
//  Siboya
//

import Foundation

enum TaedamRepositoryError: Error, Equatable {
    case emptyCategory
    case emptyContent
    case bucketListItemNotFound
}

protocol TaedamRepository: Sendable {
    func fetchBabyProfile() throws -> BabyProfile?
    func save(command: SaveBucketListCommandDTO) async throws -> SavedBucketListDTO
    func updateContent(command: UpdateBucketListContentCommandDTO) async throws
    func toggleCompletion(bucketListItemID: UUID) async throws
    func delete(bucketListItemID: UUID) async throws
}
