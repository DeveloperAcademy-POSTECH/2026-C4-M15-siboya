# Script Preview Components Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Figma와 SSD 규격에 맞는 대본 미리보기 Hero, 소요시간, 본문, 하단 버튼 컴포넌트를 구현하고 Home과 공유하는 이미지 로직을 대본 도메인으로 일반화한다.

**Architecture:** `ScriptArtworkSeries`가 1~7번 에셋 이름을 역할별로 계산하고 `ScriptArtworkView`가 이미지 또는 플레이스홀더를 렌더링한다. 네 미리보기 컴포넌트는 순수 표시 값과 callback만 받아 데이터 조회, 화면 이동, 준비자세 모달과 권한 처리로부터 분리한다.

**Tech Stack:** Swift 5, SwiftUI, UIKit `UIImage`, Swift Testing, Xcode 26.5, iOS 26.5 Simulator, SwiftLint 0.65.0

## Global Constraints

- `TitleImage1~7Thumbnail`을 132×132pt 대표 이미지로 사용한다.
- `TitleImage1~7Back`을 상단 배경으로 사용한다.
- 생각힌트 앞뒤에 컬러 `💡` 이모지를 유지한다.
- 소요 초는 60초 단위로 올림하고 `nil`이면 영역을 숨긴다.
- 본문은 전달받은 문장 배열 순서를 재정렬하지 않는다.
- 하단 바는 기존 `PrimaryButton`과 callback만 사용한다.
- 신규·수정 Swift 코드와 테스트에는 역할과 처리 이유를 설명하는 한국어 주석을 작성한다.
- 사용자 변경인 `Siboya.xcodeproj/project.pbxproj`와 `img_profile.imageset`은 수정하거나 작업 커밋에 포함하지 않는다.
- 파일 시스템 동기화 그룹을 사용하므로 새 Swift 파일을 위해 `project.pbxproj`를 수정하지 않는다.

---

### Task 1: 대본 공통 이미지 시리즈 모델

**Files:**
- Create: `Siboya/Features/Home/Model/ScriptArtworkSeries.swift`
- Delete: `Siboya/Features/Home/Model/HomeArtworkSeries.swift`
- Modify: `Siboya/Features/Home/Model/HomeScriptItem.swift`
- Modify: `Siboya/Features/Home/Model/HomeViewState.swift`
- Modify: `SiboyaTests/Home/HomeComponentsTests.swift`

**Interfaces:**
- Consumes: Home JSON 배열의 0부터 시작하는 위치
- Produces: `ScriptArtworkSeries.cycling(forZeroBasedIndex:)`와 네 역할별 asset name

- [ ] **Step 1: 공통 이름과 네 에셋 역할을 요구하는 실패 테스트 작성**

```swift
/// 첫 번째 이미지 시리즈가 네 표시 위치에 맞는 에셋 이름을 만드는지 검증합니다.
@Test
func firstArtworkSeriesBuildsRoleSpecificAssetNames() {
    let series = ScriptArtworkSeries.cycling(forZeroBasedIndex: 0)
    #expect(series.rowAssetName == "TitleImage1")
    #expect(series.cardAssetName == "TitleImage1Card")
    #expect(series.thumbnailAssetName == "TitleImage1Thumbnail")
    #expect(series.backgroundAssetName == "TitleImage1Back")
}

/// 일곱 번째 뒤의 항목이 다시 첫 번째 이미지 묶음으로 순환하는지 검증합니다.
@Test
func artworkSeriesCyclesAfterSeventhItem() {
    let seventh = ScriptArtworkSeries.cycling(forZeroBasedIndex: 6)
    let eighth = ScriptArtworkSeries.cycling(forZeroBasedIndex: 7)
    #expect(seventh.rowAssetName == "TitleImage7")
    #expect(seventh.cardAssetName == "TitleImage7Card")
    #expect(seventh.thumbnailAssetName == "TitleImage7Thumbnail")
    #expect(seventh.backgroundAssetName == "TitleImage7Back")
    #expect(eighth == .one)
}
```

- [ ] **Step 2: `ScriptArtworkSeries` 부재로 테스트 실패 확인**

Run: `xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:SiboyaTests/HomeComponentsTests`

Expected: FAIL with `cannot find 'ScriptArtworkSeries' in scope`.

- [ ] **Step 3: 공통 이미지 모델을 구현하고 Home 타입 교체**

```swift
import Foundation

/// 대본에 등록된 일곱 개 이미지 묶음을 표현하고 표시 위치별 에셋 이름을 만드는 모델입니다.
enum ScriptArtworkSeries: Int, CaseIterable, Equatable, Sendable {
    /// 첫 번째부터 일곱 번째까지의 `TitleImage` 이미지 묶음입니다.
    case one = 1, two, three, four, five, six, seven

    /// Home 대본 행에서 사용할 원본 에셋 이름입니다.
    var rowAssetName: String { "TitleImage\(rawValue)" }

    /// Home 추천 카드에서 사용할 카드 전용 에셋 이름입니다.
    var cardAssetName: String { "TitleImage\(rawValue)Card" }

    /// 미리보기 132pt 대표 이미지에 사용할 에셋 이름입니다.
    var thumbnailAssetName: String { "TitleImage\(rawValue)Thumbnail" }

    /// 미리보기 상단 배경에 사용할 에셋 이름입니다.
    var backgroundAssetName: String { "TitleImage\(rawValue)Back" }

    /// 배열 위치를 일곱 시리즈에 반복 배정합니다.
    /// - Parameter index: JSON 배열에서 얻은 0부터 시작하는 위치입니다.
    /// - Returns: 여덟 번째부터 다시 첫 번째로 순환한 시리즈입니다.
    static func cycling(forZeroBasedIndex index: Int) -> ScriptArtworkSeries {
        // 음수는 배열 위치가 아니므로 개발 단계에서 잘못된 연결을 즉시 찾습니다.
        precondition(index >= 0, "대본 이미지 순서는 0 이상이어야 합니다.")
        return allCases[index % allCases.count]
    }
}
```

`HomeScriptItem.artworkSeries`와 `HomeViewState.makeItem` 매개변수를 `ScriptArtworkSeries`로 바꾸고 관련 주석을 대본 공통 표현으로 갱신한다.

- [ ] **Step 4: Home 집중 테스트 통과 확인**

Run: Step 2와 동일. Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 5: 모델 변경 커밋**

```bash
git add Siboya/Features/Home/Model/ScriptArtworkSeries.swift Siboya/Features/Home/Model/HomeArtworkSeries.swift Siboya/Features/Home/Model/HomeScriptItem.swift Siboya/Features/Home/Model/HomeViewState.swift SiboyaTests/Home/HomeComponentsTests.swift
git commit -m "refactor: 대본 이미지 시리즈를 공통 모델로 변경"
```

### Task 2: 대본 공통 이미지 표시 뷰

**Files:**
- Create: `Siboya/Features/Home/Component/ScriptArtworkView.swift`
- Delete: `Siboya/Features/Home/Component/HomeArtworkView.swift`
- Modify: `Siboya/Features/Home/Component/HomeRecommendationCard.swift`
- Modify: `Siboya/Features/Home/Component/HomeScriptRow.swift`
- Modify: `SiboyaTests/Home/HomeComponentsTests.swift`

**Interfaces:**
- Consumes: `assetName: String`, `cornerRadius: CGFloat`
- Produces: 실제 에셋 이미지 또는 동일 프레임의 중립색 박스

- [ ] **Step 1: 기존 이미지 테스트를 `ScriptArtworkView`로 바꿔 실패 확인**

```swift
/// 공백 이름으로 이미지 조회를 시도하지 않는지 검증합니다.
@Test @MainActor
func artworkIgnoresBlankAssetName() {
    let artwork = ScriptArtworkView(assetName: "  \n", cornerRadius: 17)
    #expect(artwork.resolvedAssetName == nil)
    #expect(artwork.resolvedImage == nil)
}
```

Run: Task 1 Step 2 명령. Expected: FAIL with `cannot find 'ScriptArtworkView' in scope`.

- [ ] **Step 2: 공통 이미지 뷰 구현**

```swift
import SwiftUI
import UIKit

/// Asset Catalog 이미지를 표시하고 찾지 못하면 같은 영역을 박스로 유지하는 대본 공통 뷰입니다.
struct ScriptArtworkView: View {
    /// Asset Catalog에서 조회할 이미지 이름입니다.
    let assetName: String

    /// 실제 이미지와 플레이스홀더에 동일하게 적용할 모서리 반경입니다.
    let cornerRadius: CGFloat

    /// 공백 이름을 제거한 유효한 에셋 이름입니다.
    var resolvedAssetName: String? {
        let name = assetName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }

    /// 등록된 UIImage이며 이름이 없거나 에셋이 누락됐으면 `nil`입니다.
    var resolvedImage: UIImage? {
        guard let resolvedAssetName else { return nil }
        return UIImage(named: resolvedAssetName)
    }

    /// 실제 이미지 또는 레이아웃을 유지하는 중립색 박스를 표시합니다.
    var body: some View {
        Group {
            if let resolvedImage {
                Image(uiImage: resolvedImage).resizable().scaledToFill()
            } else {
                // 에셋이 준비되지 않아도 주변 레이아웃이 흔들리지 않도록 박스를 유지합니다.
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityHidden(true)
    }
}
```

`HomeRecommendationCard`와 `HomeScriptRow`, 관련 테스트와 Preview의 타입 이름을 `ScriptArtworkView`로 바꾼다. 등록 이미지와 누락 이미지 Preview를 새 파일에 유지한다.

- [ ] **Step 3: Home 집중 테스트 통과 확인**

Run: Task 1 Step 2 명령. Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 4: 공통 뷰 변경 커밋**

```bash
git add Siboya/Features/Home/Component/ScriptArtworkView.swift Siboya/Features/Home/Component/HomeArtworkView.swift Siboya/Features/Home/Component/HomeRecommendationCard.swift Siboya/Features/Home/Component/HomeScriptRow.swift SiboyaTests/Home/HomeComponentsTests.swift
git commit -m "refactor: 대본 이미지 뷰를 공통 컴포넌트로 변경"
```

### Task 3: 소요시간과 Hero 컴포넌트

**Files:**
- Create: `Siboya/Features/Home/Component/ScriptPreviewDuration.swift`
- Create: `Siboya/Features/Home/Component/ScriptPreviewHero.swift`
- Create: `SiboyaTests/Home/ScriptPreviewComponentsTests.swift`

**Interfaces:**
- Consumes: `estimatedDurationSeconds`, `ScriptArtworkSeries`, 임신 주차, 제목
- Produces: 선택적 `durationText`, Back 배경과 132pt Thumbnail을 가진 Hero

- [ ] **Step 1: 소요시간 올림, nil 숨김과 Hero 규격 실패 테스트 작성**

```swift
import SwiftUI
import Testing
@testable import Siboya

/// 대본 미리보기 컴포넌트의 표시 값과 동작 계약을 검증합니다.
struct ScriptPreviewComponentsTests {
    /// 초가 분 단위로 올림되고 값이 없으면 문자열도 없는지 검증합니다.
    @Test @MainActor
    func durationBuildsOptionalRoundedMinuteText() {
        #expect(ScriptPreviewDuration(estimatedDurationSeconds: 35).durationText == "약 1분")
        #expect(ScriptPreviewDuration(estimatedDurationSeconds: 60).durationText == "약 1분")
        #expect(ScriptPreviewDuration(estimatedDurationSeconds: 61).durationText == "약 2분")
        #expect(ScriptPreviewDuration(estimatedDurationSeconds: nil).durationText == nil)
    }

    /// Hero가 주차 문구와 Figma Thumbnail 규격을 유지하는지 검증합니다.
    @Test @MainActor
    func heroBuildsWeekTextAndThumbnailMetrics() {
        let hero = ScriptPreviewHero(artworkSeries: .three, targetGestationalWeek: 22, title: "일요일 아침 냄새")
        #expect(hero.weekText == "22주차")
        #expect(ScriptPreviewHero.thumbnailSize == 132)
        #expect(ScriptPreviewHero.thumbnailCornerRadius == 32)
    }
}
```

- [ ] **Step 2: 새 컴포넌트 부재로 테스트 실패 확인**

Run: `xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:SiboyaTests/ScriptPreviewComponentsTests`

Expected: FAIL with missing `ScriptPreviewDuration` and `ScriptPreviewHero`.

- [ ] **Step 3: 소요시간 컴포넌트 구현**

```swift
import SwiftUI

/// 예상 소요 초를 사용자가 읽기 쉬운 분 단위로 보여주는 미리보기 컴포넌트입니다.
struct ScriptPreviewDuration: View {
    /// 번들 대본이 제공하는 선택적 예상 소요 시간입니다.
    let estimatedDurationSeconds: Int?

    /// 초를 60초 단위로 올림한 문자열이며 값이 없으면 영역을 숨깁니다.
    var durationText: String? {
        guard let seconds = estimatedDurationSeconds else { return nil }
        // 나머지가 있을 때만 1분을 더해 61초가 2분으로 보이도록 합니다.
        let minutes = seconds / 60 + (seconds.isMultiple(of: 60) ? 0 : 1)
        return "약 \(minutes)분"
    }

    /// 값이 있을 때만 caption, 구분선과 계산된 시간을 가운데 정렬합니다.
    @ViewBuilder
    var body: some View {
        if let durationText {
            VStack(spacing: 4) {
                Text("소요시간")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                HStack(spacing: 12) {
                    separator
                    Text(durationText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    separator
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// 시간 텍스트 양쪽에서 균형을 잡는 짧은 시스템 구분선입니다.
    private var separator: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.3))
            .frame(width: 28, height: 1)
            .accessibilityHidden(true)
    }
}
```

- [ ] **Step 4: Hero 컴포넌트 구현**

```swift
import SwiftUI

/// 상단 배경, 대표 이미지, 주차와 제목을 하나의 시각적 영역으로 구성합니다.
struct ScriptPreviewHero: View {
    /// Figma에서 지정한 대표 이미지 한 변의 길이입니다.
    static let thumbnailSize: CGFloat = 132
    /// Figma에서 지정한 대표 이미지 모서리 반경입니다.
    static let thumbnailCornerRadius: CGFloat = 32

    /// 표시 위치별 에셋 이름을 제공하는 대본 이미지 시리즈입니다.
    let artworkSeries: ScriptArtworkSeries
    /// 사용자에게 보여줄 권장 임신 주차입니다.
    let targetGestationalWeek: Int
    /// 대표 이미지 아래에 보여줄 대본 제목입니다.
    let title: String

    /// 숫자 주차를 한국어 표시 문자열로 변환합니다.
    var weekText: String { "\(targetGestationalWeek)주차" }

    /// Back 이미지를 상단에 두고 Thumbnail과 텍스트를 전면에 배치합니다.
    var body: some View {
        ZStack(alignment: .top) {
            ScriptArtworkView(assetName: artworkSeries.backgroundAssetName, cornerRadius: 0)
                .frame(maxWidth: .infinity)
                .frame(height: 396)
            // 아래 본문이 자연스럽게 이어지도록 시스템 배경색으로 전환합니다.
            LinearGradient(
                colors: [.clear, Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 396)
            .accessibilityHidden(true)

            VStack(spacing: 0) {
                ScriptArtworkView(
                    assetName: artworkSeries.thumbnailAssetName,
                    cornerRadius: Self.thumbnailCornerRadius
                )
                .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
                .padding(.top, 76)
                Text(weekText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primaryRed)
                    .padding(.top, 16)
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 396, alignment: .top)
    }
}
```

- [ ] **Step 5: 집중 테스트 통과 후 커밋**

Run: Step 2 명령. Expected: `** TEST SUCCEEDED **`.

```bash
git add Siboya/Features/Home/Component/ScriptPreviewDuration.swift Siboya/Features/Home/Component/ScriptPreviewHero.swift SiboyaTests/Home/ScriptPreviewComponentsTests.swift
git commit -m "feat: 대본 미리보기 상단 컴포넌트 추가"
```

### Task 4: 본문과 생각힌트 컴포넌트

**Files:**
- Create: `Siboya/Features/Home/Component/ScriptPreviewBody.swift`
- Modify: `SiboyaTests/Home/ScriptPreviewComponentsTests.swift`

**Interfaces:**
- Consumes: `[ScriptSentenceDTO]`, `bucketListPrompt`, `bucketListGuide`
- Produces: 문장 → 빈칸 문장 → 생각힌트 순서의 `[ContentItem]`과 SwiftUI 본문

- [ ] **Step 1: 입력 순서 보존 실패 테스트 추가**

```swift
/// 문장을 재정렬하지 않고 빈칸 문장과 생각힌트를 뒤에 붙이는지 검증합니다.
@Test @MainActor
func bodyPreservesSentenceOrderBeforePromptAndGuide() {
    let body = ScriptPreviewBody(
        sentences: [
            ScriptSentenceDTO(index: 9, text: "먼저 전달된 문장"),
            ScriptSentenceDTO(index: 1, text: "나중에 전달된 문장")
        ],
        bucketListPrompt: "빈칸 문장",
        bucketListGuide: "생각힌트"
    )
    #expect(body.contentItems.map(\.text) == ["먼저 전달된 문장", "나중에 전달된 문장", "빈칸 문장", "생각힌트"])
    #expect(body.contentItems.map(\.role) == [.sentence, .sentence, .bucketListPrompt, .bucketListGuide])
}
```

- [ ] **Step 2: `ScriptPreviewBody` 부재로 테스트 실패 확인**

Run: Task 3 Step 2 명령. Expected: FAIL with missing type.

- [ ] **Step 3: 본문 컴포넌트 구현**

```swift
import SwiftUI

/// 대본 문장, 빈칸 문장과 생각힌트를 SSD 순서대로 보여주는 본문 컴포넌트입니다.
struct ScriptPreviewBody: View {
    /// 본문 항목마다 적용할 의미와 간격을 구분합니다.
    enum ContentRole: Equatable { case sentence, bucketListPrompt, bucketListGuide }

    /// 표시 순서, 식별자, 역할과 실제 텍스트를 함께 보관합니다.
    struct ContentItem: Identifiable, Equatable {
        let id: String
        let role: ContentRole
        let text: String
    }

    /// 상위 계층이 검증한 원래 순서의 대본 문장입니다.
    let sentences: [ScriptSentenceDTO]
    /// 사용자가 직접 완성해서 읽을 빈칸 문장입니다.
    let bucketListPrompt: String
    /// 빈칸을 떠올릴 수 있게 돕는 생각힌트입니다.
    let bucketListGuide: String

    /// 문장을 재정렬하지 않고 빈칸 문장과 생각힌트를 마지막에 결합합니다.
    var contentItems: [ContentItem] {
        let sentenceItems = sentences.map {
            ContentItem(id: "sentence-\($0.index)", role: .sentence, text: $0.text)
        }
        return sentenceItems + [
            ContentItem(id: "bucket-list-prompt", role: .bucketListPrompt, text: bucketListPrompt),
            ContentItem(id: "bucket-list-guide", role: .bucketListGuide, text: bucketListGuide)
        ]
    }

    /// 계산된 순서대로 역할별 본문 스타일을 표시합니다.
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(contentItems) { item in contentView(for: item) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 항목 역할에 맞는 일반 문장, 빈칸 문장 또는 생각힌트를 만듭니다.
    @ViewBuilder
    private func contentView(for item: ContentItem) -> some View {
        switch item.role {
        case .sentence:
            bodyText(item.text)
        case .bucketListPrompt:
            bodyText(item.text).padding(.top, 20)
        case .bucketListGuide:
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("💡").accessibilityHidden(true)
                bodyText(item.text)
                Text("💡").accessibilityHidden(true)
            }
            .padding(.top, 28)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("생각힌트: \(item.text)")
        }
    }

    /// 일반 문장과 빈칸 문장이 공유하는 semantic 본문 스타일입니다.
    private func bodyText(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundStyle(Color.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
```

- [ ] **Step 4: 집중 테스트 통과 후 커밋**

Run: Task 3 Step 2 명령. Expected: `** TEST SUCCEEDED **`.

```bash
git add Siboya/Features/Home/Component/ScriptPreviewBody.swift SiboyaTests/Home/ScriptPreviewComponentsTests.swift
git commit -m "feat: 대본 미리보기 본문 컴포넌트 추가"
```

### Task 5: 고정 하단 버튼 컴포넌트

**Files:**
- Create: `Siboya/Features/Home/Component/ScriptPreviewBottomBar.swift`
- Modify: `SiboyaTests/Home/ScriptPreviewComponentsTests.swift`

**Interfaces:**
- Consumes: `onPrepare: () -> Void`
- Produces: 시스템 배경 gradient, `PrimaryButton(title: "준비하기")`, 한 번 전달되는 callback

- [ ] **Step 1: callback 실패 테스트 추가**

```swift
/// 준비하기 선택이 상위 callback을 정확히 한 번 호출하는지 검증합니다.
@Test @MainActor
func bottomBarForwardsPrepareOnce() {
    var count = 0
    let bottomBar = ScriptPreviewBottomBar { count += 1 }
    bottomBar.prepare()
    #expect(count == 1)
}
```

- [ ] **Step 2: `ScriptPreviewBottomBar` 부재로 테스트 실패 확인**

Run: Task 3 Step 2 명령. Expected: FAIL with missing type.

- [ ] **Step 3: BottomBar 구현**

```swift
import SwiftUI

/// 스크롤 본문 위에 고정될 그라데이션과 준비하기 버튼을 제공하는 하단 컴포넌트입니다.
struct ScriptPreviewBottomBar: View {
    /// 준비자세 모달 등 다음 흐름을 결정할 상위 계층 callback입니다.
    let onPrepare: () -> Void

    /// 투명 그라데이션 아래에 기존 공통 PrimaryButton을 배치합니다.
    var body: some View {
        VStack(spacing: 0) {
            // 스크롤 끝과 버튼이 갑자기 끊겨 보이지 않도록 시스템 배경으로 전환합니다.
            LinearGradient(
                colors: [.clear, Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 36)
            .accessibilityHidden(true)
            PrimaryButton(title: "준비하기", action: prepare)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .background(Color(.systemBackground))
        }
    }

    /// 버튼 선택을 저장·권한 로직 없이 상위 흐름에 그대로 전달합니다.
    func prepare() { onPrepare() }
}
```

- [ ] **Step 4: 집중 테스트 통과 후 커밋**

Run: Task 3 Step 2 명령. Expected: `** TEST SUCCEEDED **`.

```bash
git add Siboya/Features/Home/Component/ScriptPreviewBottomBar.swift SiboyaTests/Home/ScriptPreviewComponentsTests.swift
git commit -m "feat: 대본 미리보기 하단 버튼 컴포넌트 추가"
```

### Task 6: 회귀 및 정적 검증

**Files:**
- Verify: `Siboya/Features/Home`
- Verify: `Siboya/Features/Home/Component`
- Verify: `SiboyaTests`

**Interfaces:**
- Consumes: Tasks 1~5의 모든 구현
- Produces: 테스트, lint와 Debug build 증거

- [ ] **Step 1: Home과 미리보기 집중 테스트 실행**

Run: `xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:SiboyaTests/HomeComponentsTests -only-testing:SiboyaTests/ScriptPreviewComponentsTests`

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 2: 전체 단위 테스트 실행**

Run: `xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:SiboyaTests`

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 3: SwiftLint 실행**

Run: `swiftlint lint --strict`

Expected: exit code 0, 새 warning/error 없음.

- [ ] **Step 4: iOS Simulator Debug build 실행**

Run: `xcodebuild build -project Siboya.xcodeproj -scheme Siboya -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'`

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: 사용자 변경과 구현 변경 분리 확인**

Run: `git status --short`, `git diff --check`, `git diff --cached --name-status`.

Expected: 사용자 소유의 `project.pbxproj`와 `img_profile.imageset`은 보존되고 구현 파일에는 공백 오류가 없다.

### Task 7: 소요시간 세로 장식선 수정

**Files:**
- Modify: `Siboya/Features/Home/Component/ScriptPreviewDuration.swift`
- Modify: `SiboyaTests/Home/ScriptPreviewComponentsTests.swift`

**Interfaces:**
- Consumes: 기존 `estimatedDurationSeconds`와 `durationText`
- Produces: `소요시간`과 `약 N분` 전체를 양옆에서 감싸는 자동 높이 1pt 세로 separator

- [ ] **Step 1: 세로 separator 두께 계약의 실패 테스트 작성**

```swift
/// 소요시간 장식선이 가로선이 아닌 1pt 세로선으로 구성되는지 검증합니다.
@Test @MainActor
func durationUsesVerticalSeparatorThickness() {
    #expect(ScriptPreviewDuration.separatorThickness == 1)
}
```

- [ ] **Step 2: 새 레이아웃 계약이 없어 테스트가 실패하는지 확인**

Run: `xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:SiboyaTests/ScriptPreviewComponentsTests/durationUsesVerticalSeparatorThickness`

Expected: FAIL with `type 'ScriptPreviewDuration' has no member 'separatorThickness'`.

- [ ] **Step 3: 텍스트 묶음 전체에 세로 separator 오버레이 적용**

```swift
/// Home의 대본 미리보기에서 예상 소요 초를 읽기 쉬운 분 단위로 보여주는 컴포넌트입니다.
struct ScriptPreviewDuration: View {
    /// 세로 장식선이 차지하는 고정 두께입니다.
    static let separatorThickness: CGFloat = 1

    /// 값이 있을 때 두 텍스트 전체를 양쪽 세로선으로 감싸 가운데 정렬합니다.
    @ViewBuilder
    var body: some View {
        if let durationText {
            VStack(spacing: 4) {
                Text("소요시간")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)

                Text(durationText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)
            }
            .padding(.horizontal, 12)
            .overlay(alignment: .leading) { separator }
            .overlay(alignment: .trailing) { separator }
            .accessibilityElement(children: .combine)
        }
    }

    /// 부모 텍스트 묶음이 제안한 전체 높이를 채우는 1pt 세로 장식선입니다.
    private var separator: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.3))
            .frame(width: Self.separatorThickness)
            .accessibilityHidden(true)
    }
}
```

- [ ] **Step 4: 집중 테스트와 정적 검증 실행**

Run: `xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:SiboyaTests/ScriptPreviewComponentsTests`

Expected: `** TEST SUCCEEDED **`.

Run: `swiftlint lint --strict`

Expected: exit code 0, 새 warning/error 없음.

- [ ] **Step 5: 구현 변경 커밋**

```bash
git add Siboya/Features/Home/Component/ScriptPreviewDuration.swift SiboyaTests/Home/ScriptPreviewComponentsTests.swift
git commit -m "fix: 소요시간 장식선을 세로로 수정"
```
