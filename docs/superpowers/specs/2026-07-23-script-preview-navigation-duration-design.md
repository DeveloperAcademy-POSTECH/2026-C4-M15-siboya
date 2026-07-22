# Script Preview Navigation and Duration Design

## 목적

Home에서 대본 미리보기로 이동했을 때 SSD가 요구하는 시스템 뒤로가기 버튼을 안정적으로 표시하고, `ScriptPreviewDuration`을 Figma의 실제 타이포그래피와 간격에 맞는 크기로 확대한다.

## 기준 자료와 우선순위

1. 기능과 이동 계약은 `docs/design/taedam-session-spec.md` 및 `docs/superpowers/specs/2026-07-22-script-preview-flow-design.md`를 따른다.
2. 화면 크기와 간격은 Figma `대본&생각힌트 미리보기` 노드 `1009:11964`를 따른다.
3. SSD가 명시한 세로 separator 두께 `1pt`는 Figma의 `0.5pt`보다 우선한다.
4. 실제 문구와 소요 시간 값은 기존 번들 JSON과 `ScriptPreviewDuration.durationText` 변환 결과를 유지한다.
5. 신규·수정 Swift 코드와 테스트에는 역할, 상호작용과 검증 의도를 설명하는 한국어 주석을 작성한다.

## 조사 결과

### 뒤로가기 버튼

- SSD는 미리보기의 뒤로가기를 커스텀 버튼이 아닌 `NavigationStack`의 시스템 `chevron.backward`로 구현하도록 명시한다.
- 현재 `ContentView`는 `NavigationStack(path:)`에 `ScriptPreviewRoute`를 추가해 `ScriptPreviewView`를 push하며, `navigationBarBackButtonHidden`은 사용하지 않는다.
- 현재 커밋을 iPhone 17 Pro, iOS 26.5 Simulator에서 Home → Preview 순서로 실행했을 때 화면 좌측 상단에 시스템 뒤로가기 버튼이 표시됐고 접근성 트리에서도 `BackButton`을 확인했다.
- 현재 구조는 정상이나 navigation bar 표시 여부를 암묵적 기본값에 맡기고 있으므로 미리보기에서 navigation bar를 명시적으로 보이게 해 상위 modifier나 향후 변경의 영향을 차단한다.

### `ScriptPreviewDuration`

- 현재 `소요시간`은 `.caption`, 시간은 `.subheadline`을 사용하고 텍스트 묶음 가장자리에 separator를 overlay한다.
- Figma는 `소요시간`을 13pt Footnote, `약 N분`을 20pt Title3 Semibold로 사용한다.
- Figma의 중앙 영역은 기본 너비 `73pt`, 내부 여백 `10pt`, 텍스트 간격 `4pt`이며 양쪽 `35pt` 세로선과 중앙 영역 사이는 각각 `18pt`다.
- 현재 구현은 시간 글꼴, 내부 여백과 선 사이 간격이 모두 작아 전체 컴포넌트가 Figma보다 축소돼 보인다.

## 선택한 설계

### 시스템 뒤로가기 유지

`ScriptPreviewView`는 기존 `NavigationStack` push와 시스템 back 버튼을 그대로 사용한다.

- `.toolbar(.visible, for: .navigationBar)`를 적용해 navigation bar 표시를 명시한다.
- `.toolbarBackground(.hidden, for: .navigationBar)`는 유지해 Hero 배경이 화면 최상단까지 보이게 한다.
- 커스텀 `ToolbarItem`, 별도 `dismiss` 버튼과 `navigationBarBackButtonHidden(true)`는 추가하지 않는다.
- 따라서 시스템 back swipe, 접근성 label과 iOS 26의 navigation bar 버튼 표현을 그대로 보존한다.

### Duration 레이아웃 확대

`ScriptPreviewDuration`은 overlay 대신 구조가 드러나는 가로 묶음으로 구성한다.

```text
1pt × 35pt separator
        ↕ center aligned
18pt spacing
73pt 이상 중앙 영역
  ├─ 10pt 내부 여백
  ├─ 소요시간: Footnote 13pt
  ├─ 4pt spacing
  └─ 약 N분: Title3 20pt Semibold
18pt spacing
1pt × 35pt separator
```

- 중앙 영역은 일반 글자 크기에서 Figma의 `73pt`를 유지하고 Dynamic Type에서는 잘리지 않도록 최소 너비로 취급한다.
- 양쪽 separator는 Figma처럼 중앙 영역과 분리된 고정 `35pt` 높이로 가운데 정렬한다.
- 기존 `durationText`의 분 올림, `nil`일 때 전체 숨김과 하나의 접근성 요소 결합은 유지한다.
- 텍스트 색상과 `ScriptPreviewView`에서 Duration 위에 주는 `8pt` 간격은 이번 크기 수정 범위에서 변경하지 않는다.

## 변경 범위

- `Siboya/Features/Home/View/ScriptPreviewView.swift`
  - navigation bar를 명시적으로 표시한다.
- `Siboya/Features/Home/Component/ScriptPreviewDuration.swift`
  - Figma 기준 타이포그래피와 구조적 간격을 적용한다.
- `SiboyaTests/Home/ScriptPreviewComponentsTests.swift`
  - Duration 표시값과 레이아웃 수치, 일반 글자 크기 및 Dynamic Type 확장을 검증한다.
- `SiboyaUITests/SiboyaUITests.swift`
  - 기존 UI Test 타깃에서 Home 대본을 선택한 뒤 시스템 `BackButton`의 존재와 Home 복귀를 검증한다.
  - 수정하는 기존 Xcode 템플릿 주석도 프로젝트 규칙에 맞게 한국어로 정리한다.

권한, sheet, Alert, `TaedamScreen`, Hero safe-area 배치, Home 데이터 조회와 사용자 소유 프로젝트·에셋 변경은 수정하지 않는다.

## 테스트

1. 35초, 60초, 61초와 `nil`의 기존 표시값 테스트를 유지한다.
2. separator 두께 `1pt`, 높이 `35pt`, 선 사이 간격 `18pt`, 중앙 최소 너비 `73pt`, 내부 여백 `10pt` 계약을 검증한다.
3. 일반 글자 크기에서 Duration의 fitting size가 최소 `111×67pt`이고, 접근성 글자 크기에서 높이와 필요 너비가 확장되는지 검증한다.
4. UI Test에서 Home의 대본 행을 선택해 미리보기로 이동하고 시스템 `BackButton`이 나타나는지 확인한다.
5. 같은 UI Test에서 뒤로가기를 선택하면 Home의 대본 목록이 다시 표시되는지 확인한다.
6. 관련 단위 테스트, UI Test, 전체 `SiboyaTests`, SwiftLint와 Debug Simulator 빌드를 실행한다.

## 제외한 접근

- 커스텀 원형 뒤로가기 버튼: SSD의 시스템 navigation 계약과 interactive pop 동작을 중복 구현하므로 제외한다.
- Figma의 separator `0.5pt`를 그대로 사용: 승인된 SSD가 `1pt`를 명시하므로 제외한다.
- 시간 글꼴만 확대: 중앙 여백과 선 간격이 계속 작아 전체 컴포넌트 크기 문제가 남으므로 제외한다.

## 완료 조건

1. Home → Preview 이동 시 시스템 뒤로가기 버튼이 표시되고 Home으로 복귀한다.
2. Hero의 화면 최상단 배치와 투명 navigation bar가 유지된다.
3. Duration이 승인된 Figma 수치와 SSD의 1pt 세로선 계약을 함께 만족한다.
4. `nil` 소요 시간, Dynamic Type, 기존 준비자세·권한·세션 흐름에 회귀가 없다.
5. 신규·수정 Swift 코드와 테스트의 주석이 한국어로 작성된다.
