# Home Components Design

## 목적

Home(태담 탭) 화면을 구성할 표시 전용 SwiftUI 컴포넌트를 먼저 만든다. 컴포넌트는 Figma의 레이아웃과 스타일을 따르되 제목, 임신 주차, 카테고리와 이미지 이름은 상위 계층이 전달한 값을 표시한다. Asset Catalog에 이미지가 없으면 같은 레이아웃 크기의 중립색 박스를 표시한다.

## 범위

이번 작업은 다음 다섯 타입만 대상으로 한다.

- `HomeArtworkView`: 동적 Asset Catalog 이미지와 박스 fallback
- `HomeRecommendationCard`: 이번 주 추천 대본 카드
- `HomeScriptRow`: 카테고리 안의 개별 대본 행
- `HomeCategorySection`: 카테고리 제목과 대본 행 목록
- `HomeScriptItem`: 위 컴포넌트가 소비하는 표시 전용 값

전체 Home 화면, 데이터 로드, SwiftData 조회, 탭 전환, 미리보기 push, 준비자세 sheet와 권한 처리는 이번 범위에 포함하지 않는다. 이 컴포넌트들이 검증된 다음 단계에서 화면과 흐름을 조립한다.

## 파일 구조

저장소의 구조 원칙에 따라 `Siboya/Features/Home` 아래에 파일을 평평하게 둔다.

```text
Siboya/Features/Home/
├── HomeArtworkView.swift
├── HomeCategorySection.swift
├── HomeRecommendationCard.swift
├── HomeScriptItem.swift
└── HomeScriptRow.swift
```

화면 상태와 로더는 기존 `Model`, `Service` 폴더에 유지한다. 컴포넌트 수가 더 늘어 탐색이 불편해지기 전에는 `Components` 하위 폴더를 만들지 않는다.

## 컴포넌트 계약

### HomeScriptItem

`Identifiable`, `Equatable`, `Sendable`을 따르는 표시 전용 값이다.

```swift
struct HomeScriptItem: Identifiable, Equatable, Sendable {
    let scriptID: UUID
    let scriptVersion: Int
    let title: String
    let targetGestationalWeek: Int
    let artworkAssetName: String

    var id: String {
        "\(scriptID.uuidString)-\(scriptVersion)"
    }
}
```

`scriptID + scriptVersion`을 행 식별자와 선택 callback의 기준으로 사용한다. View는 `ScriptSelectionDTO`가 아직 구현되지 않은 현재 코드에 의존하지 않는다.

### HomeArtworkView

```swift
HomeArtworkView(
    assetName: item.artworkAssetName,
    cornerRadius: 17
)
```

- `UIImage(named:)`로 Asset Catalog 이미지를 확인한다.
- 이미지가 있으면 `Image(uiImage:)`를 `resizable`과 `scaledToFill`로 표시한다.
- 이미지가 없거나 이름이 trim 후 비어 있으면 `secondarySystemBackground` 색상의 `RoundedRectangle`을 표시한다.
- 크기는 자체적으로 고정하지 않고 호출자가 `.frame(width:height:)`로 결정한다.
- 이미지와 fallback 모두 같은 corner radius와 clipping을 적용해 교체 시 레이아웃이 바뀌지 않게 한다.
- 장식 이미지이므로 VoiceOver 탐색에서는 숨긴다.

### HomeRecommendationCard

```swift
HomeRecommendationCard(
    item: item,
    onSelect: { scriptID, scriptVersion in ... }
)
```

- Figma 기준 362×230 비율의 카드이며 화면 폭에 맞게 가로로 확장한다.
- `HomeArtworkView`를 카드 전체에 표시하고 하단에 흰색 방향의 gradient를 겹친다.
- 하단 선두에 대본 제목을 `title3`, semibold로 표시한다.
- 전체 카드를 하나의 `Button`으로 만들어 탭 영역과 접근성 동작을 일치시킨다.
- 탭하면 `scriptID`, `scriptVersion`을 callback으로 전달한다.
- 버튼 스타일은 `.plain`으로 두고 컴포넌트가 Navigation이나 중복 탭 상태를 소유하지 않는다.

### HomeScriptRow

```swift
HomeScriptRow(
    item: item,
    onSelect: { scriptID, scriptVersion in ... }
)
```

- 높이는 80pt로 유지한다.
- 선두에 66×66, corner radius 17의 `HomeArtworkView`를 표시한다.
- 이미지와 텍스트 사이 간격은 9pt다.
- 제목은 `.body`, 대상 주차는 `.footnote`와 secondary 색상으로 표시한다.
- 주차 표기는 `"\(targetGestationalWeek)주차"`로 계산한다.
- 전체 행을 하나의 `Button`으로 만들며 선택 시 ID와 version을 전달한다.
- 목록 경계선은 행 내부에 직접 그리지 않는다. 섹션 조립 단계에서 필요한 구분을 적용한다.

### HomeCategorySection

```swift
HomeCategorySection(
    title: category,
    items: items,
    onSelect: { scriptID, scriptVersion in ... }
)
```

- 카테고리 제목은 `.title3`, semibold로 표시한다.
- 전달받은 `items` 순서를 그대로 유지한다.
- 각 값은 `HomeScriptRow`로 표시하고 선택 callback을 그대로 전달한다.
- 항목 사이에는 `Color(.separator)`를 사용한 hairline 구분선을 텍스트 영역에만 표시한다.
- 빈 배열이면 카테고리 제목과 목록을 모두 표시하지 않는다.
- 자체 `ScrollView`를 만들지 않는다. 상위 Home 화면이 전체 스크롤을 한 번만 소유한다.

## 데이터 흐름

```text
상위 Home 상태
  └─ [HomeScriptItem]
       ├─ HomeRecommendationCard
       └─ HomeCategorySection
            └─ HomeScriptRow

사용자 탭
  └─ (scriptID, scriptVersion)
       └─ 상위 Coordinator 또는 ViewModel
```

컴포넌트는 `BundledHomeWeeklyContentLoader`, `BundledTaedamScriptLoader`, `TaedamRepository`, `ModelContext`와 권한 API를 import하거나 호출하지 않는다.

## Figma와 데이터 우선순위

- 크기, 간격, corner radius, 타이포그래피 역할과 카드 구조는 Figma를 따른다.
- 제목, 대상 주차, 카테고리와 이미지 asset 이름은 JSON에서 만든 주입값을 따른다.
- Figma의 `22주차`를 고정하지 않는다. 현재 JSON 대본은 `20주차`이므로 전달값에 따라 `20주차`를 표시한다.
- Figma의 샘플 제목을 컴포넌트 내부에 하드코딩하지 않는다.

## 이미지 누락 처리

이미지 누락은 데이터 로딩 실패나 오류 화면으로 취급하지 않는다. `UIImage(named:)` 결과가 없으면 박스를 표시하고 나머지 제목, 주차와 선택 동작을 유지한다. 나중에 `Assets.xcassets`에 JSON의 `artworkAssetName`과 같은 이름의 imageset을 추가하면 코드 변경 없이 실제 이미지로 교체된다.

## 접근성

- 추천 카드와 대본 행은 각각 하나의 접근성 버튼으로 노출한다.
- 추천 카드는 대본 제목을 label로 사용한다.
- 대본 행은 제목을 label, `N주차`를 value로 사용한다.
- 장식 이미지는 접근성 트리에서 숨긴다.
- Dynamic Type에 대응하도록 SwiftUI semantic font를 사용하고 제목 줄이 길어져도 잘리지 않게 고정 폭이나 `lineLimit(1)`을 적용하지 않는다.

## 테스트와 검증

- `HomeScriptItem`의 ID가 동일 UUID의 서로 다른 version을 구분하는지 Swift Testing으로 검증한다.
- 주차 표시 문자열을 순수 계산 프로퍼티로 두고 `20주차`, `40주차`를 검증한다.
- 빈 카테고리 배열 표시 정책은 `HomeCategorySection`의 계산된 표시 여부로 검증한다.
- 각 컴포넌트에 실제 이미지와 존재하지 않는 asset 이름을 사용한 `#Preview`를 제공해 이미지와 박스 fallback을 비교한다.
- 집중 단위 테스트, 전체 테스트, SwiftLint와 iOS Simulator 빌드를 실행한다.
- 최종 화면 조립 전이므로 이번 단계에서는 Home UI 테스트나 navigation 테스트를 추가하지 않는다.

## 완료 조건

- 다섯 타입이 `Siboya/Features/Home`에 추가된다.
- 이미지가 있거나 없어도 동일한 프레임과 탭 동작을 유지한다.
- 제목, 주차, 카테고리와 선택 식별자가 하드코딩되지 않는다.
- 새 컴포넌트가 데이터 로더, SwiftData와 Navigation을 직접 알지 않는다.
- 신규 단위 테스트, 전체 테스트, SwiftLint와 Simulator 빌드가 통과한다.
- 기존 `project.pbxproj`의 개인 서명 변경과 사용자가 추가한 Asset Catalog 항목을 수정하거나 함께 커밋하지 않는다.
