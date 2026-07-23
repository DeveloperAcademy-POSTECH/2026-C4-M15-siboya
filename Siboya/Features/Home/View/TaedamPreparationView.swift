//
//  TaedamPreparationView.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import SwiftUI

/// 태담 시작 전 자세를 안내하고 닫기·시작 동작을 상위 흐름으로 전달하는 bottom sheet입니다.
struct TaedamPreparationView: View {
    /// 안전 영역을 제외한 시스템 최대 detent에서 Figma의 화면 높이 약 87%를 재현하는 비율입니다.
    static let sheetDetentFraction = 0.95

    /// Figma close control이 차지하는 header 높이입니다.
    static let headerHeight: CGFloat = 44

    /// Figma에서 원형 glass 닫기 버튼이 차지하는 실제 외곽 크기입니다.
    static let closeButtonSize: CGFloat = 44

    /// 시스템 glass의 내부 여백과 합쳐 44pt 원을 만드는 SF Symbol container 크기입니다.
    static let closeLabelSize: CGFloat = 36

    /// 닫기 버튼을 sheet 상단과 우측으로부터 동일하게 떨어뜨리는 Figma 여백입니다.
    static let closeButtonInset: CGFloat = 16

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

    /// 권한을 확인하는 동안 시작 버튼의 중복 입력을 막고 처리 상태를 표시합니다.
    let isStarting: Bool

    /// 닫기 버튼을 선택했을 때 sheet 상태를 갱신할 상위 callback입니다.
    let onClose: () -> Void

    /// 시작하기를 선택했을 때 다음 화면 전환을 요청할 상위 callback입니다.
    let onStart: () -> Void

    /// 기존 표시 계약과 테스트가 확인할 태명 치환 안내 문구입니다.
    var instructionText: String {
        TaedamPreparationGuidance(babyNickname: babyNickname).instructionText
    }

    /// 닫기 동작을 상위 흐름으로 전달해 View가 sheet 상태를 직접 소유하지 않게 합니다.
    func close() {
        onClose()
    }

    /// 시작 동작을 상위 흐름으로 전달해 View가 화면 전환 상태를 직접 소유하지 않게 합니다.
    func start() {
        onStart()
    }

    /// 상단 닫기, Figma 위치의 안내 콘텐츠와 하단 시작 버튼을 하나의 sheet에 조립합니다.
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // 닫기 버튼을 overlay로 분리해도 기존 이미지의 세로 시작 위치가 바뀌지 않도록 header 공간을 유지합니다.
                Color.clear
                    .frame(height: Self.headerHeight)
                    .allowsHitTesting(false)

                // Figma의 sheet 상단 좌표를 유지하면서 누락 에셋에는 같은 크기의 대체 박스를 표시합니다.
                TaedamPreparationArtwork(assetName: profileAssetName)
                    .padding(.top, Self.artworkTopSpacing)

                // 제목과 태명 안내를 이미지 아래의 승인된 간격으로 배치합니다.
                TaedamPreparationGuidance(babyNickname: babyNickname)
                    .padding(.top, Self.guidanceTopSpacing)

                // 일반 글자 크기에서는 버튼을 하단에 고정하고 큰 글자에서는 남은 공간이 먼저 줄어들게 합니다.
                Spacer(minLength: 24)

                PrimaryButton(
                    title: "시작하기",
                    isEnabled: !isStarting,
                    isLoading: isStarting,
                    action: start
                )
                .accessibilityIdentifier("TaedamPreparationStartButton")
                .padding(.horizontal, Self.horizontalPadding)
                .padding(.bottom, Self.bottomPadding)
            }

            // 콘텐츠 흐름과 분리해 sheet 상단·우측 16pt 위치를 스크롤이나 글자 크기와 무관하게 고정합니다.
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .frame(
                        width: Self.closeLabelSize,
                        height: Self.closeLabelSize
                    )
                    // symbol container를 정확한 44pt 터치 영역 가운데에 두어 시스템 기본 inset의 크기 변동을 막습니다.
                    .frame(
                        width: Self.closeButtonSize,
                        height: Self.closeButtonSize
                    )
                    // 투명한 여백까지 원형 터치·접근성 영역에 포함해 X glyph만 작은 버튼으로 인식되지 않게 합니다.
                    .contentShape([.interaction, .accessibility], Circle())
            }
            .buttonStyle(.plain)
            // Figma의 원형 Liquid Glass 외곽을 44pt layout bounds에 직접 적용합니다.
            .glassEffect(.regular.interactive(), in: Circle())
            .frame(
                width: Self.closeButtonSize,
                height: Self.closeButtonSize
            )
            .padding(.top, Self.closeButtonInset)
            .padding(.trailing, Self.closeButtonInset)
            .accessibilityLabel("준비자세 닫기")
            .accessibilityIdentifier("TaedamPreparationCloseButton")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
    }
}

// 등록된 프로필 에셋과 안내 문구의 균형을 확인합니다.
#Preview("준비자세") {
    TaedamPreparationView(
        babyNickname: "꾹꾹이",
        isStarting: false,
        onClose: {},
        onStart: {}
    )
    .presentationDetents([.fraction(TaedamPreparationView.sheetDetentFraction)])
}

#Preview("준비자세 - Dark") {
    TaedamPreparationView(
        babyNickname: "꾹꾹이",
        isStarting: false,
        onClose: {},
        onStart: {}
    )
    .preferredColorScheme(.dark)
}
