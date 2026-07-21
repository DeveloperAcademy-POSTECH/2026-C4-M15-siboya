//
//  TaedamAmbientBackground.swift
//  Siboya
//
//  Created by Codex on 7/21/26.
//

import SwiftUI

struct TaedamAmbientBackground: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                RadialGradient(
                    colors: [
                        Color(red: 0.96, green: 0.32, blue: 0.86).opacity(0.72),
                        .clear
                    ],
                    center: .bottomLeading,
                    startRadius: 0,
                    endRadius: 190
                )

                RadialGradient(
                    colors: [
                        Color(red: 0.24, green: 0.62, blue: 1).opacity(0.72),
                        .clear
                    ],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: 210
                )

                RadialGradient(
                    colors: [
                        Color(red: 0.55, green: 0.34, blue: 1).opacity(0.42),
                        .clear
                    ],
                    center: .bottom,
                    startRadius: 0,
                    endRadius: 150
                )
            }
            .frame(height: 145)
            .blur(radius: 24)
            .mask(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
