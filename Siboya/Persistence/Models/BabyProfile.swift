//
//  BabyProfile.swift
//  Siboya
//

import Foundation
import SwiftData

@Model
final class BabyProfile {
    @Attribute(.unique) var id: UUID
    private(set) var nickname: String
    private(set) var gestationalWeek: Int

    init(
        id: UUID = UUID(),
        nickname: String,
        gestationalWeek: Int
    ) {
        self.id = id
        self.nickname = nickname
        self.gestationalWeek = gestationalWeek
    }

    func updateNickname(_ newNickname: String) {
        nickname = newNickname
    }

    func updateGestationalWeek(_ newWeek: Int) {
        gestationalWeek = newWeek
    }
}
