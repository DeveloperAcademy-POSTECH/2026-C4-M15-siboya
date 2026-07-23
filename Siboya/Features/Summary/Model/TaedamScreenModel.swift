//
//  TaedamScreenModel.swift
//  Siboya
//
//  Created by Codex on 7/21/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class TaedamScreenModel {
    private(set) var phase: TaedamScreenPhase = .ready
    private(set) var currentLineIndex: Int?
    private(set) var currentLineProgress = 0.0

    let lines: [TaedamLineDTO]
    let bucketListGuide: String

    private let timingPolicy: TaedamTimingPolicy
    private let sleeper: any TaedamSleeping
    private var activeFlowID: UUID?
    private var progressTask: Task<Void, Never>?

    init(
        input: TaedamSessionInputDTO,
        timingPolicy: TaedamTimingPolicy? = nil,
        sleeper: (any TaedamSleeping)? = nil
    ) {
        lines = input.lines
        bucketListGuide = input.script.bucketListGuide
        self.timingPolicy = timingPolicy ?? TaedamTimingPolicy()
        self.sleeper = sleeper ?? ContinuousTaedamSleeper()
    }

    var countdownValue: Int? {
        guard case let .countingDown(remainingSeconds) = phase else {
            return nil
        }

        return remainingSeconds
    }

    var bucketListIndex: Int? {
        lines.firstIndex { $0.kind == .bucketList }
    }

    func start() {
        guard phase == .ready else { return }
        startFlow(at: 0, includesCountdown: true)
    }

    func selectLine(at index: Int) {
        guard allowsScriptSelection,
              lines.indices.contains(index),
              lines[index].kind.isScript else {
            return
        }

        startFlow(at: index, includesCountdown: false)
    }

    func cancel() {
        activeFlowID = nil
        progressTask?.cancel()
        progressTask = nil
    }

    func isLineSelectable(at index: Int) -> Bool {
        guard allowsScriptSelection,
              lines.indices.contains(index) else {
            return false
        }

        return lines[index].kind.isScript
    }

    private var allowsScriptSelection: Bool {
        switch phase {
        case .readingScript, .bucketList:
            return true
        case .ready, .countingDown:
            return false
        }
    }

    private func startFlow(at index: Int, includesCountdown: Bool) {
        progressTask?.cancel()

        let flowID = UUID()
        activeFlowID = flowID
        progressTask = Task { [weak self] in
            await self?.runFlow(
                id: flowID,
                startIndex: index,
                includesCountdown: includesCountdown
            )
        }
    }

    private func runFlow(
        id: UUID,
        startIndex: Int,
        includesCountdown: Bool
    ) async {
        do {
            if includesCountdown {
                try await runCountdown(id: id)
            }

            try await runScript(id: id, startIndex: startIndex)
        } catch is CancellationError {
            return
        } catch {
            return
        }

        guard activeFlowID == id else { return }
        progressTask = nil
    }

    private func runCountdown(id: UUID) async throws {
        guard timingPolicy.countdownSeconds > 0 else { return }

        for remainingSeconds in stride(
            from: timingPolicy.countdownSeconds,
            through: 1,
            by: -1
        ) {
            try ensureActiveFlow(id: id)
            phase = .countingDown(remainingSeconds: remainingSeconds)
            try await sleeper.sleep(for: .seconds(1))
        }
    }

    private func runScript(id: UUID, startIndex: Int) async throws {
        guard let bucketListIndex else { return }

        for index in startIndex..<bucketListIndex {
            try ensureActiveFlow(id: id)
            try await runLine(id: id, index: index)
        }

        try ensureActiveFlow(id: id)
        currentLineIndex = bucketListIndex
        currentLineProgress = 1
        phase = .bucketList
    }

    private func runLine(id: UUID, index: Int) async throws {
        let line = lines[index]
        let stepCount = timingPolicy.progressStepCount(for: line.text)
        let duration = timingPolicy.durationSeconds(for: line.text)
        let stepDuration = duration / Double(stepCount)

        currentLineIndex = index
        currentLineProgress = 0
        phase = .readingScript(index: index)

        for step in 1...stepCount {
            try await sleeper.sleep(for: .seconds(stepDuration))
            try ensureActiveFlow(id: id)
            currentLineProgress = Double(step) / Double(stepCount)
        }
    }

    private func ensureActiveFlow(id: UUID) throws {
        try Task.checkCancellation()

        guard activeFlowID == id else {
            throw CancellationError()
        }
    }
}

private extension TaedamLineKindDTO {
    var isScript: Bool {
        if case .script = self {
            return true
        }

        return false
    }
}
