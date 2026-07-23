//
//  HomeView.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import SwiftUI

/// 전달받은 표시 상태로 태명, 이번 주 추천과 카테고리별 대본을 그리는 순수 Home 화면입니다.
struct HomeView: View {
    /// 저장소와 번들 모델에서 변환된 Home 표시 전용 상태입니다.
    let state: HomeViewState

    /// 추천 카드 또는 대본 행 선택 시 UUID와 버전을 상위 화면에 전달하는 동작입니다.
    let onSelectScript: (UUID, Int) -> Void

    /// 표시 상태와 선택 콜백을 주입하되 미연결 화면에서도 빈 동작으로 안전하게 미리 볼 수 있게 합니다.
    /// - Parameters:
    ///   - state: Home이 표시할 태명, 추천과 카테고리 목록입니다.
    ///   - onSelectScript: 대본 UUID와 버전을 미리보기 흐름에 전달할 콜백입니다.
    init(
        state: HomeViewState,
        onSelectScript: @escaping (UUID, Int) -> Void = { _, _ in }
    ) {
        self.state = state
        self.onSelectScript = onSelectScript
    }

    /// 하나의 세로 스크롤 안에 모든 Home 콘텐츠를 두고 탭 바만 safe area에 고정합니다.
    var body: some View {
        ZStack {
            // 라이트 모드에서는 Figma의 밝은 배경을 유지하고 다크 모드에서는 텍스트 대비를 함께 보존합니다.
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if let babyNickname = state.babyNickname {
                        // SwiftData에서 읽은 태명을 Home의 가장 높은 정보 계층으로 표시합니다.
                        Text(babyNickname)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.primary)
                            .accessibilityAddTraits(.isHeader)
                    }

                    if let recommendation = state.recommendation {
                        // 프로필, 현재 주차와 추천 대본 연결이 모두 성공한 경우에만 추천 영역을 표시합니다.
                        recommendationSection(recommendation)
                            .padding(.top, state.babyNickname == nil ? 0 : 20)
                    }

                    if !state.categories.isEmpty {
                        // 추천 데이터와 무관하게 정상 대본이 있으면 카테고리 탐색 목록을 계속 제공합니다.
                        categorySections
                            .padding(.top, categoryTopSpacing)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
    }

    /// 추천 또는 태명 영역의 존재 여부에 따라 첫 카테고리가 자연스럽게 이어질 상단 간격을 계산합니다.
    private var categoryTopSpacing: CGFloat {
        if state.recommendation != nil {
            // Figma에서 추천 카드와 첫 카테고리 제목 사이의 시각적 구분을 유지합니다.
            return 32
        }

        // 추천이 없을 때 태명이 있으면 제목과 목록을 분리하고, 완전 빈 상단이면 최소 여백만 둡니다.
        return state.babyNickname == nil ? 8 : 28
    }

    /// `이번주 추천`, 주차별 headline과 고정 높이 카드를 하나의 강조 영역으로 구성합니다.
    /// - Parameter recommendation: 같은 주차에서 연결된 headline과 대본 카드 상태입니다.
    /// - Returns: Figma의 텍스트 계층과 12pt 카드 간격을 반영한 추천 영역입니다.
    private func recommendationSection(
        _ recommendation: HomeRecommendationState
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("이번주 추천")
                .font(.body)
                .foregroundStyle(Color("PrimaryRed"))

            Text(recommendation.headline)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.primary)
                .fixedSize(horizontal: false, vertical: true)

            HomeRecommendationCard(
                item: recommendation.item,
                onSelect: onSelectScript
            )
            .padding(.top, 12)
        }
    }

    /// 상태에 저장된 카테고리 순서를 유지하며 각 섹션 사이에 24pt 간격을 둡니다.
    private var categorySections: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(state.categories) { category in
                HomeCategorySection(
                    title: category.title,
                    items: category.items,
                    onSelect: onSelectScript
                )
            }
        }
    }
}

private extension HomeViewState {
    /// 실제 번들 데이터와 22주 프로필로 구성해 전체 Home 레이아웃을 확인하는 미리보기 상태입니다.
    static var preview: HomeViewState {
        HomeViewStateBuilder.make(
            babyNickname: "꾹꾹이",
            gestationalWeek: 22,
            weeklyDocument: try? BundledHomeWeeklyContentLoader.load(),
            scriptDocument: try? BundledTaedamScriptLoader.load()
        )
    }
}

// 실제 22주 추천과 여섯 대본이 Figma 계층대로 배치되는지 확인합니다.
#Preview("Loaded Home") {
    HomeView(state: .preview)
}

// 모든 데이터가 없어도 배경과 하단 탭 구조가 유지되는지 확인합니다.
#Preview("Empty Home") {
    HomeView(state: .empty)
}

// 시스템 배경색과 semantic 텍스트가 다크 모드에서도 충분한 대비를 유지하는지 확인합니다.
#Preview("Loaded Home in dark mode") {
    HomeView(state: .preview)
        .preferredColorScheme(.dark)
}
