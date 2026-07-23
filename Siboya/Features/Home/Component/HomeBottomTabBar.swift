//
//  HomeBottomTabBar.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import SwiftUI

/// Home 하단에 고정되어 현재 태담 탭과 소원 탭 이동 동작을 제공하는 탭 바입니다.
struct HomeBottomTabBar: View {
    /// Figma에서 탭바 높이의 절반까지 뒤 콘텐츠를 그대로 노출하는 gradient 시작 지점입니다.
    static let backgroundFadeStartY: CGFloat = 0.5

    /// 시스템 배경색 보간이 화면 아래까지 부드럽게 이어지도록 둔 Figma의 gradient 종료 지점입니다.
    static let backgroundFadeEndY: CGFloat = 1.1684

    /// 앱 루트가 관리하는 현재 탭으로 선택 색상과 접근성 상태를 결정합니다.
    let selectedTab: SiboyaTab

    /// 이미 선택된 태담 탭을 다시 눌렀을 때 상위 화면에 알릴 동작입니다.
    let onSelectTaedam: () -> Void

    /// 사용자가 소원 탭을 눌렀을 때 상위 화면에 알릴 동작입니다.
    let onSelectPromise: () -> Void

    /// 스크롤 콘텐츠와 탭 바가 자연스럽게 분리되도록 상단 그라데이션과 캡슐형 버튼을 구성합니다.
    var body: some View {
        HStack(spacing: 0) {
            // 현재 화면인 태담 탭은 선택 배경과 브랜드 대표색으로 강조합니다.
            tabButton(
                title: "태담",
                systemImage: "heart.fill",
                isSelected: selectedTab == .taedam,
                action: selectTaedam
            )

            // 소원 탭은 상위 라우터가 저장된 버킷리스트 화면으로 전환할 수 있도록 콜백을 전달합니다.
            tabButton(
                title: "소원",
                systemImage: "lightbulb.max.fill",
                isSelected: selectedTab == .wish,
                action: selectPromise
            )
        }
        .padding(4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(0.45), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background {
            // 하나의 투명→시스템 배경 gradient를 사용해 상단에서 실제 스크롤 콘텐츠가 비치게 합니다.
            LinearGradient(
                colors: [.clear, Color.background],
                startPoint: UnitPoint(x: 0.5, y: Self.backgroundFadeStartY),
                endPoint: UnitPoint(x: 0.5, y: Self.backgroundFadeEndY)
            )
            // Home의 하단 safe area도 같은 fade로 채워 별도의 단색 띠가 생기지 않게 합니다.
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
        }
    }

    /// 아이콘과 제목을 세로로 묶어 Figma와 같은 너비의 탭 버튼을 만듭니다.
    /// - Parameters:
    ///   - title: 아이콘 아래에 표시하고 VoiceOver가 읽을 탭 이름입니다.
    ///   - systemImage: 탭의 의미를 나타내는 SF Symbol 이름입니다.
    ///   - isSelected: 선택 배경, 강조색과 접근성 선택 특성을 적용할지 나타냅니다.
    ///   - action: 사용자가 버튼을 눌렀을 때 실행할 상위 콜백입니다.
    /// - Returns: 94pt 너비와 48pt 높이를 최소로 유지하고 Dynamic Type에 맞춰 확장되는 탭 버튼입니다.
    private func tabButton(
        title: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))

                Text(title)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(
                isSelected ? Color.brandPrimary : Color.textPrimary
            )
            .frame(minWidth: 94, minHeight: 48)
            .background {
                if isSelected {
                    // 현재 탭의 전체 터치 영역을 부드러운 캡슐로 표시해 선택 상태를 분명히 합니다.
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// 태담 버튼 선택을 View 내부 상태로 처리하지 않고 상위 조정자에게 그대로 전달합니다.
    func selectTaedam() {
        onSelectTaedam()
    }

    /// 소원 버튼 선택을 상위 조정자에게 전달해 탭 전환 구현과 분리합니다.
    func selectPromise() {
        onSelectPromise()
    }
}

// 태담 탭 선택 상태와 캡슐형 하단 배치를 독립적으로 확인합니다.
#Preview("Home bottom tab bar") {
    VStack {
        Spacer()
        HomeBottomTabBar(
            selectedTab: .taedam,
            onSelectTaedam: {},
            onSelectPromise: {}
        )
    }
}

// 접근성 글자 크기에서 48pt 최소 터치 높이를 지키면서 탭 내용이 잘리지 않는지 확인합니다.
#Preview("Home bottom tab bar with accessibility text") {
    VStack {
        Spacer()
        HomeBottomTabBar(
            selectedTab: .wish,
            onSelectTaedam: {},
            onSelectPromise: {}
        )
    }
    .environment(\.dynamicTypeSize, .accessibility5)
}
