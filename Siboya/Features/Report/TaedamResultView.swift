//
//  TaedamResultView.swift
//  Siboya
//
//  Created by Erin Yaebin Kim on 7/20/26.
//

import SwiftUI

struct TaedamResultView: View {
    let week: Int
    let question: String
    let imageName: String
    
    var body: some View {
        ZStack{
            Image("Taedam-BG")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea(edges: .all)
                .opacity(0.38)
            //HeaderContents
            //Image
            VStack(spacing: 12) {
                Image("TitleImage")
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
               //주차별
                Text("\(week)주차")
                    .font(.title3)
                    .foregroundStyle(
                        Color(red: 1.0, green: 0.39, blue: 0.37)
                    )
                //태담제목
                Text(question)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    TaedamResultView(week: 22, question: "일요일 아침", imageName: "TitleImage")
}
