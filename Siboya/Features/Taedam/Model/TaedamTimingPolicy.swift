//
//  TaedamTimingPolicy.swift
//  Siboya
//
//  Created by Codex on 7/21/26.
//

import Foundation

struct TaedamTimingPolicy: Equatable, Sendable {
    let countdownSeconds: Int
    let charactersPerSecond: Double
    let minimumDurationSeconds: Double
    let maximumDurationSeconds: Double
    let progressUpdatesPerSecond: Int

    init(
        countdownSeconds: Int = 3,
        charactersPerSecond: Double = 4,
        minimumDurationSeconds: Double = 2.5,
        maximumDurationSeconds: Double = 10,
        progressUpdatesPerSecond: Int = 30
    ) {
        self.countdownSeconds = max(0, countdownSeconds)
        self.charactersPerSecond = max(0.1, charactersPerSecond)
        self.minimumDurationSeconds = max(0, minimumDurationSeconds)
        self.maximumDurationSeconds = max(
            self.minimumDurationSeconds,
            maximumDurationSeconds
        )
        self.progressUpdatesPerSecond = max(1, progressUpdatesPerSecond)
    }

    func durationSeconds(for text: String) -> Double {
        let characterCount = text.filter { !$0.isWhitespace }.count
        let calculatedDuration = Double(characterCount) / charactersPerSecond

        return min(
            max(calculatedDuration, minimumDurationSeconds),
            maximumDurationSeconds
        )
    }

    func progressStepCount(for text: String) -> Int {
        max(1, Int((durationSeconds(for: text) * Double(progressUpdatesPerSecond)).rounded(.up)))
    }
}
