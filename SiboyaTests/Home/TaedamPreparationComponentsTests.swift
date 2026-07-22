//
//  TaedamPreparationComponentsTests.swift
//  SiboyaTests
//
//  Created by Codex on 7/23/26.
//

import SwiftUI
import Testing
@testable import Siboya

/// 준비자세를 구성하는 순수 표시 컴포넌트가 Figma 규격과 사용자 동작을 지키는지 검증합니다.
@MainActor
struct TaedamPreparationComponentsTests {
    /// 프로필 이미지가 지정된 에셋 이름과 Figma의 90×88pt 영역을 사용하는지 검증합니다.
    @Test
    func artworkUsesProfileAssetAndFigmaSize() {
        let artwork = TaedamPreparationArtwork()

        #expect(artwork.assetName == "img_profile")
        #expect(TaedamPreparationArtwork.width == 90)
        #expect(TaedamPreparationArtwork.height == 88)
    }

    /// 안내가 태명을 정확히 치환하고 Figma 제목·본문 크기와 8pt 간격을 사용하는지 검증합니다.
    @Test
    func guidanceBuildsNicknameMessageAndFigmaTypography() {
        let guidance = TaedamPreparationGuidance(babyNickname: "꾹꾹이")

        #expect(
            guidance.instructionText
                == "아내의 배에 손을 얹고\n꾹꾹이와 교감할 준비가 되면\n시작 버튼을 눌러주세요"
        )
        #expect(TaedamPreparationGuidance.textSpacing == 8)
        #expect(TaedamPreparationGuidance.titleFontSize == 28)
        #expect(TaedamPreparationGuidance.instructionFontSize == 22)
    }

    /// 시작 버튼이 52pt 높이를 유지하고 로딩 여부에 따라 입력 가능 상태를 계산하는지 검증합니다.
    @Test
    func startButtonUsesFigmaHeightAndLoadingState() {
        let idleButton = TaedamPreparationStartButton(isLoading: false, action: {})
        let loadingButton = TaedamPreparationStartButton(isLoading: true, action: {})

        #expect(TaedamPreparationStartButton.height == 52)
        #expect(idleButton.isEnabled)
        #expect(!loadingButton.isEnabled)
    }

    /// 시작 버튼이 권한 확인을 소유하지 않고 전달받은 callback을 한 번 호출하는지 검증합니다.
    @Test
    func startButtonForwardsActionOnce() {
        var startCount = 0
        let button = TaedamPreparationStartButton(isLoading: false) {
            startCount += 1
        }

        button.start()

        #expect(startCount == 1)
    }
}
