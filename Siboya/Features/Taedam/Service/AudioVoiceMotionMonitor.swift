//
//  AudioVoiceMotionMonitor.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import AVFAudio
import Foundation

/// 대본을 읽는 동안 마이크 음량을 태담 배경 모션 값으로 전달합니다.
///
/// 이 객체는 input node의 bus 0에 tap을 하나 설치합니다. 버킷리스트 STT처럼 같은
/// input node를 사용하는 기능으로 전환하기 전에 ``stopMonitoring()``을 먼저 호출해야 합니다.
@MainActor
final class AudioVoiceMotionMonitor: VoiceMotionMonitoring {
    nonisolated let samples: AsyncStream<VoiceMotionSampleDTO>

    private let sampleContinuation: AsyncStream<VoiceMotionSampleDTO>.Continuation
    private let audioEngine: AVAudioEngine
    private let audioSession: AVAudioSession
    private let authorizationService: TaedamSpeechAuthorizationService

    private var analyzer: VoiceMotionAnalyzer
    private var isMonitoring = false
    private var hasInstalledAudioTap = false

    init(analysisPolicy: VoiceMotionAnalysisPolicy = .init()) {
        let sampleStream = AsyncStream.makeStream(
            of: VoiceMotionSampleDTO.self,
            bufferingPolicy: .bufferingNewest(1)
        )

        samples = sampleStream.stream
        sampleContinuation = sampleStream.continuation
        audioEngine = AVAudioEngine()
        audioSession = AVAudioSession.sharedInstance()
        authorizationService = TaedamSpeechAuthorizationService()
        analyzer = VoiceMotionAnalyzer(policy: analysisPolicy)
    }

    deinit {
        sampleContinuation.finish()
    }

    /// 마이크 tap을 설치하고 음량 샘플 전달을 시작합니다.
    func startMonitoring() async throws {
        guard !isMonitoring else { return }

        let authorization = authorizationService.currentAuthorization()
        guard authorization.microphone == .authorized else {
            throw VoiceMotionMonitoringError.microphonePermissionDenied
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard recordingFormat.sampleRate > 0,
              recordingFormat.channelCount > 0 else {
            throw VoiceMotionMonitoringError.invalidAudioFormat
        }

        do {
            try audioSession.setCategory(.record, mode: .measurement)
            try audioSession.setActive(true)

            analyzer.reset()
            inputNode.installTap(
                onBus: 0,
                bufferSize: 1_024,
                format: recordingFormat
            ) { [weak self] buffer, _ in
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

            audioEngine.prepare()
            isMonitoring = true
            try audioEngine.start()
        } catch let error as VoiceMotionMonitoringError {
            cleanUp()
            throw error
        } catch {
            cleanUp()
            throw VoiceMotionMonitoringError.audioSessionUnavailable
        }
    }

    /// 마이크 tap과 오디오 세션을 정리합니다.
    func stopMonitoring() async {
        cleanUp()
        sampleContinuation.yield(
            VoiceMotionSampleDTO(
                normalizedValue: 0,
                isVoiceActive: false
            )
        )
    }

    private func receiveAudioLevel(
        rmsDecibels: Float,
        duration: TimeInterval
    ) {
        guard isMonitoring else { return }

        sampleContinuation.yield(
            analyzer.process(
                rmsDecibels: rmsDecibels,
                duration: duration
            )
        )
    }

    private func cleanUp() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if hasInstalledAudioTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledAudioTap = false
        }

        isMonitoring = false
        analyzer.reset()
        try? audioSession.setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }
}
