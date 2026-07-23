//  TaedamChecklistViewModel.swift
//  Siboya
//
//  SCRUM-26 태담 체크박스 리스트
//  TaedamRepository 호출 + 유효성 검사 + 에러 처리를 담당한다.
//  @Query는 SwiftUI 환경에 묶여있어 View에만 선언 가능하므로,
//  View가 매 호출마다 repository를 건네주는 방식으로 연결한다.
//

import Foundation
import Observation

@Observable
final class TaedamChecklistViewModel {

    var errorMessage: String?

    func updateNickname(_ nickname: String, using repository: TaedamRepository) async {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            try await repository.updateNickname(trimmed)
        } catch {
            errorMessage = "태명 변경에 실패했어요. 다시 시도해주세요."
        }
    }

    func updateGestationalWeek(_ week: Int, using repository: TaedamRepository) async {
        do {
            try await repository.updateGestationalWeek(week)
        } catch {
            errorMessage = "주차 수정에 실패했어요. 다시 시도해주세요."
        }
    }

    func updateContent(
        bucketListItemID: UUID,
        content: String,
        using repository: TaedamRepository
    ) async {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            try await repository.updateContent(
                command: UpdateBucketListContentCommandDTO(
                    bucketListItemID: bucketListItemID,
                    content: trimmed
                )
            )
        } catch {
            errorMessage = "내용 수정에 실패했어요. 다시 시도해주세요."
        }
    }

    func delete(bucketListItemID: UUID, using repository: TaedamRepository) async {
        do {
            try await repository.delete(bucketListItemID: bucketListItemID)
        } catch {
            errorMessage = "삭제에 실패했어요. 다시 시도해주세요."
        }
    }
}
