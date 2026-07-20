//
//  TaedamResultHeaderView.swift
//  Siboya
//
//  Created by Erin Yaebin Kim on 7/20/26.
//

import SwiftUI

struct ResultHeaderView: View {
    let week: Int
    let theme: String
    let imageName: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(imageName)
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
            Text("\(week)주차")
                .font(.title3)
                .foregroundStyle(
                    // Color(red: 1.0, green: 0.39, blue: 0.37)
                    Color(.systemRed)
                )
            
            // 태담제목
            Text(theme)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    ResultHeaderView(week: 22, theme: "일요일 아침", imageName: "TitleImage")
}
