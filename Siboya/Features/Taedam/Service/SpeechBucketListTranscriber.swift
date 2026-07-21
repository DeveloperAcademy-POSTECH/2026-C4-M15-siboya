//
//  SpeechBucketListTranscriber.swift
//  Siboya
//
//  Created by Codex on 7/21/26.
//

import AVFAudio
import Foundation
import Speech

/// Apple Speech와 마이크 입력을 사용해 버킷리스트를 한국어 텍스트로 변환합니다.
///
/// 기본 인식 언어는 `ko-KR`이며 한 번에 하나의 전사만 실행합니다. 화면에서는 부분 전사 스트림을
/// 구독해 플레이스홀더를 실시간 문장으로 덮어쓰고, 정지 또는 자동 종료 후 `finish()`로 초안을 받습니다.
///
/// 사용 예시:
/// ```swift
/// let transcriber = SpeechBucketListTranscriber()
///
/// let transcriptTask = Task {
///     for await transcript in transcriber.partialTranscripts {
///         // 화면에 최신 전체 전사문을 표시합니다.
///     }
/// }
/// try await transcriber.start(duration: .seconds(20))
///
/// // 사용자가 정지 버튼을 누르거나 화면의 20초 타이머가 끝났을 때 호출합니다.
/// let draft = try await transcriber.finish()
/// transcriptTask.cancel()
/// ```
///
/// 최초 발화 후 연속 무음이 감지되거나 `duration`이 지나면 마이크를 자동으로 닫고
/// ``automaticEndEvents``로 알립니다. 최종 ``BucketListDraftDTO``를 받으려면 호출 측에서
/// `finish()`를 호출해야 합니다. 대본으로 돌아갈 때는 `cancel()`로 전사문을 폐기합니다.
@MainActor
final class SpeechBucketListTranscriber: BucketListTranscribing {
    /// 새 인식 결과가 생길 때마다 가장 최근의 전체 전사문을 전달합니다.
    ///
    /// 느린 구독자가 이전 값을 처리 중이면 가장 최신 값 하나만 버퍼에 유지합니다.
    nonisolated let partialTranscripts: AsyncStream<String>

    /// 마이크 입력이 자동으로 끝날 때 종료 이유를 전달합니다.
    nonisolated let automaticEndEvents: AsyncStream<BucketListTranscriptionEndReason>

    private let partialTranscriptContinuation: AsyncStream<String>.Continuation
    private let automaticEndEventContinuation:
        AsyncStream<BucketListTranscriptionEndReason>.Continuation
    private let recognizer: SFSpeechRecognizer?
    private let audioEngine: AVAudioEngine
    private let audioSession: AVAudioSession
    private let authorizationService: TaedamSpeechAuthorizationService
    private let finalizationGracePeriod: Duration

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var timeoutTask: Task<Void, Never>?
    private var state = State.idle
    private var latestTranscript = ""
    private var receivedFinalResult = false
    private var recognitionFailed = false
    private var hasInstalledAudioTap = false
    private var silenceDetector: BucketListSilenceDetector

    /// 전사 서비스를 생성합니다.
    ///
    /// - Parameters:
    ///   - locale: Speech 인식 언어입니다. 기본값은 한국어 `ko-KR`입니다.
    ///   - finalizationGracePeriod: `finish()` 후 Speech의 최종 결과를 기다릴 최대 시간입니다.
    ///   - silenceDetectionPolicy: 최초 발화와 연속 무음을 판정할 정책입니다.
    init(
        locale: Locale = Locale(identifier: "ko-KR"),
        finalizationGracePeriod: Duration = .seconds(1),
        silenceDetectionPolicy: BucketListSilenceDetectionPolicy = .init()
    ) {
        let partialTranscriptStream = AsyncStream.makeStream(
            of: String.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        let automaticEndEventStream = AsyncStream.makeStream(
            of: BucketListTranscriptionEndReason.self,
            bufferingPolicy: .bufferingNewest(1)
        )

        partialTranscripts = partialTranscriptStream.stream
        partialTranscriptContinuation = partialTranscriptStream.continuation
        automaticEndEvents = automaticEndEventStream.stream
        automaticEndEventContinuation = automaticEndEventStream.continuation
        recognizer = SFSpeechRecognizer(locale: locale)
        audioEngine = AVAudioEngine()
        audioSession = AVAudioSession.sharedInstance()
        authorizationService = TaedamSpeechAuthorizationService()
        self.finalizationGracePeriod = finalizationGracePeriod
        silenceDetector = BucketListSilenceDetector(
            policy: silenceDetectionPolicy
        )
    }

    deinit {
        partialTranscriptContinuation.finish()
        automaticEndEventContinuation.finish()
    }

    // MARK: - Start
    /// 마이크 입력과 부분 전사를 시작합니다.
    ///
    /// 권한 팝업은 이 메서드에서 표시하지 않습니다. 먼저
    /// ``TaedamSpeechAuthorizationService/requestAuthorization()``을 호출해야 합니다.
    ///
    /// - Parameter duration: 마이크를 열어둘 최대 시간입니다.
    func start(duration: Duration) async throws {
        guard duration > .zero else {
            throw BucketListTranscriptionError.invalidDuration
        }

        guard state == .idle else {
            throw BucketListTranscriptionError.alreadyTranscribing
        }

        try validateAuthorization()

        guard let recognizer, recognizer.isAvailable else {
            throw BucketListTranscriptionError.recognizerUnavailable
        }

        resetTranscriptionValues()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        request.taskHint = .dictation
        recognitionRequest = request

        do {
            try configureAudioSession()
            try installAudioTap(for: request)

            state = .transcribing
            // Speech 결과 콜백
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                let transcript = result?.bestTranscription.formattedString
                let isFinal = result?.isFinal ?? false
                let hasError = error != nil

                Task { @MainActor [weak self] in
                    self?.receiveRecognitionUpdate(
                        transcript: transcript,
                        isFinal: isFinal,
                        hasError: hasError
                    )
                }
            }

            audioEngine.prepare()
            try audioEngine.start()
            scheduleTimeout(after: duration)
        } catch let error as BucketListTranscriptionError {
            cleanUp(cancelRecognition: true)
            throw error
        } catch {
            cleanUp(cancelRecognition: true)
            throw BucketListTranscriptionError.recognitionFailed
        }
    }

    // MARK: - Finish
    /// 마이크를 닫고 최종 Speech 결과를 기다린 뒤 편집 가능한 초안을 반환합니다.
    ///
    /// 사용자가 아무 말도 하지 않았다면 빈 문자열을 가진 초안을 반환할 수 있습니다.
    func finish() async throws -> BucketListDraftDTO {
        guard state != .idle else {
            throw BucketListTranscriptionError.notTranscribing
        }

        if state == .transcribing {
            stopAudioCapture(endingRecognition: true)
            state = .awaitingFinalResult
        }

        do {
            try await waitForFinalResult()
        } catch {
            cleanUp(cancelRecognition: true)
            throw error
        }

        if recognitionFailed && latestTranscript.isEmpty {
            cleanUp(cancelRecognition: true)
            throw BucketListTranscriptionError.recognitionFailed
        }

        let transcript = latestTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanUp(cancelRecognition: !receivedFinalResult)

        return BucketListDraftDTO(
            rawTranscript: transcript,
            editedText: transcript
        )
    }

    // MARK: - Cancel
    /// 마이크와 Speech 작업을 즉시 취소하고 현재 전사문을 폐기합니다.
    ///
    /// 취소 후 같은 객체에서 `start(duration:)`을 다시 호출할 수 있습니다.
    func cancel() async {
        cleanUp(cancelRecognition: true)
    }
}

private extension SpeechBucketListTranscriber {
    private func validateAuthorization() throws {
        let authorization = authorizationService.currentAuthorization()

        guard authorization.microphone == .authorized else {
            throw BucketListTranscriptionError.microphonePermissionDenied
        }

        guard authorization.speechRecognition == .authorized else {
            throw BucketListTranscriptionError.speechRecognitionPermissionDenied
        }
    }

    private func configureAudioSession() throws {
        try audioSession.setCategory(.record, mode: .measurement)
        try audioSession.setActive(true)
    }

    private func installAudioTap(
        for request: SFSpeechAudioBufferRecognitionRequest
    ) throws {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        guard recordingFormat.sampleRate > 0,
              recordingFormat.channelCount > 0 else {
            throw BucketListTranscriptionError.invalidAudioFormat
        }

        inputNode.installTap(
            onBus: 0,
            bufferSize: 1_024,
            format: recordingFormat
        ) { buffer, _ in
            request.append(buffer)

            let rmsDecibels = AudioBufferLevelMeter.rmsDecibels(in: buffer)
            let duration = Double(buffer.frameLength) / recordingFormat.sampleRate

            Task { @MainActor [weak self] in
                self?.receiveAudioLevel(
                    rmsDecibels: rmsDecibels,
                    duration: duration
                )
            }
        }
        hasInstalledAudioTap = true
    }

    private func scheduleTimeout(after duration: Duration) {
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            do {
                try await Task.sleep(for: duration)
                guard !Task.isCancelled else { return }
                self?.reachDurationLimit()
            } catch is CancellationError {
                return
            } catch {
                return
            }
        }
    }

    private func reachDurationLimit() {
        endAudioInput(reason: .maximumDuration)
    }

    private func receiveAudioLevel(
        rmsDecibels: Float,
        duration: TimeInterval
    ) {
        guard state == .transcribing else { return }

        if silenceDetector.process(
            rmsDecibels: rmsDecibels,
            duration: duration
        ) {
            endAudioInput(reason: .silence)
        }
    }

    private func endAudioInput(
        reason: BucketListTranscriptionEndReason
    ) {
        guard state == .transcribing else { return }

        stopAudioCapture(endingRecognition: true)
        state = .awaitingFinalResult
        automaticEndEventContinuation.yield(reason)
    }

    private func receiveRecognitionUpdate(
        transcript: String?,
        isFinal: Bool,
        hasError: Bool
    ) {
        guard state != .idle else { return }

        if let transcript, transcript != latestTranscript {
            latestTranscript = transcript
            partialTranscriptContinuation.yield(transcript)
        }

        if isFinal {
            let shouldNotifyAutomaticEnd = state == .transcribing
            receivedFinalResult = true
            stopAudioCapture(endingRecognition: false)
            state = .awaitingFinalResult

            if shouldNotifyAutomaticEnd {
                automaticEndEventContinuation.yield(.recognitionFinalized)
            }
        }

        if hasError {
            let shouldNotifyAutomaticEnd = state == .transcribing
            recognitionFailed = true
            stopAudioCapture(endingRecognition: false)
            state = .awaitingFinalResult

            if shouldNotifyAutomaticEnd {
                automaticEndEventContinuation.yield(.recognitionFailed)
            }
        }
    }

    private func waitForFinalResult() async throws {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: finalizationGracePeriod)

        while !receivedFinalResult,
              !recognitionFailed,
              clock.now < deadline {
            try await Task.sleep(for: .milliseconds(50))
        }
    }

    private func stopAudioCapture(endingRecognition: Bool) {
        timeoutTask?.cancel()
        timeoutTask = nil

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if hasInstalledAudioTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledAudioTap = false
        }

        if endingRecognition {
            recognitionRequest?.endAudio()
        }

        try? audioSession.setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }

    private func cleanUp(cancelRecognition: Bool) {
        stopAudioCapture(endingRecognition: false)

        if cancelRecognition {
            recognitionTask?.cancel()
        }

        recognitionTask = nil
        recognitionRequest = nil
        state = .idle
        resetTranscriptionValues()
    }

    private func resetTranscriptionValues() {
        latestTranscript = ""
        receivedFinalResult = false
        recognitionFailed = false
        silenceDetector.reset()
    }
}

private extension SpeechBucketListTranscriber {
    enum State {
        case idle
        case transcribing
        case awaitingFinalResult
    }
}
