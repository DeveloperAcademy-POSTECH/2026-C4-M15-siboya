//
//  BabyProfile.swift
//  Siboya
//

import Foundation
import SwiftData

/// 앱에 하나만 저장되는 아기 프로필의 태명과 임신 주수를 SwiftData로 보관합니다.
@Model
final class BabyProfile {
    /// SwiftData에서 각 프로필을 고유하게 식별하기 위한 값입니다.
    @Attribute(.unique) var id: UUID

    /// 화면에 표시할 태명으로, 외부에서는 전용 변경 함수로만 수정합니다.
    private(set) var nickname: String
  
    /// 홈과 태담 콘텐츠 선택에 사용하는 현재 임신 주수입니다.
    private(set) var gestationalWeek: Int

    /// 저장할 프로필의 식별자·태명·임신 주수를 받아 새 모델을 만듭니다.
    /// - Parameters:
    ///   - id: 기존 데이터 복원 시에도 사용할 수 있는 고유 식별자입니다.
    ///   - nickname: 사용자에게 표시할 태명입니다.
    ///   - gestationalWeek: 현재 임신 주수입니다.
    init(
        id: UUID = UUID(),
        nickname: String,
        gestationalWeek: Int
    ) {
        self.id = id
        self.nickname = nickname
        self.gestationalWeek = gestationalWeek
    }

    /// 새 태명으로 변경해 저장소가 수정 사실을 추적할 수 있게 합니다.
    /// - Parameter newNickname: 공백 검증을 마친 새 태명입니다.
    func updateNickname(_ newNickname: String) {
        nickname = newNickname
    }

    func updateGestationalWeek(_ newWeek: Int) {
        gestationalWeek = newWeek
    }
}
