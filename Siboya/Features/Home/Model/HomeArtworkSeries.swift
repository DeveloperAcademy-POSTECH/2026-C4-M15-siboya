//
//  HomeArtworkSeries.swift
//  Siboya
//
//  Created by Codex on 7/22/26.
//

import Foundation

/// Home에 등록된 일곱 개 이미지 묶음을 표현하고 표시 위치에 맞는 에셋 이름을 만드는 모델입니다.
enum HomeArtworkSeries: Int, CaseIterable, Equatable, Sendable {
    /// 첫 번째 `TitleImage` 이미지 묶음입니다.
    case one = 1

    /// 두 번째 `TitleImage` 이미지 묶음입니다.
    case two

    /// 세 번째 `TitleImage` 이미지 묶음입니다.
    case three

    /// 네 번째 `TitleImage` 이미지 묶음입니다.
    case four

    /// 다섯 번째 `TitleImage` 이미지 묶음입니다.
    case five

    /// 여섯 번째 `TitleImage` 이미지 묶음입니다.
    case six

    /// 일곱 번째 `TitleImage` 이미지 묶음입니다.
    case seven

    /// 66×66 대본 행에서 사용할 원본 크기 에셋 이름입니다.
    var rowAssetName: String {
        "TitleImage\(rawValue)"
    }

    /// 230pt 추천 카드에서 사용할 카드 전용 에셋 이름입니다.
    var cardAssetName: String {
        "TitleImage\(rawValue)Card"
    }

    /// 배열의 0부터 시작하는 순서를 일곱 시리즈에 반복 배정해 데이터 수가 달라도 같은 규칙을 유지합니다.
    /// - Parameter index: JSON 배열에서 `enumerated()`로 얻은 0부터 시작하는 위치입니다.
    /// - Returns: 여덟 번째 위치부터 다시 첫 번째로 순환한 이미지 시리즈입니다.
    static func cycling(forZeroBasedIndex index: Int) -> HomeArtworkSeries {
        // 음수는 JSON 배열 위치가 될 수 없으므로 잘못된 호출을 개발 단계에서 바로 발견합니다.
        precondition(index >= 0, "Home 이미지 순서는 0 이상이어야 합니다.")

        let wrappedIndex = index % allCases.count
        return allCases[wrappedIndex]
    }
}
