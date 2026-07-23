//
//  TaedamToolbarBackground.swift
//  Siboya
//
//  Created by Codex on 7/21/26.
//

import SwiftUI

struct TaedamToolbarBackground: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black.opacity(0.92), location: 0.48),
                        .init(color: .black.opacity(0.45), location: 0.76),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(height: 104)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
    }
}

#Preview {
    ZStack(alignment: .top) {
        VStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { index in
                Text("태담 대본 문장 \(index + 1)")
                    .font(.title2.bold())
            }
        }

        TaedamToolbarBackground()
    }
}
