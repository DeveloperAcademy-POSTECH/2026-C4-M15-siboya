//
//  HomeWeeklyContentDocument.swift
//  Siboya
//
//  Created by Codex on 7/21/26.
//

import Foundation

struct HomeWeeklyContentDocument: Decodable, Sendable {
    let weeks: [HomeWeeklyContent]

    func content(forGestationalWeek gestationalWeek: Int) -> HomeWeeklyContent? {
        weeks.first { $0.gestationalWeek == gestationalWeek }
    }
}

struct HomeWeeklyContent: Decodable, Sendable {
    let gestationalWeek: Int
    let headline: String
    let recommendedScriptID: UUID
}
