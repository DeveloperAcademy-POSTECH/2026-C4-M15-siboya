//
//  TaedamRepository.swift
//  Siboya
//

import Foundation

enum TaedamRepositoryError: Error, Equatable {
    case emptyNickname
    case emptyCategory
    case emptyContent
    case babyProfileNotFound
    case bucketListItemNotFound
}

protocol TaedamRepository: Sendable {
    func fetchBabyProfile() throws -> BabyProfile?
    func ensureBabyProfile(nickname: String, gestationalWeek: Int) async throws
    func updateNickname(_ nickname: String) async throws
    func updateGestationalWeek(_ gestationalWeek: Int) async throws
    func save(command: SaveBucketListCommandDTO) async throws -> SavedBucketListDTO
    func updateContent(command: UpdateBucketListContentCommandDTO) async throws
    func toggleCompletion(bucketListItemID: UUID) async throws
    func delete(bucketListItemID: UUID) async throws
}
