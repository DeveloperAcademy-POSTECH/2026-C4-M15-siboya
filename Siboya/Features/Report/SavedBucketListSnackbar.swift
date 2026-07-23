//
//  SavedPromiseSnackbar.swift
//  Siboya
//
//  Created by Erin Yaebin Kim on 7/21/26.
//

import SwiftUI

struct SavedBucketListSnackbar: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.accent)
                .accessibilityHidden(true)

            Text(message)
                .font(.headline)
                .foregroundStyle(Color.accent)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 64)
        .background(
            Color.background,
            in: RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
        )
        .shadow(
            color: .black.opacity(0.08),
            radius: 12,
            y: 6
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .accessibilityIdentifier("taedam-result-snackbar")
    }
}

#Preview("Snackbar - Dark") {
    ZStack {
        Color.background
            .ignoresSafeArea()

        SavedBucketListSnackbar(
            message: "약속탭에 저장되었어요"
        )
        .padding(24)
    }
    .preferredColorScheme(.dark)
}
