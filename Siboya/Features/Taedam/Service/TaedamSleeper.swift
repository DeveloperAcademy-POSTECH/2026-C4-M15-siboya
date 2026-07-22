//
//  TaedamSleeper.swift
//  Siboya
//
//  Created by Codex on 7/21/26.
//

import Foundation

protocol TaedamSleeping: Sendable {
    func sleep(for duration: Duration) async throws
}

struct ContinuousTaedamSleeper: TaedamSleeping {
    func sleep(for duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }
}
