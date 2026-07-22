//
//  TaedamRepository.swift
//  Siboya
//

import Foundation

/// 태담 저장소가 입력 검증과 데이터 조회 실패를 호출자에게 구분해 알리는 오류입니다.
enum TaedamRepositoryError: Error, Equatable {
    /// 태명이 비어 있어 프로필을 만들거나 수정할 수 없는 경우입니다.
    case emptyNickname
    /// 버킷리스트 분류가 비어 있어 저장할 수 없는 경우입니다.
    case emptyCategory
    /// 버킷리스트 내용이 비어 있어 저장하거나 수정할 수 없는 경우입니다.
    case emptyContent
    /// 수정할 아기 프로필이 아직 생성되지 않은 경우입니다.
    case babyProfileNotFound
    /// 수정·완료·삭제할 버킷리스트 항목을 찾을 수 없는 경우입니다.
    case bucketListItemNotFound
}

/// 태담 화면이 필요한 프로필과 버킷리스트 데이터를 저장·조회하는 추상 인터페이스입니다.
protocol TaedamRepository: Sendable {
    /// 저장된 아기 프로필 한 건을 조회하고, 없으면 `nil`을 반환합니다.
    func fetchBabyProfile() throws -> BabyProfile?

    /// 프로필이 없는 경우에만 유효한 태명과 임신 주수로 새 프로필을 만듭니다.
    func ensureBabyProfile(nickname: String, gestationalWeek: Int) async throws

    /// 이미 저장된 프로필의 태명을 유효한 새 값으로 변경합니다.
    func updateNickname(_ nickname: String) async throws

    /// 사용자가 작성한 버킷리스트 항목을 저장하고 이후 작업에 사용할 식별자를 반환합니다.
    func save(command: SaveBucketListCommandDTO) async throws -> SavedBucketListDTO

    /// 지정한 버킷리스트 항목의 내용만 변경합니다.
    func updateContent(command: UpdateBucketListContentCommandDTO) async throws

    /// 지정한 버킷리스트 항목의 완료 상태를 반전합니다.
    func toggleCompletion(bucketListItemID: UUID) async throws

    /// 지정한 버킷리스트 항목을 영구적으로 제거합니다.
    func delete(bucketListItemID: UUID) async throws
}
