//
//  TaedamPreparationView.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import SwiftUI

/// 태담 시작 전 자세를 안내하고 닫기·권한 확인 동작을 상위 흐름으로 전달하는 bottom sheet입니다.
struct TaedamPreparationView: View {
    /// 안전 영역을 제외한 시스템 최대 detent에서 Figma의 화면 높이 약 87%를 재현하는 비율입니다.
    static let sheetDetentFraction = 0.95

    /// Figma close control이 차지하는 header 높이입니다.
    static let headerHeight: CGFloat = 44

    /// 시스템 glass 여백을 포함했을 때 닫기 control 외곽이 약 44pt가 되게 하는 label 크기입니다.
    static let closeLabelSize: CGFloat = 22

    /// Header 아래에서 프로필 이미지까지 확보할 세로 간격입니다.
    static let artworkTopSpacing: CGFloat = 52

    /// 프로필 이미지와 안내 제목 사이의 Figma 기준 간격입니다.
    static let guidanceTopSpacing: CGFloat = 67

    /// 시작 버튼이 화면 양쪽에서 유지할 여백입니다.
    static let horizontalPadding: CGFloat = 20

    /// 시작 버튼과 sheet 하단 사이의 Figma 기준 여백입니다.
    static let bottomPadding: CGFloat = 22

    /// 기존 테스트와 외부 표시 계약이 확인할 기본 프로필 에셋 이름입니다.
    let profileAssetName = TaedamPreparationArtwork.defaultAssetName

    /// 안내 컴포넌트에 전달할 사용자 태명입니다.
    let babyNickname: String

    /// 권한 요청 중 시작 버튼의 중복 입력을 막을 상태입니다.
    let isRequestingPermission: Bool

    /// 닫기 버튼을 선택했을 때 sheet 상태를 갱신할 상위 callback입니다.
    let onClose: () -> Void

    /// 시작하기를 선택했을 때 권한 확인을 요청할 상위 callback입니다.
    let onStart: () -> Void

    /// 기존 표시 계약과 테스트가 확인할 태명 치환 안내 문구입니다.
    var instructionText: String {
        TaedamPreparationGuidance(babyNickname: babyNickname).instructionText
    }

    /// 닫기 동작을 상위 흐름으로 전달해 View가 sheet 상태를 직접 소유하지 않게 합니다.
    func close() {
        onClose()
    }

    /// 시작 동작을 상위 흐름으로 전달해 View가 권한 API를 직접 호출하지 않게 합니다.
    func start() {
        onStart()
    }

    /// 상단 닫기, Figma 위치의 안내 콘텐츠와 하단 시작 버튼을 하나의 sheet에 조립합니다.
    var body: some View {
        VStack(spacing: 0) {
            // 시스템 grabber 아래에 iOS 26 glass 닫기 버튼을 오른쪽 정렬합니다.
            HStack {
                Spacer()

                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .medium))
                        .frame(
                            width: Self.closeLabelSize,
                            height: Self.closeLabelSize
                        )
                }
                .buttonStyle(.glass)
                .frame(width: 44, height: 44)
                .accessibilityLabel("준비자세 닫기")
                .accessibilityIdentifier("TaedamPreparationCloseButton")
            }
            .frame(height: Self.headerHeight)
            .padding(.horizontal, 16)

            // Figma의 sheet 상단 좌표를 유지하면서 누락 에셋에는 같은 크기의 대체 박스를 표시합니다.
            TaedamPreparationArtwork(assetName: profileAssetName)
                .padding(.top, Self.artworkTopSpacing)

            // 제목과 태명 안내를 이미지 아래의 승인된 간격으로 배치합니다.
            TaedamPreparationGuidance(babyNickname: babyNickname)
                .padding(.top, Self.guidanceTopSpacing)

            // 일반 글자 크기에서는 버튼을 하단에 고정하고 큰 글자에서는 남은 공간이 먼저 줄어들게 합니다.
            Spacer(minLength: 24)

            TaedamPreparationStartButton(
                isLoading: isRequestingPermission,
                action: start
            )
            .padding(.horizontal, Self.horizontalPadding)
            .padding(.bottom, Self.bottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// 등록된 프로필 에셋과 안내 문구의 균형을 확인합니다.
#Preview("준비자세") {
    TaedamPreparationView(
        babyNickname: "꾹꾹이",
        isRequestingPermission: false,
        onClose: {},
        onStart: {}
    )
    .presentationDetents([.fraction(TaedamPreparationView.sheetDetentFraction)])
}
