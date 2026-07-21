//
//  TaedamResultHeaderView.swift
//  Siboya
//
//  Created by Erin Yaebin Kim on 7/20/26.
//

import SwiftUI

struct ResultHeaderContent: Equatable {
    let targetGestationalWeek: Int
    let title: String
    let artworkAssetName: String
}

struct ResultHeaderView: View {
    let content: ResultHeaderContent
    
    var body: some View {
        VStack(spacing: 12) {
            Image(content.artworkAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: 144, height: 144)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 32,
                        style: .continuous
                    )
                )
                .accessibilityHidden(true)
            
            // 주차별
            Text("\(content.targetGestationalWeek)주차")
                .font(.title3)
                .foregroundStyle(
                    // Color(red: 1.0, green: 0.39, blue: 0.37)
                    Color(.systemRed)
                )
            
            // 태담제목
            Text(content.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    ResultHeaderView(
        content: ResultHeaderContent(
            targetGestationalWeek: 22,
            title: "일요일 아침 냄새",
            artworkAssetName: "TitleImage"
        )
    )
}
