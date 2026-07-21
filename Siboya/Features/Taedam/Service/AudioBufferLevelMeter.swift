//
//  AudioBufferLevelMeter.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import Accelerate
import AVFAudio
import Foundation

/// 마이크의 PCM 버퍼를 무음 감지에 사용할 RMS dB 값으로 변환합니다.
enum AudioBufferLevelMeter {
    nonisolated static func rmsDecibels(
        in buffer: AVAudioPCMBuffer
    ) -> Float {
        guard let channelData = buffer.floatChannelData?.pointee,
              buffer.frameLength > 0 else {
            return -.infinity
        }

        var rootMeanSquare: Float = 0
        vDSP_rmsqv(
            channelData,
            1,
            &rootMeanSquare,
            vDSP_Length(buffer.frameLength)
        )

        guard rootMeanSquare > 0 else { return -.infinity }
        return 20 * log10(rootMeanSquare)
    }
}
