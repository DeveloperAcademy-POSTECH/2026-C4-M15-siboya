//
//  HomeScriptItem.swift
//  Siboya
//

import Foundation

struct HomeScriptItem: Identifiable, Equatable, Sendable {
    let scriptID: UUID
    let scriptVersion: Int
    let title: String
    let targetGestationalWeek: Int
    let artworkAssetName: String

    var id: String {
        "\(scriptID.uuidString)-\(scriptVersion)"
    }

    var gestationalWeekText: String {
        "\(targetGestationalWeek)주차"
    }
}
