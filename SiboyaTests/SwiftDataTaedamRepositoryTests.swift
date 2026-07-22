//
//  SwiftDataTaedamRepositoryTests.swift
//  SiboyaTests
//

import Foundation
import Testing
import SwiftData
@testable import Siboya

/// 인메모리 SwiftData 컨테이너에서 태담 저장소의 조회·검증·변경 계약을 검증합니다.
struct SwiftDataTaedamRepositoryTests {
    /// 각 테스트가 서로 영향을 주지 않도록 비영구 컨테이너 기반의 새 모델 컨텍스트를 만듭니다.
    private func makeContext() -> ModelContext {
        ModelContext(PersistenceContainer.makeContainer(inMemory: true))
    }

    /// 저장 후 식별자로 항목을 다시 조회해 실제 영속화 결과를 확인합니다.
    /// - Parameters:
    ///   - id: 조회할 버킷리스트 항목 식별자입니다.
    ///   - context: 테스트가 생성한 인메모리 모델 컨텍스트입니다.
    private func fetchItem(id: UUID, in context: ModelContext) throws -> BucketListItem? {
        try context.fetch(
            FetchDescriptor<BucketListItem>(predicate: #Predicate { $0.id == id })
        ).first
    }

    // MARK: - fetchBabyProfile

    /// 프로필이 전혀 없을 때 조회 API가 빈 결과를 정확히 반환하는지 검증합니다.
    @Test
    func fetchBabyProfile_프로필이_없으면_nil을_반환한다() throws {
        let context = makeContext()
        let repository = SwiftDataTaedamRepository(modelContext: context)

        #expect(try repository.fetchBabyProfile() == nil)
    }

    /// 저장된 프로필이 있을 때 태명과 임신 주수를 그대로 반환하는지 검증합니다.
    @Test
    func fetchBabyProfile_있으면_그_프로필을_반환한다() throws {
        let context = makeContext()
        context.insert(BabyProfile(nickname: "콩콩이", gestationalWeek: 22))
        try context.save()
        let repository = SwiftDataTaedamRepository(modelContext: context)

        let profile = try repository.fetchBabyProfile()

        #expect(profile?.nickname == "콩콩이")
        #expect(profile?.gestationalWeek == 22)
    }

    // MARK: - ensureBabyProfile

    /// 기존 프로필이 없으면 전달한 태명과 임신 주수로 새 프로필을 만드는지 검증합니다.
    @Test
    func ensureBabyProfile_없으면_생성한다() async throws {
        let context = makeContext()
        let repository = SwiftDataTaedamRepository(modelContext: context)

        try await repository.ensureBabyProfile(nickname: "콩콩이", gestationalWeek: 22)

        let profile = try repository.fetchBabyProfile()
        #expect(profile?.nickname == "콩콩이")
        #expect(profile?.gestationalWeek == 22)
    }

    /// 이미 프로필이 있으면 이후 생성 요청이 기존 데이터를 덮어쓰지 않는지 검증합니다.
    @Test
    func ensureBabyProfile_이미_있으면_그대로_둔다() async throws {
        let context = makeContext()
        let repository = SwiftDataTaedamRepository(modelContext: context)
        try await repository.ensureBabyProfile(nickname: "콩콩이", gestationalWeek: 22)

        try await repository.ensureBabyProfile(nickname: "다른이름", gestationalWeek: 10)

        let profile = try repository.fetchBabyProfile()
        #expect(profile?.nickname == "콩콩이")
        #expect(profile?.gestationalWeek == 22)
    }

    /// 공백뿐인 태명으로는 의미 없는 프로필을 만들 수 없도록 입력 오류를 반환하는지 검증합니다.
    @Test
    func ensureBabyProfile_닉네임이_공백뿐이면_emptyNickname을_던진다() async throws {
        let context = makeContext()
        let repository = SwiftDataTaedamRepository(modelContext: context)

        await #expect(throws: TaedamRepositoryError.emptyNickname) {
            try await repository.ensureBabyProfile(nickname: "   ", gestationalWeek: 22)
        }
    }

    // MARK: - updateNickname

    /// 기존 프로필의 태명을 새 입력으로 변경한 뒤 저장하는지 검증합니다.
    @Test
    func updateNickname_태명을_변경한다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)
        try await repository.ensureBabyProfile(nickname: "콩콩이", gestationalWeek: 22)

        try await repository.updateNickname("꾹꾹이")

        #expect(try repository.fetchBabyProfile()?.nickname == "꾹꾹이")
    }

    /// 태명 변경 시 공백뿐인 값은 저장하지 않고 입력 오류를 반환하는지 검증합니다.
    @Test
    func updateNickname_공백뿐이면_emptyNickname을_던진다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)
        try await repository.ensureBabyProfile(nickname: "콩콩이", gestationalWeek: 22)

        await #expect(throws: TaedamRepositoryError.emptyNickname) {
            try await repository.updateNickname("   ")
        }
    }

    /// 수정할 프로필이 없을 때 조회 실패 오류를 반환하는지 검증합니다.
    @Test
    func updateNickname_프로필이_없으면_babyProfileNotFound를_던진다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)

        await #expect(throws: TaedamRepositoryError.babyProfileNotFound) {
            try await repository.updateNickname("꾹꾹이")
        }
    }

    // MARK: - save

    /// 유효한 분류와 내용을 저장하고 반환한 식별자로 같은 항목을 조회할 수 있는지 검증합니다.
    @Test
    func save_유효한_입력이면_저장하고_id를_반환한다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)

        let result = try await repository.save(
            command: SaveBucketListCommandDTO(category: "아기사랑", content: "안녕")
        )

        let saved = try await fetchItem(id: result.bucketListItemID, in: context)
        #expect(saved?.category == "아기사랑")
        #expect(saved?.content == "안녕")
        #expect(saved?.isCompleted == false)
    }

    /// 저장 시 사용자 입력 앞뒤 공백을 제거해 일관된 목록 값을 남기는지 검증합니다.
    @Test
    func save_앞뒤_공백을_trim해서_저장한다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)

        let result = try await repository.save(
            command: SaveBucketListCommandDTO(category: "  아기사랑  ", content: "  안녕  ")
        )

        let saved = try await fetchItem(id: result.bucketListItemID, in: context)
        #expect(saved?.category == "아기사랑")
        #expect(saved?.content == "안녕")
    }

    /// 공백뿐인 분류를 저장 요청하면 분류 입력 오류를 반환하는지 검증합니다.
    @Test
    func save_카테고리가_공백뿐이면_emptyCategory를_던진다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)

        await #expect(throws: TaedamRepositoryError.emptyCategory) {
            try await repository.save(
                command: SaveBucketListCommandDTO(category: "   ", content: "안녕")
            )
        }
    }

    /// 공백뿐인 내용을 저장 요청하면 내용 입력 오류를 반환하는지 검증합니다.
    @Test
    func save_content가_공백뿐이면_emptyContent를_던진다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)

        await #expect(throws: TaedamRepositoryError.emptyContent) {
            try await repository.save(
                command: SaveBucketListCommandDTO(category: "아기사랑", content: "   ")
            )
        }
    }

    // MARK: - updateContent

    /// 내용만 수정할 때 기존 분류는 유지되는지 검증합니다.
    @Test
    func updateContent_content를_바꾸고_category는_그대로다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)
        let saved = try await repository.save(
            command: SaveBucketListCommandDTO(category: "아기사랑", content: "원래 문장")
        )

        try await repository.updateContent(
            command: UpdateBucketListContentCommandDTO(
                bucketListItemID: saved.bucketListItemID,
                content: "수정한 문장"
            )
        )

        let updated = try await fetchItem(id: saved.bucketListItemID, in: context)
        #expect(updated?.content == "수정한 문장")
        #expect(updated?.category == "아기사랑")
    }

    /// 내용 수정 시 공백뿐인 값은 저장하지 않고 내용 입력 오류를 반환하는지 검증합니다.
    @Test
    func updateContent_content가_공백뿐이면_emptyContent를_던진다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)
        let saved = try await repository.save(
            command: SaveBucketListCommandDTO(category: "아기사랑", content: "원래 문장")
        )

        await #expect(throws: TaedamRepositoryError.emptyContent) {
            try await repository.updateContent(
                command: UpdateBucketListContentCommandDTO(
                    bucketListItemID: saved.bucketListItemID,
                    content: "   "
                )
            )
        }
    }

    /// 삭제되었거나 없는 항목을 수정하면 항목 조회 실패 오류를 반환하는지 검증합니다.
    @Test
    func updateContent_존재하지_않는_id면_bucketListItemNotFound를_던진다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)

        await #expect(throws: TaedamRepositoryError.bucketListItemNotFound) {
            try await repository.updateContent(
                command: UpdateBucketListContentCommandDTO(
                    bucketListItemID: UUID(),
                    content: "아무 문장"
                )
            )
        }
    }

    // MARK: - toggleCompletion

    /// 완료 상태 변경을 반복하면 참과 거짓이 차례로 반전되는지 검증합니다.
    @Test
    func toggleCompletion_호출할_때마다_isCompleted를_뒤집는다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)
        let saved = try await repository.save(
            command: SaveBucketListCommandDTO(category: "아기사랑", content: "안녕")
        )

        try await repository.toggleCompletion(bucketListItemID: saved.bucketListItemID)
        #expect(try fetchItem(id: saved.bucketListItemID, in: context)?.isCompleted == true)

        try await repository.toggleCompletion(bucketListItemID: saved.bucketListItemID)
        #expect(try fetchItem(id: saved.bucketListItemID, in: context)?.isCompleted == false)
    }

    /// 존재하지 않는 항목의 완료 상태를 바꾸려 하면 항목 조회 실패 오류를 반환하는지 검증합니다.
    @Test
    func toggleCompletion_존재하지_않는_id면_bucketListItemNotFound를_던진다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)

        await #expect(throws: TaedamRepositoryError.bucketListItemNotFound) {
            try await repository.toggleCompletion(bucketListItemID: UUID())
        }
    }

    // MARK: - delete

    /// 저장된 항목을 삭제한 뒤 같은 식별자로는 조회되지 않는지 검증합니다.
    @Test
    func delete_항목을_제거한다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)
        let saved = try await repository.save(
            command: SaveBucketListCommandDTO(category: "아기사랑", content: "안녕")
        )

        try await repository.delete(bucketListItemID: saved.bucketListItemID)

        #expect(try fetchItem(id: saved.bucketListItemID, in: context) == nil)
    }

    /// 존재하지 않는 항목을 삭제하려 하면 항목 조회 실패 오류를 반환하는지 검증합니다.
    @Test
    func delete_존재하지_않는_id면_bucketListItemNotFound를_던진다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)

        await #expect(throws: TaedamRepositoryError.bucketListItemNotFound) {
            try await repository.delete(bucketListItemID: UUID())
        }
    }
}
