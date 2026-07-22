//
//  SwiftDataTaedamRepository.swift
//  Siboya
//

import Foundation
import SwiftData

/// SwiftData `ModelContext`를 이용해 태담 프로필과 버킷리스트를 영속화하는 저장소 구현체입니다.
/// `ModelContext`는 스레드 바운드이므로 이 저장소의 호출자는 생성한 컨텍스트와 같은 실행 맥락에서 사용해야 합니다.
final class SwiftDataTaedamRepository: TaedamRepository, @unchecked Sendable {
    /// 프로필과 버킷리스트 모델을 조회·삽입·저장하는 SwiftData 컨텍스트입니다.
    private let modelContext: ModelContext

    /// 외부에서 준비한 컨텍스트를 받아 저장소가 같은 영속성 저장소를 사용하도록 초기화합니다.
    /// - Parameter modelContext: 모델 CRUD 작업을 수행할 SwiftData 컨텍스트입니다.
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// 프로필 조회 범위를 한 건으로 제한해 저장된 아기 프로필 또는 `nil`을 반환합니다.
    func fetchBabyProfile() throws -> BabyProfile? {
        var descriptor = FetchDescriptor<BabyProfile>()
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    /// 기존 프로필을 유지하고, 없는 경우에만 공백을 제거한 입력으로 새 프로필을 저장합니다.
    func ensureBabyProfile(nickname: String, gestationalWeek: Int) async throws {
        guard try fetchBabyProfile() == nil else { return }

        // 저장 전 공백만 있는 태명을 차단해 화면에 의미 없는 프로필이 나타나는 것을 방지합니다.
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNickname.isEmpty else { throw TaedamRepositoryError.emptyNickname }

        let profile = BabyProfile(nickname: trimmedNickname, gestationalWeek: gestationalWeek)
        modelContext.insert(profile)
        try modelContext.save()
    }

    /// 공백을 정리한 새 태명으로 기존 프로필을 수정하고 변경 내용을 저장합니다.
    func updateNickname(_ nickname: String) async throws {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNickname.isEmpty else { throw TaedamRepositoryError.emptyNickname }

        // 프로필이 없는 상태에서 수정하면 사용자가 원인을 알 수 있도록 조회 실패 오류를 반환합니다.
        guard let profile = try fetchBabyProfile() else {
            throw TaedamRepositoryError.babyProfileNotFound
        }
        profile.updateNickname(trimmedNickname)
        try modelContext.save()
    }

    /// 유효한 분류와 내용을 가진 버킷리스트 항목을 저장하고 생성된 식별자를 반환합니다.
    func save(command: SaveBucketListCommandDTO) async throws -> SavedBucketListDTO {
        let category = command.category.trimmingCharacters(in: .whitespacesAndNewlines)
        let content = command.content.trimmingCharacters(in: .whitespacesAndNewlines)
        // 공백 입력을 저장하면 이후 목록과 대본 화면에서 구분할 수 없으므로 각각 검증합니다.
        guard !category.isEmpty else { throw TaedamRepositoryError.emptyCategory }
        guard !content.isEmpty else { throw TaedamRepositoryError.emptyContent }

        let item = BucketListItem(category: category, content: content)
        modelContext.insert(item)
        try modelContext.save()
        return SavedBucketListDTO(bucketListItemID: item.id)
    }

    /// 지정된 항목이 존재할 때만 공백을 정리한 새 내용으로 변경합니다.
    func updateContent(command: UpdateBucketListContentCommandDTO) async throws {
        let content = command.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { throw TaedamRepositoryError.emptyContent }

        // 삭제된 항목을 조용히 무시하지 않고 호출자가 목록을 갱신할 수 있도록 오류를 반환합니다.
        guard let item = try fetchItem(id: command.bucketListItemID) else {
            throw TaedamRepositoryError.bucketListItemNotFound
        }
        item.updateContent(content)
        try modelContext.save()
    }

    /// 지정된 버킷리스트 항목의 완료 여부를 바꾸고 영속 저장합니다.
    func toggleCompletion(bucketListItemID: UUID) async throws {
        guard let item = try fetchItem(id: bucketListItemID) else {
            throw TaedamRepositoryError.bucketListItemNotFound
        }
        item.toggleCompletion()
        try modelContext.save()
    }

    /// 지정된 버킷리스트 항목을 조회한 뒤 삭제하고 변경 내용을 저장합니다.
    func delete(bucketListItemID: UUID) async throws {
        guard let item = try fetchItem(id: bucketListItemID) else {
            throw TaedamRepositoryError.bucketListItemNotFound
        }
        modelContext.delete(item)
        try modelContext.save()
    }

    /// 식별자가 일치하는 버킷리스트 항목 한 건을 찾아 수정·삭제 작업에 제공합니다.
    /// - Parameter id: 조회할 버킷리스트 항목의 고유 식별자입니다.
    private func fetchItem(id: UUID) throws -> BucketListItem? {
        let descriptor = FetchDescriptor<BucketListItem>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
}
