//
//  TaedamPreparationView.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import SwiftUI
import UIKit

/// 태담을 시작하기 전 사용자의 준비를 안내하고 권한 요청 동작만 상위 흐름에 전달하는 바텀 시트입니다.
struct TaedamPreparationView: View {
    /// 등록된 프로필 이미지를 찾을 Asset Catalog 이름입니다.
    let profileAssetName = "img_profile"

    /// 실제 사용자 태명을 포함해 표시할 준비 안내 문구입니다.
    let instructionText: String

    /// 권한 시스템 알림을 기다리는 동안 중복 시작을 막기 위한 표시 상태입니다.
    let isRequestingPermission: Bool

    /// 닫기 버튼이 선택됐을 때 시트를 닫도록 상위 흐름에 전달할 동작입니다.
    let onClose: () -> Void

    /// 시작하기 버튼이 선택됐을 때 권한 확인을 요청하도록 상위 흐름에 전달할 동작입니다.
    let onStart: () -> Void

    /// 태명과 화면 상태·사용자 동작을 받아 준비자세 전용 표시 값을 만듭니다.
    /// - Parameters:
    ///   - babyNickname: 안내 문구에 주입할 태명입니다.
    ///   - isRequestingPermission: 권한 요청이 진행 중인지 나타내는 값입니다.
    ///   - onClose: 시트를 닫을 때 실행할 동작입니다.
    ///   - onStart: 권한 확인을 시작할 때 실행할 동작입니다.
    init(
        babyNickname: String,
        isRequestingPermission: Bool,
        onClose: @escaping () -> Void,
        onStart: @escaping () -> Void
    ) {
        // 전달받은 태명을 한 번만 조합해 View 갱신 시에도 안내 문구가 항상 같은 의미를 유지하게 합니다.
        instructionText = "아내의 배에 손을 얹고\n\(babyNickname)와 교감할 준비가 되면\n시작 버튼을 눌러주세요"
        self.isRequestingPermission = isRequestingPermission
        self.onClose = onClose
        self.onStart = onStart
    }

    /// 프로필 에셋이 번들에 존재하는 경우에만 실제 이미지를 표시하기 위한 조회 결과입니다.
    private var profileImage: UIImage? {
        UIImage(named: profileAssetName)
    }

    /// 상단 닫기, 중앙 안내, 하단 시작 버튼을 분리해 Figma의 세로 정보 흐름을 유지합니다.
    var body: some View {
        VStack(spacing: 0) {
            // 닫기 버튼을 우측 상단에 독립 배치해 화면을 닫을 수 있음을 빠르게 찾게 합니다.
            HStack {
                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .frame(width: 44, height: 44)
                        .background(Color(.secondarySystemBackground), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("준비자세 닫기")
            }
            .padding(.top, 12)
            .padding(.horizontal, 20)

            // 프로필 에셋이 없더라도 132pt 영역을 유지해 나머지 안내 요소가 움직이지 않게 합니다.
            profileArtwork
                .frame(width: 132, height: 132)
                .padding(.top, 24)

            // 제목과 태명 안내를 중앙에 두어 시작 전에 필요한 행동을 차례로 읽게 합니다.
            Text("태담 준비하기")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.primary)
                .padding(.top, 24)

            Text(instructionText)
                .font(.body)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)
                .padding(.horizontal, 32)

            Spacer(minLength: 24)

            // 권한 요청 중에는 기존 공통 버튼의 비활성·로딩 표현을 사용해 중복 시스템 알림을 예방합니다.
            PrimaryButton(
                title: "시작하기",
                isEnabled: !isRequestingPermission,
                isLoading: isRequestingPermission,
                action: onStart
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    /// 에셋 존재 여부에 따라 실제 프로필 또는 중립색의 같은 크기 플레이스홀더를 만듭니다.
    @ViewBuilder
    private var profileArtwork: some View {
        if let profileImage {
            // 실제 에셋은 비율을 유지하며 132×132 프레임 안에 맞춰 장식용으로 표시합니다.
            Image(uiImage: profileImage)
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
        } else {
            // 개발 중 에셋이 누락돼도 Figma 기준 공간과 버튼 위치를 보존하기 위해 박스로 대체합니다.
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .accessibilityHidden(true)
        }
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
    .presentationDetents([.fraction(0.87)])
}
