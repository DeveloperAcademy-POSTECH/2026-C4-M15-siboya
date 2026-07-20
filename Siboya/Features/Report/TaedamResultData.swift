//
//  TaedamResultData.swift
//  Siboya
//
//  Created by Erin Yaebin Kim on 7/20/26.
//

import Foundation

struct TaedamResultData: Equatable {
    let week: Int
    let theme: String
    let summary: String
    let actionItems: [TaedamActionItem]
    let imageName: String
}

struct TaedamActionItem: Identifiable, Equatable {
    let id: UUID
    let title: String
}
