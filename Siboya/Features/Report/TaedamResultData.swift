//
//  TaedamResultData.swift
//  Siboya
//
//  Created by Erin Yaebin Kim on 7/20/26.
//

import Foundation

struct TaedamResultData: Equatable {
    let week: Int
    let question: String
    let summary: String
    let actionItems: [String]
    let imageName: String
}
