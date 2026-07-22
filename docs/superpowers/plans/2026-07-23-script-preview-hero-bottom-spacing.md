# Script Preview Hero 하단 간격 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hero의 썸네일·주차·제목을 Figma 위치로 내리고 제목과 소요시간 사이를 `8pt`로 유지한다.

**Architecture:** 배경 이미지와 그라데이션을 Hero의 레이아웃 크기를 결정하는 `ZStack` 자식에서 장식용 `background`로 분리한다. 전경은 Figma 상단 좌표를 사용해 자연 높이를 만들고, `ScriptPreviewView`가 그 전경 경계 다음에 Duration을 `8pt` 떨어뜨린다.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing, UIKit hosting measurement, Xcode 26 iOS Simulator

## Global Constraints

- Figma `대본&생각힌트 미리보기` 노드 `1009:11964`의 썸네일 상단 `140pt`, 썸네일-주차 `16pt`, 주차-제목 `6pt`, 제목-Duration `8pt`를 따른다.
- Hero 배경 높이 `396pt`, 썸네일 `132×132pt`, 모서리 반경 `32pt`, 배경 이미지 상단 정렬과 `.top` safe-area 무시는 유지한다.
- Dynamic Type에서 긴 제목이 커지면 Hero의 레이아웃 높이도 함께 확장한다.
- 신규·수정 Swift 코드와 테스트에는 역할과 검증 의도를 설명하는 한국어 주석을 작성한다.
- `ScriptPreviewDuration`, 본문, 준비자세·권한·전체 화면 흐름과 사용자 소유 프로젝트·에셋 변경은 수정하지 않는다.

---

### Task 1: Hero 전경 경계와 Duration 간격 연결

**Files:**
- Modify: `Siboya/Features/Home/Component/ScriptPreviewHero.swift`
- Modify: `Siboya/Features/Home/View/ScriptPreviewView.swift`
- Test: `SiboyaTests/Home/ScriptPreviewComponentsTests.swift`
- Test: `SiboyaTests/Home/ScriptPreviewViewTests.swift`

**Interfaces:**
- Consumes: `ScriptPreviewHero`의 기존 이미지 시리즈·주차·제목과 `ScriptPreviewDuration`
- Produces: `foregroundTopSpacing`, `thumbnailToWeekSpacing`, `weekToTitleSpacing`, `heroToDurationSpacing` 레이아웃 계약

- [ ] **Step 1: 승인된 좌표와 실제 Hero 레이아웃 경계를 검증하는 실패 테스트 작성**

`ScriptPreviewComponentsTests.swift`에 다음 테스트를 추가한다.

```swift
    /// Hero 전경이 Figma의 세로 좌표를 사용하고 장식 배경이 전경 레이아웃 높이를 늘리지 않는지 검증합니다.
    @Test @MainActor
    func heroUsesFigmaForegroundSpacingWithoutBackgroundLayoutGap() {
        let regularHeight = fittingSize(
            of: ScriptPreviewHero(
                artworkSeries: .one,
                targetGestationalWeek: 22,
                title: "일요일 아침 냄새"
            )
            .environment(\.dynamicTypeSize, .medium)
        ).height

        #expect(ScriptPreviewHero.foregroundTopSpacing == 140)
        #expect(ScriptPreviewHero.thumbnailToWeekSpacing == 16)
        #expect(ScriptPreviewHero.weekToTitleSpacing == 6)
        #expect(regularHeight < ScriptPreviewHero.backgroundHeight)
    }
```

`ScriptPreviewViewTests.swift`에 다음 테스트를 추가한다.

```swift
    /// Hero 제목의 레이아웃 경계 다음에 소요시간이 Figma 기준 8pt만큼 떨어지는지 검증합니다.
    @Test
    func previewUsesEightPointHeroToDurationSpacing() {
        #expect(ScriptPreviewView.heroToDurationSpacing == 8)
    }
```

- [ ] **Step 2: 새 계약이 없어서 테스트가 실패하는지 확인**

Run:

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests/ScriptPreviewComponentsTests/heroUsesFigmaForegroundSpacingWithoutBackgroundLayoutGap -only-testing:SiboyaTests/ScriptPreviewViewTests/previewUsesEightPointHeroToDurationSpacing
```

Expected: FAIL at compile time because 새 spacing 상수와 공개된 `backgroundHeight`가 없다.

- [ ] **Step 3: Hero 배경과 전경의 레이아웃 책임 분리**

`ScriptPreviewHero.swift`에 다음 내부 계약을 추가하고 기존 `backgroundHeight`를 테스트 가능한 내부 상수로 변경한다.

```swift
    /// Figma에서 대표 이미지가 화면 최상단부터 떨어진 거리입니다.
    static let foregroundTopSpacing: CGFloat = 140

    /// Figma에서 대표 이미지와 주차 문구 사이의 간격입니다.
    static let thumbnailToWeekSpacing: CGFloat = 16

    /// Figma에서 주차 문구와 제목 사이의 간격입니다.
    static let weekToTitleSpacing: CGFloat = 6

    /// 상단 배경이 차지하는 Figma 기준 높이이며 장식 레이어 크기만 결정합니다.
    static let backgroundHeight: CGFloat = 396
```

`body`는 전경만 레이아웃 높이를 만들고 배경은 장식으로 붙이도록 변경한다.

```swift
    /// 배경은 레이아웃 높이에서 분리하고 Thumbnail·텍스트는 Figma 좌표로 세로 배치합니다.
    var body: some View {
        VStack(spacing: 0) {
            ScriptArtworkView(
                assetName: artworkSeries.thumbnailAssetName,
                cornerRadius: Self.thumbnailCornerRadius
            )
            .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
            .padding(.top, Self.foregroundTopSpacing)

            Text(weekText)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primaryRed)
                .padding(.top, Self.thumbnailToWeekSpacing)

            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Self.weekToTitleSpacing)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            background
        }
        .ignoresSafeArea(edges: Self.ignoredSafeAreaEdges)
    }

    /// Hero 높이에 영향을 주지 않고 상단 배경과 시스템 배경 전환 그라데이션을 그립니다.
    private var background: some View {
        ZStack(alignment: .top) {
            ScriptArtworkView(
                assetName: artworkSeries.backgroundAssetName,
                cornerRadius: 0,
                imageAlignment: backgroundArtworkAlignment
            )

            LinearGradient(
                colors: [.clear, Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .accessibilityHidden(true)
        }
        .frame(height: Self.backgroundHeight)
    }
```

- [ ] **Step 4: 상위 View의 8pt 간격을 명시적 계약으로 연결**

`ScriptPreviewView.swift`에 상수를 추가한다.

```swift
    /// Hero 제목과 소요시간 정보 사이에 유지할 Figma 기준 간격입니다.
    static let heroToDurationSpacing: CGFloat = 8
```

기존 Duration 상단 여백을 다음처럼 바꾼다.

```swift
                .padding(.top, Self.heroToDurationSpacing)
```

- [ ] **Step 5: 집중 테스트와 기존 Dynamic Type 테스트 확인**

Run:

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests/ScriptPreviewComponentsTests -only-testing:SiboyaTests/ScriptPreviewViewTests
```

Expected: PASS. 일반 Hero는 배경보다 짧은 자연 높이를 사용하고 접근성 Hero는 계속 확장된다.

- [ ] **Step 6: 전체 검증 후 구현 파일만 커밋**

Run:

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SiboyaTests
./Scripts/lint.sh
xcodebuild build -project Siboya.xcodeproj -scheme Siboya -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
git diff --check
```

Expected: 전체 단위 테스트와 빌드가 성공하고 SwiftLint 위반 및 whitespace 오류가 없다.

```bash
git add Siboya/Features/Home/Component/ScriptPreviewHero.swift Siboya/Features/Home/View/ScriptPreviewView.swift SiboyaTests/Home/ScriptPreviewComponentsTests.swift SiboyaTests/Home/ScriptPreviewViewTests.swift
git commit -m "fix: 대본 미리보기 Hero 하단 간격 조정"
```
