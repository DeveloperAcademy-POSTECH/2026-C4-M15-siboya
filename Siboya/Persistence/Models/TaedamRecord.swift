//
//  TaedamRecord.swift
//  Siboya
//
//  Created by 노을 on 7/15/26.
//

import Foundation
import SwiftData

@Model
final class TaedamRecord {
    var date: Date
    var scriptKeyword: String

    init(date: Date, scriptKeyword: String) {
        self.date = date
        self.scriptKeyword = scriptKeyword
    }
}
