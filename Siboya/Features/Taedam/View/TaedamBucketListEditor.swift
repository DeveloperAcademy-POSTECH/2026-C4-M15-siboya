//
//  TaedamBucketListEditor.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import SwiftUI

/// STT가 끝난 버킷리스트 문장을 키보드로 수정하는 카드형 입력 영역입니다.
struct TaedamBucketListEditor: View {
    @Binding private var text: String

    private let placeholder: String
    private let focus: FocusState<Bool>.Binding

    init(
        text: Binding<String>,
        placeholder: String,
        focus: FocusState<Bool>.Binding
    ) {
        _text = text
        self.placeholder = placeholder
        self.focus = focus
    }

    var body: some View {
        TextField(
            placeholder,
            text: $text,
            axis: .vertical
        )
        .taedamScriptTextStyle()
        .foregroundStyle(Color.textPrimary)
        .lineLimit(3...7)
        .textFieldStyle(.plain)
        .focused(focus)
        .accessibilityLabel("버킷리스트 수정")
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .background(
            Color.background,
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.textPrimary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 16, y: 6)
        .task {
            // 컨테이너와 외부 ScrollView의 배치가 끝난 뒤 키보드를 표시합니다.
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled,
                  !focus.wrappedValue else {
                return
            }
            focus.wrappedValue = true
        }
    }
}
