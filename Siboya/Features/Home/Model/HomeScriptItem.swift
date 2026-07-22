//
//  HomeScriptItem.swift
//  Siboya
//

import Foundation

/// Home 화면 컴포넌트가 태담 대본을 표시하고 선택 결과를 전달하는 데 사용하는 경량 모델입니다.
struct HomeScriptItem: Identifiable, Equatable, Sendable {
    /// 서버 또는 번들 문서에서 대본 자체를 구분하는 고유 식별자입니다.
    let scriptID: UUID

    /// 같은 대본의 수정본을 구분하는 버전 번호입니다.
    let scriptVersion: Int

    /// 카드와 목록 행에 노출할 대본 제목입니다.
    let title: String

    /// 해당 대본을 추천할 임신 주차입니다.
    let targetGestationalWeek: Int

    /// 대표 이미지를 불러올 때 사용하는 Asset Catalog 이름입니다.
    let artworkAssetName: String

    /// 같은 UUID라도 버전이 다르면 SwiftUI가 별도 항목으로 인식하도록 만든 복합 식별자입니다.
    var id: String {
        "\(scriptID.uuidString)-\(scriptVersion)"
    }

    /// 임신 주차를 화면에서 바로 사용할 수 있는 한국어 문자열로 변환합니다.
    var gestationalWeekText: String {
        "\(targetGestationalWeek)주차"
    }
}
