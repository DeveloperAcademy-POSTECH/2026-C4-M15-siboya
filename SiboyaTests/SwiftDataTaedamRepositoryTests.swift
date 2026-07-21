//
//  SwiftDataTaedamRepositoryTests.swift
//  SiboyaTests
//

import Foundation
import Testing
import SwiftData
@testable import Siboya

struct SwiftDataTaedamRepositoryTests {
    private func makeContext() -> ModelContext {
        ModelContext(PersistenceContainer.makeContainer(inMemory: true))
    }

    private func fetchItem(id: UUID, in context: ModelContext) throws -> BucketListItem? {
        try context.fetch(
            FetchDescriptor<BucketListItem>(predicate: #Predicate { $0.id == id })
        ).first
    }

    // MARK: - fetchBabyProfile

    @Test func fetchBabyProfile_프로필이_없으면_nil을_반환한다() throws {
        let context = makeContext()
        let repository = SwiftDataTaedamRepository(modelContext: context)

        #expect(try repository.fetchBabyProfile() == nil)
    }

    @Test func fetchBabyProfile_있으면_그_프로필을_반환한다() throws {
        let context = makeContext()
        context.insert(BabyProfile(nickname: "콩콩이", gestationalWeek: 22))
        try context.save()
        let repository = SwiftDataTaedamRepository(modelContext: context)

        let profile = try repository.fetchBabyProfile()

        #expect(profile?.nickname == "콩콩이")
        #expect(profile?.gestationalWeek == 22)
    }

    // MARK: - ensureBabyProfile

    @Test func ensureBabyProfile_없으면_생성한다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)

        try await repository.ensureBabyProfile(nickname: "콩콩이", gestationalWeek: 22)

        let profile = try await repository.fetchBabyProfile()
        #expect(profile?.nickname == "콩콩이")
        #expect(profile?.gestationalWeek == 22)
    }

    @Test func ensureBabyProfile_이미_있으면_그대로_둔다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)
        try await repository.ensureBabyProfile(nickname: "콩콩이", gestationalWeek: 22)

        try await repository.ensureBabyProfile(nickname: "다른이름", gestationalWeek: 10)

let profile = try repository.fetchBabyProfile()
        #expect(profile?.nickname == "콩콩이")
        #expect(profile?.gestationalWeek == 22)
    }

    @Test func ensureBabyProfile_닉네임이_공백뿐이면_emptyNickname을_던진다() async throws {
        let context = makeContext()
let repository = SwiftDataTaedamRepository(modelContext: context)

        await #expect(throws: TaedamRepositoryError.emptyNickname) {
            try await repository.ensureBabyProfile(nickname: "   ", gestationalWeek: 22)
        }
    }

    // MARK: - updateNickname

    @Test func updateNickname_태명을_변경한다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)
        try await repository.ensureBabyProfile(nickname: "콩콩이", gestationalWeek: 22)

        try await repository.updateNickname("꾹꾹이")

        #expect(try repository.fetchBabyProfile()?.nickname == "꾹꾹이")
    }

    @Test func updateNickname_공백뿐이면_emptyNickname을_던진다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)
        try await repository.ensureBabyProfile(nickname: "콩콩이", gestationalWeek: 22)

        await #expect(throws: TaedamRepositoryError.emptyNickname) {
            try await repository.updateNickname("   ")
        }
    }

    @Test func updateNickname_프로필이_없으면_babyProfileNotFound를_던진다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)

        await #expect(throws: TaedamRepositoryError.babyProfileNotFound) {
            try await repository.updateNickname("꾹꾹이")
        }
    }

    // MARK: - save

    @Test func save_유효한_입력이면_저장하고_id를_반환한다() async throws {
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

    @Test func save_앞뒤_공백을_trim해서_저장한다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)

        let result = try await repository.save(
            command: SaveBucketListCommandDTO(category: "  아기사랑  ", content: "  안녕  ")
        )

        let saved = try await fetchItem(id: result.bucketListItemID, in: context)
        #expect(saved?.category == "아기사랑")
        #expect(saved?.content == "안녕")
    }

    @Test func save_카테고리가_공백뿐이면_emptyCategory를_던진다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)

        await #expect(throws: TaedamRepositoryError.emptyCategory) {
            try await repository.save(
                command: SaveBucketListCommandDTO(category: "   ", content: "안녕")
            )
        }
    }

    @Test func save_content가_공백뿐이면_emptyContent를_던진다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)

        await #expect(throws: TaedamRepositoryError.emptyContent) {
            try await repository.save(
                command: SaveBucketListCommandDTO(category: "아기사랑", content: "   ")
            )
        }
    }

    // MARK: - updateContent

    @Test func updateContent_content를_바꾸고_category는_그대로다() async throws {
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

    @Test func updateContent_content가_공백뿐이면_emptyContent를_던진다() async throws {
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

    @Test func updateContent_존재하지_않는_id면_bucketListItemNotFound를_던진다() async throws {
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

    @Test func toggleCompletion_호출할_때마다_isCompleted를_뒤집는다() async throws {
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

    @Test func toggleCompletion_존재하지_않는_id면_bucketListItemNotFound를_던진다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)

        await #expect(throws: TaedamRepositoryError.bucketListItemNotFound) {
            try await repository.toggleCompletion(bucketListItemID: UUID())
        }
    }

    // MARK: - delete

    @Test func delete_항목을_제거한다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)
        let saved = try await repository.save(
            command: SaveBucketListCommandDTO(category: "아기사랑", content: "안녕")
        )

        try await repository.delete(bucketListItemID: saved.bucketListItemID)

        #expect(try fetchItem(id: saved.bucketListItemID, in: context) == nil)
    }

    @Test func delete_존재하지_않는_id면_bucketListItemNotFound를_던진다() async throws {
        let context = makeContext()
        let repository = await SwiftDataTaedamRepository(modelContext: context)

        await #expect(throws: TaedamRepositoryError.bucketListItemNotFound) {
            try await repository.delete(bucketListItemID: UUID())
        }
    }
}
