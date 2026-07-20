//
//  TaedamResultViewModel.swift
//  Siboya
//
//  Created by Erin Yaebin Kim on 7/21/26.
//

import SwiftUI
import Observation

@MainActor
@Observable

final class TaedamResultViewModel {
    let result: TaedamResultData

    var isToastPresented = false

    private var hasShownSavedToast = false

    init(result: TaedamResultData) {
        self.result = result
    }

    func showSavedToastIfNeeded() async {
        // 화면 재계산이나 뒤로 갔다 돌아왔을 때
        // 토스트가 반복 노출되는 것을 방지
        guard !hasShownSavedToast else { return }

        hasShownSavedToast = true

        withAnimation(.easeOut(duration: 0.25)) {
            isToastPresented = true
        }

        // VoiceOver 사용자에게도 저장 완료 사실 전달
        AccessibilityNotification
            .Announcement("리스트는 약속 탭에 저장되었어요")
            .post()
        
        // 이 부분은 지워도 될지도?
        do {
            try await Task.sleep(for: .seconds(2))
        } catch {
            // 화면이 사라져 Task가 취소된 경우
            return
        }

        guard !Task.isCancelled else { return }

        withAnimation(.easeIn(duration: 0.2)) {
            isToastPresented = false
        }
    }
}
