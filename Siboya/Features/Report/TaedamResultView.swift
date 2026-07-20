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
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            Image("Taedam-BG")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea(edges: .all)
                .opacity(0.38)
            
            ScrollView {
                VStack(spacing: 0) {
                    ResultHeaderView(
                        // viewModel.result.week/question/imageName으로 수정하기
                        week: 22,
                        question: "일요일 아침",
                        imageName: imageName)
                }
                .padding(.top, 36)
            }
        }
    }
}

#Preview {
    TaedamResultView(
        week: 22,
        question: "일요일 아침",
        imageName: "TitleImage"
    )
}
