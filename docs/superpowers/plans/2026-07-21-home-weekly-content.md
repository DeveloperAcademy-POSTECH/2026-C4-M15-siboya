# Home Weekly Content Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add bundled 20–40 week Home headlines with an optional recommended Taedam script UUID, plus a typed loader and executable tests.

**Architecture:** Keep Home-only weekly content in `Siboya/Resources/Home/home-weekly-content.json` instead of duplicating it inside `taedam-scripts.json`. Decode the resource through focused Home model and loader types; `recommendedScriptID` remains `nil` until the corresponding script is added and selected by the team.

**Tech Stack:** Swift 6, Foundation `Codable`, Swift Testing, Xcode 26.5, iOS 26.5

## Global Constraints

- Figma is the visual source of truth; JSON is the copy, week, list, and identifier source of truth.
- Store exactly one Home content entry for every gestational week from 20 through 40.
- Keep `recommendedScriptID` present in every JSON entry and set it to `null` until a recommended script is confirmed.
- Do not duplicate script title, image name, sentences, prompt, or guide in the Home JSON.
- Do not change `taedam-scripts.json` in this task.
- Do not push the branch.

---

### Task 1: Decode and load bundled weekly Home content

**Files:**
- Create: `SiboyaTests/Home/HomeWeeklyContentDocumentTests.swift`
- Create: `Siboya/Features/Home/Model/HomeWeeklyContentDocument.swift`
- Create: `Siboya/Features/Home/Service/BundledHomeWeeklyContentLoader.swift`
- Create: `Siboya/Resources/Home/home-weekly-content.json`

**Interfaces:**
- Consumes: `Bundle`, `JSONDecoder`, the approved 20–40 week Notion headlines.
- Produces: `HomeWeeklyContentDocument`, `HomeWeeklyContent`, `HomeWeeklyContentDocument.content(forGestationalWeek:)`, and `BundledHomeWeeklyContentLoader.load(from:)`.

- [ ] **Step 1: Write the failing tests**

Create `SiboyaTests/Home/HomeWeeklyContentDocumentTests.swift`:

```swift
import Foundation
import Testing
@testable import Siboya

struct HomeWeeklyContentDocumentTests {
    @Test func bundledDocumentContainsEveryWeekFromTwentyThroughForty() throws {
        let document = try BundledHomeWeeklyContentLoader.load()

        #expect(document.weeks.map(\.gestationalWeek) == Array(20...40))
        #expect(Set(document.weeks.map(\.gestationalWeek)).count == 21)
        #expect(document.weeks.allSatisfy { !$0.headline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        #expect(document.weeks.allSatisfy { $0.recommendedScriptID == nil })
    }

    @Test func documentReturnsContentForExactGestationalWeek() throws {
        let document = try BundledHomeWeeklyContentLoader.load()
        let content = try #require(document.content(forGestationalWeek: 20))

        #expect(content.headline == "아빠의 낮은 목소리가 잘 들리는 시기")
        #expect(content.recommendedScriptID == nil)
        #expect(document.content(forGestationalWeek: 19) == nil)
        #expect(document.content(forGestationalWeek: 41) == nil)
    }

    @Test func recommendedScriptIDDecodesAsUUIDOrNull() throws {
        let linkedID = UUID(uuidString: "57A07A17-20D6-440C-989F-0B1208B6ED01")!
        let data = Data(
            """
            {
              "weeks": [
                {
                  "gestationalWeek": 20,
                  "headline": "연결됨",
                  "recommendedScriptID": "\(linkedID.uuidString)"
                },
                {
                  "gestationalWeek": 21,
                  "headline": "미연결",
                  "recommendedScriptID": null
                }
              ]
            }
            """.utf8
        )

        let document = try JSONDecoder().decode(HomeWeeklyContentDocument.self, from: data)

        #expect(document.weeks[0].recommendedScriptID == linkedID)
        #expect(document.weeks[1].recommendedScriptID == nil)
    }
}
```

- [ ] **Step 2: Run the focused tests and verify RED**

Run:

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -derivedDataPath /tmp/SiboyaDerivedData -only-testing:SiboyaTests/HomeWeeklyContentDocumentTests
```

Expected: build failure because `BundledHomeWeeklyContentLoader`, `HomeWeeklyContentDocument`, and `HomeWeeklyContent` do not exist yet.

- [ ] **Step 3: Add the minimal decoding model**

Create `Siboya/Features/Home/Model/HomeWeeklyContentDocument.swift`:

```swift
import Foundation

struct HomeWeeklyContentDocument: Decodable, Sendable {
    let weeks: [HomeWeeklyContent]

    func content(forGestationalWeek gestationalWeek: Int) -> HomeWeeklyContent? {
        weeks.first { $0.gestationalWeek == gestationalWeek }
    }
}

struct HomeWeeklyContent: Decodable, Sendable {
    let gestationalWeek: Int
    let headline: String
    let recommendedScriptID: UUID?
}
```

- [ ] **Step 4: Add the bundled resource loader**

Create `Siboya/Features/Home/Service/BundledHomeWeeklyContentLoader.swift`:

```swift
import Foundation

enum BundledHomeWeeklyContentLoader {
    static func load(from bundle: Bundle = .main) throws -> HomeWeeklyContentDocument {
        let resourceURL = bundle.url(
            forResource: "home-weekly-content",
            withExtension: "json",
            subdirectory: "Home"
        ) ?? bundle.url(
            forResource: "home-weekly-content",
            withExtension: "json"
        )

        guard let resourceURL else {
            throw HomeWeeklyContentLoadingError.resourceNotFound
        }

        let data = try Data(contentsOf: resourceURL)
        return try JSONDecoder().decode(HomeWeeklyContentDocument.self, from: data)
    }
}

enum HomeWeeklyContentLoadingError: Error {
    case resourceNotFound
}
```

- [ ] **Step 5: Add the approved 20–40 week JSON resource**

Create `Siboya/Resources/Home/home-weekly-content.json`:

```json
{
  "weeks": [
    { "gestationalWeek": 20, "headline": "아빠의 낮은 목소리가 잘 들리는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 21, "headline": "아기가 소리에 귀를 기울이기 시작하는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 22, "headline": "목소리에 반응해 꼼지락 움직이는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 23, "headline": "아빠의 다정한 억양을 알아채는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 24, "headline": "청각이 발달해 외부 소리를 구분하는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 25, "headline": "아빠와 대화하며 정서를 키워가는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 26, "headline": "아빠의 목소리를 머릿속에 기억하는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 27, "headline": "힘찬 태동으로 아빠에게 응답하는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 28, "headline": "아기의 감정이 더욱 풍부해지는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 29, "headline": "아빠의 목소리로 마음의 안정을 찾는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 30, "headline": "세상 밖 소리에 호기심이 많아지는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 31, "headline": "태어날 세상과의 첫 교감을 시작하는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 32, "headline": "목소리의 톤과 높낮이를 구분하는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 33, "headline": "아빠와의 대화에 더 적극적으로 반응하는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 34, "headline": "아빠 목소리를 들으며 안도감을 느끼는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 35, "headline": "아빠의 사랑을 온전히 받아들이는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 36, "headline": "세상에 나갈 준비를 차근차근 마치는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 37, "headline": "언제든 아빠를 만날 준비가 되어있는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 38, "headline": "아빠의 목소리로 편안하게 휴식하는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 39, "headline": "태어나 첫인사를 나눌 준비를 하는 시기", "recommendedScriptID": null },
    { "gestationalWeek": 40, "headline": "마침내 아빠와 눈을 맞추고 만날 시기", "recommendedScriptID": null }
  ]
}
```

- [ ] **Step 6: Run the focused tests and verify GREEN**

Run:

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -derivedDataPath /tmp/SiboyaDerivedData -only-testing:SiboyaTests/HomeWeeklyContentDocumentTests
```

Expected: `HomeWeeklyContentDocumentTests` passes with 3 tests and 0 failures.

- [ ] **Step 7: Run the complete unit test target**

Run:

```bash
xcodebuild test -project Siboya.xcodeproj -scheme Siboya -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -derivedDataPath /tmp/SiboyaDerivedData -only-testing:SiboyaTests
```

Expected: `** TEST SUCCEEDED **` with 0 failures.

- [ ] **Step 8: Commit the tested implementation**

```bash
git add Siboya/Features/Home/Model/HomeWeeklyContentDocument.swift Siboya/Features/Home/Service/BundledHomeWeeklyContentLoader.swift Siboya/Resources/Home/home-weekly-content.json SiboyaTests/Home/HomeWeeklyContentDocumentTests.swift
git commit -m "feat: add weekly home content resource"
```

