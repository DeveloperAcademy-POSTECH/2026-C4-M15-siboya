//
//  PrimaryBottomButton.swift
//  Siboya
//
//  Created by Erin Yaebin Kim on 7/21/26.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    Text(title)
                        .font(.headline)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 56)
        .foregroundStyle(.white)
        .background(
            isEnabled ? Color.primaryRed : Color.gray.opacity(0.4),
            in: Capsule()
        )
        .disabled(!isEnabled || isLoading)
    }
}

#Preview {
    PrimaryButton(
        title: "완료",
                action: {}
            )
            .padding()
}
