//
//  TaedamAmbientBackground.swift
//  Siboya
//
//  Created by Codex on 7/21/26.
//

import SwiftUI

/// 화면 하단에서 계속 흐르는 색상과 음성에 반응하는 흰색 표면을 그립니다.
struct TaedamAmbientBackground: View {
    let normalizedVoiceMotion: Double
    let isVoiceActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        normalizedVoiceMotion: Double = 0,
        isVoiceActive: Bool = false
    ) {
        self.normalizedVoiceMotion = normalizedVoiceMotion
        self.isVoiceActive = isVoiceActive
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                ambientContent(at: context.date)
            }
            .frame(height: TaedamAmbientMetrics.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func ambientContent(at date: Date) -> some View {
        let elapsedTime = reduceMotion ? 0 : date.timeIntervalSinceReferenceDate
        let phase = CGFloat(elapsedTime.truncatingRemainder(dividingBy: 1_000))
        let level = CGFloat(min(max(normalizedVoiceMotion, 0), 1))
        let activeLevel = isVoiceActive ? level : level * 0.45
        let amplifiedLevel = min(activeLevel * 1.7, 1)

        return ZStack(alignment: .bottom) {
            movingColorField(
                phase: phase,
                level: amplifiedLevel
            )

            VoiceReactiveSurface(
                level: amplifiedLevel * 0.72,
                phase: phase + 1.7
            )
            .fill(.white.opacity(0.72))
            .frame(height: TaedamAmbientMetrics.surfaceHeight)
            .scaleEffect(x: 1.08, y: 1, anchor: .bottom)
            .blur(radius: 18)

            VoiceReactiveSurface(
                level: amplifiedLevel,
                phase: phase
            )
            .fill(.white)
            .frame(height: TaedamAmbientMetrics.surfaceHeight)
            .scaleEffect(x: 1.05, y: 1, anchor: .bottom)
            .blur(radius: 4)
        }
        .mask(
            LinearGradient(
                colors: [.clear, .black.opacity(0.82), .black],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .compositingGroup()
    }

    private func movingColorField(
        phase: CGFloat,
        level: CGFloat
    ) -> some View {
        let horizontalTravel = 0.16 + (level * 0.22)
        let verticalTravel = 0.05 + (level * 0.07)
        let verticalBounce = 12 + (level * 50)
        let voiceLift = level * 34
        let leftVerticalOffset = (sin((phase * 0.88) + 0.4) * verticalBounce) - voiceLift
        let rightVerticalOffset = (cos((phase * 0.82) + 1.1) * verticalBounce) - voiceLift
        let leftCenter = UnitPoint(
            x: 0.08 + (sin(phase * 0.42) * horizontalTravel),
            y: 0.93 + (cos(phase * 0.31) * verticalTravel)
        )
        let rightCenter = UnitPoint(
            x: 0.92 + (cos(phase * 0.37) * horizontalTravel),
            y: 0.94 + (sin(phase * 0.29) * verticalTravel)
        )
        let center = UnitPoint(
            x: 0.5 + (sin(phase * 0.24) * 0.24),
            y: 0.97
        )

        return ZStack {
            colorGlow(
                color: Color(red: 0.96, green: 0.32, blue: 0.86).opacity(0.82),
                center: leftCenter,
                endRadius: 220 + (145 * level)
            )
            .offset(y: leftVerticalOffset)

            colorGlow(
                color: Color(red: 0.24, green: 0.62, blue: 1).opacity(0.84),
                center: rightCenter,
                endRadius: 235 + (155 * level)
            )
            .offset(y: rightVerticalOffset)

            colorGlow(
                color: Color(red: 0.55, green: 0.34, blue: 1).opacity(0.44),
                center: center,
                endRadius: 180 + (105 * level)
            )
            .offset(
                y: (sin((phase * 0.7) + 2.3) * verticalBounce * 0.55) -
                    (voiceLift * 0.65)
            )
        }
        .scaleEffect(
            x: 1 + (0.24 * level),
            y: 1 + (0.16 * level),
            anchor: .bottom
        )
        .blur(radius: 24)
    }

    private func colorGlow(
        color: Color,
        center: UnitPoint,
        endRadius: CGFloat
    ) -> some View {
        RadialGradient(
            colors: [color, .clear],
            center: center,
            startRadius: 0,
            endRadius: endRadius
        )
    }
}

/// 음량에 따라 아래쪽 흰색 영역의 높이와 굴곡을 변화시키는 표면입니다.
private struct VoiceReactiveSurface: Shape {
    var level: CGFloat
    var phase: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(level, phase) }
        set {
            level = newValue.first
            phase = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let clampedLevel = min(max(level, 0), 1)
        let pulse = 0.92 + (sin(phase * 2.1) * 0.08)
        let domeHeight = 118 * clampedLevel * pulse
        let centerPosition = 0.5 + (sin(phase * 0.38) * 0.035)
        let baselineHeight: CGFloat = 1.5
        let sampleCount = 48

        var path = Path()
        for index in 0...sampleCount {
            let progress = CGFloat(index) / CGFloat(sampleCount)
            let xPosition = rect.width * progress
            let distanceFromCenter = abs(progress - centerPosition) / 0.58
            let domeBase = max(
                0,
                cos(min(distanceFromCenter, 1) * .pi / 2)
            )
            let domeCurve = pow(domeBase, 2.2)
            let yPosition = rect.maxY - baselineHeight - (domeHeight * domeCurve)

            if index == 0 {
                path.move(to: CGPoint(x: xPosition, y: yPosition))
            } else {
                path.addLine(to: CGPoint(x: xPosition, y: yPosition))
            }
        }

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private enum TaedamAmbientMetrics {
    static let height: CGFloat = 235
    static let surfaceHeight: CGFloat = 176
}

#Preview("Voice Active") {
    TaedamAmbientBackground(
        normalizedVoiceMotion: 0.82,
        isVoiceActive: true
    )
    .background(.white)
}
