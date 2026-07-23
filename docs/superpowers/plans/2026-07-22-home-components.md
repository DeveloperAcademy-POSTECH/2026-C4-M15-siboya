# Home Components Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Figma Home을 구성하는 표시 전용 SwiftUI 컴포넌트 다섯 개를 만들고, 없는 이미지 에셋은 같은 크기의 박스로 대체한다.

**Architecture:** `HomeScriptItem`이 JSON에서 변환된 표시값과 선택 식별자를 보유한다. 네 View는 값과 callback만 받아 렌더링하며, Asset Catalog 조회는 `HomeArtworkView` 한 곳에서 처리한다. 로더·SwiftData·Navigation은 이후 화면 조립 단계에서 연결한다.

**Tech Stack:** Swift 5, SwiftUI, UIKit `UIImage`, Swift Testing, Xcode 26.6, iOS 26.5

## Global Constraints

- 구현 파일은 `Siboya/Features/Home` 아래에 평평하게 둔다.
- 테스트 파일은 `SiboyaTests/Home`에 둔다.
- Figma는 레이아웃·간격·타이포그래피 역할의 기준이고 JSON 주입값은 문구·주차·카테고리·식별자의 기준이다.
- 이미지가 없거나 이름이 비어 있으면 `Color(.secondarySystemBackground)` 박스를 표시한다.
- 컴포넌트는 로더, `ModelContext`, Repository, 권한 API와 Navigation을 참조하지 않는다.
- 사용자 Asset Catalog 파일과 `project.pbxproj` 변경을 수정하거나 구현 커밋에 포함하지 않는다.
- 새로운 외부 의존성을 추가하지 않는다.

---

### Task 1: Home 표시 모델

**Files:**
- Create: `Siboya/Features/Home/HomeScriptItem.swift`
- Create: `SiboyaTests/Home/HomeComponentsTests.swift`

**Interfaces:**
- Consumes: `Foundation.UUID`
- Produces: `HomeScriptItem`, `id: String`, `gestationalWeekText: String`

- [ ] **Step 1: 실패 테스트 작성**

```swift
import Foundation
import Testing
@testable import Siboya

struct HomeComponentsTests {
    @Test
    func scriptItemIDIncludesVersion() throws {
        let scriptID = try #require(
            UUID(uuidString: "57A07A17-20D6-440C-989F-0B1208B6ED01")
        )
        let firstVersion = makeItem(scriptID: scriptID, version: 1)
        let secondVersion = makeItem(scriptID: scriptID, version: 2)

        #expect(firstVersion.id != secondVersion.id)
        #expect(firstVersion.id == "57A07A17-20D6-440C-989F-0B1208B6ED01-1")
    }

    @Test
    func gestationalWeekTextUsesInjectedWeek() {
        #expect(makeItem(week: 20).gestationalWeekText == "20주차")
        #expect(makeItem(week: 40).gestationalWeekText == "40주차")
    }

    private func makeItem(
        scriptID: UUID = UUID(),
        version: Int = 1,
        week: Int = 20
    ) -> HomeScriptItem {
        HomeScriptItem(
            scriptID: scriptID,
            scriptVersion: version,
            title: "일요일 아침 냄새",
            targetGestationalWeek: week,
            artworkAssetName: "script_home_sunday_morning_20w"
        )
    }
}
```

- [ ] **Step 2: RED 확인**

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests/HomeComponentsTests
```

Expected: `HomeScriptItem`이 없어 컴파일에 실패한다.

- [ ] **Step 3: 최소 구현 작성**

```swift
import Foundation

struct HomeScriptItem: Identifiable, Equatable, Sendable {
    let scriptID: UUID
    let scriptVersion: Int
    let title: String
    let targetGestationalWeek: Int
    let artworkAssetName: String

    var id: String {
        "\(scriptID.uuidString)-\(scriptVersion)"
    }

    var gestationalWeekText: String {
        "\(targetGestationalWeek)주차"
    }
}
```

- [ ] **Step 4: GREEN 확인**

Step 2 명령을 다시 실행해 테스트 통과를 확인한다.

- [ ] **Step 5: 지정 파일만 커밋**

```bash
git commit Siboya/Features/Home/HomeScriptItem.swift SiboyaTests/Home/HomeComponentsTests.swift -m "feat: Home 대본 표시 모델 추가"
```

---

### Task 2: 이미지와 fallback 박스

**Files:**
- Create: `Siboya/Features/Home/HomeArtworkView.swift`
- Modify: `SiboyaTests/Home/HomeComponentsTests.swift`

**Interfaces:**
- Consumes: `assetName: String`, `cornerRadius: CGFloat`
- Produces: `HomeArtworkView`, `resolvedAssetName`, `resolvedImage`

- [ ] **Step 1: 실패 테스트 추가**

```swift
@Test
@MainActor
func artworkIgnoresBlankAssetName() {
    let artwork = HomeArtworkView(assetName: "  \n", cornerRadius: 17)
    #expect(artwork.resolvedAssetName == nil)
    #expect(artwork.resolvedImage == nil)
}

@Test
@MainActor
func artworkUsesPlaceholderWhenAssetDoesNotExist() {
    let artwork = HomeArtworkView(
        assetName: "missing-\(UUID().uuidString)",
        cornerRadius: 17
    )
    #expect(artwork.resolvedAssetName != nil)
    #expect(artwork.resolvedImage == nil)
}
```

- [ ] **Step 2: RED 확인**

Task 1의 집중 테스트 명령을 실행해 `HomeArtworkView`가 없어서 실패하는지 확인한다.

- [ ] **Step 3: 최소 구현 작성**

```swift
import SwiftUI
import UIKit

struct HomeArtworkView: View {
    let assetName: String
    let cornerRadius: CGFloat

    var resolvedAssetName: String? {
        let trimmedName = assetName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? nil : trimmedName
    }

    var resolvedImage: UIImage? {
        guard let resolvedAssetName else { return nil }
        return UIImage(named: resolvedAssetName)
    }

    var body: some View {
        Group {
            if let resolvedImage {
                Image(uiImage: resolvedImage)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityHidden(true)
    }
}
```

같은 파일 끝에 실제 asset과 missing asset Preview를 추가한다.

```swift
#Preview("Existing asset") {
    HomeArtworkView(assetName: "TitleImage2", cornerRadius: 17)
        .frame(width: 180, height: 120)
}

#Preview("Missing asset placeholder") {
    HomeArtworkView(assetName: "missing-script-artwork", cornerRadius: 17)
        .frame(width: 180, height: 120)
}
```

- [ ] **Step 4: GREEN 확인**

집중 테스트를 다시 실행해 두 asset 정책 테스트가 통과하는지 확인한다.

- [ ] **Step 5: 지정 파일만 커밋**

```bash
git commit Siboya/Features/Home/HomeArtworkView.swift SiboyaTests/Home/HomeComponentsTests.swift -m "feat: Home 이미지 fallback 컴포넌트 추가"
```

---

### Task 3: 추천 카드와 대본 행

**Files:**
- Create: `Siboya/Features/Home/HomeRecommendationCard.swift`
- Create: `Siboya/Features/Home/HomeScriptRow.swift`
- Modify: `SiboyaTests/Home/HomeComponentsTests.swift`

**Interfaces:**
- Consumes: `HomeScriptItem`, `(UUID, Int) -> Void`
- Produces: `HomeRecommendationCard`, `HomeScriptRow`, 두 View의 `select()`

- [ ] **Step 1: 선택 전달 실패 테스트 추가**

```swift
@Test
@MainActor
func recommendationCardForwardsScriptSelection() {
    let item = makeItem(version: 3)
    var receivedID: UUID?
    var receivedVersion: Int?
    let card = HomeRecommendationCard(item: item) { scriptID, version in
        receivedID = scriptID
        receivedVersion = version
    }

    card.select()

    #expect(receivedID == item.scriptID)
    #expect(receivedVersion == 3)
}

@Test
@MainActor
func scriptRowForwardsScriptSelection() {
    let item = makeItem(version: 4)
    var receivedID: UUID?
    var receivedVersion: Int?
    let row = HomeScriptRow(item: item) { scriptID, version in
        receivedID = scriptID
        receivedVersion = version
    }

    row.select()

    #expect(receivedID == item.scriptID)
    #expect(receivedVersion == 4)
}
```

- [ ] **Step 2: RED 확인**

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests/HomeComponentsTests
```

Expected: `HomeRecommendationCard`와 `HomeScriptRow`가 없어 컴파일에 실패한다.

- [ ] **Step 3: 추천 카드 구현**

```swift
import SwiftUI

struct HomeRecommendationCard: View {
    let item: HomeScriptItem
    let onSelect: (UUID, Int) -> Void

    var body: some View {
        Button(action: select) {
            ZStack(alignment: .bottomLeading) {
                HomeArtworkView(assetName: item.artworkAssetName, cornerRadius: 20)

                LinearGradient(
                    colors: [.clear, .white.opacity(0.96)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Text(item.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.leading)
                    .padding(20)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 230)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 9)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.title)
    }

    func select() {
        onSelect(item.scriptID, item.scriptVersion)
    }
}
```

- [ ] **Step 4: 대본 행 구현**

```swift
import SwiftUI

struct HomeScriptRow: View {
    let item: HomeScriptItem
    let onSelect: (UUID, Int) -> Void

    var body: some View {
        Button(action: select) {
            HStack(spacing: 9) {
                HomeArtworkView(assetName: item.artworkAssetName, cornerRadius: 17)
                    .frame(width: 66, height: 66)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.body)
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.leading)

                    Text(item.gestationalWeekText)
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.title)
        .accessibilityValue(item.gestationalWeekText)
    }

    func select() {
        onSelect(item.scriptID, item.scriptVersion)
    }
}
```

`HomeRecommendationCard.swift` 끝에 다음 Preview를 추가한다.

```swift
#Preview("Recommendation with placeholder") {
    HomeRecommendationCard(
        item: HomeScriptItem(
            scriptID: UUID(),
            scriptVersion: 1,
            title: "바다 냄새와 파도 소리",
            targetGestationalWeek: 20,
            artworkAssetName: "missing-script-artwork"
        ),
        onSelect: { _, _ in }
    )
    .padding(20)
}
```

`HomeScriptRow.swift` 끝에 다음 Preview를 추가한다.

```swift
#Preview("Script row with placeholder") {
    HomeScriptRow(
        item: HomeScriptItem(
            scriptID: UUID(),
            scriptVersion: 1,
            title: "조용한 도서관 구석에서",
            targetGestationalWeek: 20,
            artworkAssetName: "missing-script-artwork"
        ),
        onSelect: { _, _ in }
    )
    .padding(.horizontal, 20)
}
```

- [ ] **Step 5: GREEN 확인**

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests/HomeComponentsTests
```

Expected: UUID와 version 전달 테스트가 통과한다.

- [ ] **Step 6: 지정 파일만 커밋**

```bash
git commit Siboya/Features/Home/HomeRecommendationCard.swift Siboya/Features/Home/HomeScriptRow.swift SiboyaTests/Home/HomeComponentsTests.swift -m "feat: Home 추천 카드와 대본 행 추가"
```

---

### Task 4: 카테고리 섹션

**Files:**
- Create: `Siboya/Features/Home/HomeCategorySection.swift`
- Modify: `SiboyaTests/Home/HomeComponentsTests.swift`

**Interfaces:**
- Consumes: `title`, `[HomeScriptItem]`, `(UUID, Int) -> Void`
- Produces: `HomeCategorySection`, `hasContent`

- [ ] **Step 1: 빈 목록 실패 테스트 추가**

```swift
@Test
@MainActor
func categorySectionHidesEmptyItems() {
    let emptySection = HomeCategorySection(
        title: "멀리멀리 대모험",
        items: [],
        onSelect: { _, _ in }
    )
    let populatedSection = HomeCategorySection(
        title: "멀리멀리 대모험",
        items: [makeItem()],
        onSelect: { _, _ in }
    )

    #expect(!emptySection.hasContent)
    #expect(populatedSection.hasContent)
}
```

- [ ] **Step 2: RED 확인**

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests/HomeComponentsTests
```

Expected: `HomeCategorySection`이 없어 컴파일에 실패한다.

- [ ] **Step 3: 최소 구현 작성**

```swift
import SwiftUI

struct HomeCategorySection: View {
    let title: String
    let items: [HomeScriptItem]
    let onSelect: (UUID, Int) -> Void

    var hasContent: Bool {
        !items.isEmpty
    }

    var body: some View {
        if hasContent {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        HomeScriptRow(item: item, onSelect: onSelect)

                        if index < items.index(before: items.endIndex) {
                            Divider()
                                .padding(.leading, 75)
                        }
                    }
                }
            }
        }
    }
}
```

같은 파일 끝에 실제 asset과 missing asset을 함께 보여주는 Preview를 추가한다.

```swift
#Preview("Category section") {
    HomeCategorySection(
        title: "멀리멀리 대모험",
        items: [
            HomeScriptItem(
                scriptID: UUID(),
                scriptVersion: 1,
                title: "바다 냄새와 파도 소리",
                targetGestationalWeek: 20,
                artworkAssetName: "TitleImage2"
            ),
            HomeScriptItem(
                scriptID: UUID(),
                scriptVersion: 1,
                title: "밤하늘의 불빛들",
                targetGestationalWeek: 20,
                artworkAssetName: "missing-script-artwork"
            )
        ],
        onSelect: { _, _ in }
    )
    .padding(20)
}
```

- [ ] **Step 4: GREEN 확인**

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests/HomeComponentsTests
```

Expected: 빈 목록과 채워진 목록의 `hasContent` 결과가 통과한다.

- [ ] **Step 5: 지정 파일만 커밋**

```bash
git commit Siboya/Features/Home/HomeCategorySection.swift SiboyaTests/Home/HomeComponentsTests.swift -m "feat: Home 카테고리 섹션 추가"
```

---

### Task 5: 전체 검증

**Files:**
- Verify: `Siboya/Features/Home/*.swift`
- Verify: `SiboyaTests/Home/HomeComponentsTests.swift`

**Interfaces:**
- Consumes: Tasks 1~4 결과
- Produces: 테스트·빌드·lint 증거

- [ ] **Step 1: 집중 테스트 실행**

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests/HomeComponentsTests
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 2: 전체 단위 테스트 실행**

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 3: Simulator용 앱 빌드**

```bash
xcodebuild build -project Siboya.xcodeproj -scheme Siboya -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: SwiftLint 실행**

```bash
./Scripts/lint.sh
```

Expected: 신규 Home 파일에 error가 없고 exit 0으로 끝난다.

- [ ] **Step 5: 변경 범위 확인**

```bash
git status --short
git log -5 --oneline
```

Expected: 구현 커밋에는 Home·HomeTests 파일만 포함되고, 사용자 에셋과 `project.pbxproj` 변경은 작업 트리에 그대로 남는다.
