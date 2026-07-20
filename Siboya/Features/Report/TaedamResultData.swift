//
//  TaedamResultData.swift
//  Siboya
//
//  Created by Erin Yaebin Kim on 7/20/26.
//

import Foundation

struct TaedamActionItem: Identifiable, Equatable {
    let id: UUID
    let title: String
}

struct TaedamResultData: Equatable {
    let week: Int
    let theme: String
    let summary: String
    let promise: TaedamActionItem
    let imageName: String
}
