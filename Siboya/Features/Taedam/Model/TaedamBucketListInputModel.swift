//
//  TaedamBucketListInputModel.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import Foundation
import Observation

/// 태담의 버킷리스트 STT와 키보드 편집 상태를 나타냅니다.
enum TaedamBucketListInputPhase: Equatable, Sendable {
    case idle
    case transcribing
    case finalizing
    case editing
}

/// STT의 부분 전사와 자동 종료 이벤트를 화면의 편집 상태로 연결합니다.
@MainActor
@Observable
final class TaedamBucketListInputModel {
    private(set) var phase: TaedamBucketListInputPhase = .idle
    private(set) var liveTranscript = ""
    private(set) var draft: BucketListDraftDTO?
    private(set) var error: BucketListTranscriptionError?
    private(set) var automaticEndReason: BucketListTranscriptionEndReason?
    private(set) var voiceMotionSample = VoiceMotionSampleDTO(
        normalizedValue: 0,
        isVoiceActive: false
    )

    /// 키보드로 수정 중인 문장입니다. 저장 단계에서는 이 값만 사용해야 합니다.
    var editedText = ""

    private let transcriber: any BucketListTranscribing
    private var activeSessionID: UUID?
    private var partialTranscriptTask: Task<Void, Never>?
    private var automaticEndTask: Task<Void, Never>?
    private var voiceMotionTask: Task<Void, Never>?

    init(transcriber: any BucketListTranscribing) {
        self.transcriber = transcriber
    }

    /// 부분 전사와 자동 종료 이벤트를 구독한 뒤 STT를 시작합니다.
    func start(duration: Duration = .seconds(20)) async {
        guard phase == .idle else { return }

        let sessionID = UUID()
        activeSessionID = sessionID
        resetDraftValues()
        phase = .transcribing
        observeTranscriber(sessionID: sessionID)

        do {
            try await transcriber.start(duration: duration)
        } catch let transcriptionError as BucketListTranscriptionError {
            guard activeSessionID == sessionID else { return }
            moveToEmptyEditingState(error: transcriptionError)
        } catch {
            guard activeSessionID == sessionID else { return }
            moveToEmptyEditingState(error: .recognitionFailed)
        }
    }

    /// 사용자의 정지 입력 또는 자동 종료 이벤트에 따라 최종 전사문을 확정합니다.
    func finish() async {
        guard phase == .transcribing,
              let sessionID = activeSessionID else {
            return
        }

        phase = .finalizing

        do {
            let draft = try await transcriber.finish()
            guard activeSessionID == sessionID else { return }
            moveToEditingState(draft: draft)
        } catch let transcriptionError as BucketListTranscriptionError {
            guard activeSessionID == sessionID else { return }
            moveToEmptyEditingState(error: transcriptionError)
        } catch {
            guard activeSessionID == sessionID else { return }
            moveToEmptyEditingState(error: .recognitionFailed)
        }
    }

    /// 대본으로 돌아가거나 화면을 닫을 때 STT와 작성 중인 문장을 폐기합니다.
    func cancel() async {
        activeSessionID = nil
        stopObservingTranscriber()
        phase = .idle
        resetDraftValues()
        await transcriber.cancel()
    }

    private func observeTranscriber(sessionID: UUID) {
        let partialTranscripts = transcriber.partialTranscripts
        let automaticEndEvents = transcriber.automaticEndEvents
        let voiceMotionSamples = transcriber.voiceMotionSamples

        partialTranscriptTask = Task { [weak self] in
            for await transcript in partialTranscripts {
                guard !Task.isCancelled,
                      self?.activeSessionID == sessionID else {
                    return
                }

                self?.liveTranscript = transcript
            }
        }

        automaticEndTask = Task { [weak self] in
            for await reason in automaticEndEvents {
                guard !Task.isCancelled,
                      self?.activeSessionID == sessionID else {
                    return
                }

                self?.automaticEndReason = reason
                await self?.finish()
                return
            }
        }

        voiceMotionTask = Task { [weak self] in
            for await sample in voiceMotionSamples {
                guard !Task.isCancelled,
                      self?.activeSessionID == sessionID else {
                    return
                }

                self?.voiceMotionSample = sample
            }
        }
    }

    private func moveToEditingState(draft: BucketListDraftDTO) {
        self.draft = draft
        liveTranscript = draft.rawTranscript
        editedText = draft.editedText
        phase = .editing
        voiceMotionSample = VoiceMotionSampleDTO(
            normalizedValue: 0,
            isVoiceActive: false
        )
        stopObservingTranscriber()
    }

    private func moveToEmptyEditingState(
        error: BucketListTranscriptionError
    ) {
        self.error = error
        moveToEditingState(
            draft: BucketListDraftDTO(
                rawTranscript: "",
                editedText: ""
            )
        )
    }

    private func stopObservingTranscriber() {
        partialTranscriptTask?.cancel()
        partialTranscriptTask = nil
        automaticEndTask?.cancel()
        automaticEndTask = nil
        voiceMotionTask?.cancel()
        voiceMotionTask = nil
    }

    private func resetDraftValues() {
        liveTranscript = ""
        draft = nil
        editedText = ""
        error = nil
        automaticEndReason = nil
        voiceMotionSample = VoiceMotionSampleDTO(
            normalizedValue: 0,
            isVoiceActive: false
        )
    }
}
