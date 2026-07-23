# Script Preview Flow Design

## 목적

Home에서 선택한 대본을 전체 화면 미리보기로 열고, 기존 미리보기 컴포넌트를 조립해 실제 번들 대본을 표시한다. 사용자가 준비하기를 선택하면 준비자세 sheet를 열고, 시작하기에서 마이크와 Speech 권한을 확인한 뒤에만 기존 `TaedamScreen`으로 이동한다.

이번 설계는 다음 범위를 하나의 검증 가능한 흐름으로 연결한다.

1. Home 대본 선택과 전체 화면 이동
2. SwiftData `BabyProfile`과 번들 대본을 이용한 `TaedamSessionInputDTO` 생성
3. 대본·생각힌트 미리보기 View
4. 준비자세 bottom sheet
5. 마이크·Speech 권한 확인과 요청
6. 거부 시 설정 안내 Alert
7. 권한 승인 후 기존 `TaedamScreen` 표시

STT, 키보드 수정, 저장과 결과 화면의 신규 구현은 이번 범위에 포함하지 않는다. 이번 작업은 현재 존재하는 `TaedamScreen` 진입까지 연결한다.

## 기준 자료와 우선순위

1. 미리보기 레이아웃은 Figma `대본&생각힌트 미리보기` 노드 `1009:11964`를 따른다.
2. 준비자세 sheet는 Figma `준비자세` 노드 `1009:12106`을 따른다.
3. 권한 안내는 Figma `마이크권한 허용` 노드 `1009:12161`과 `docs/design/taedam-session-spec.md`를 따른다.
4. 실제 주차, 제목, 시간, 문장, 빈칸 문장과 생각힌트는 번들 JSON에서 만든 `TaedamSessionInputDTO`를 따른다.
5. 이미지 시리즈는 선택 경로와 무관하게 `taedam-scripts.json` 배열에서 해당 대본이 위치한 인덱스로 결정한다.
6. 신규·수정 Swift 코드에는 타입, 상태, 함수, 핵심 분기와 레이아웃의 이유를 설명하는 한국어 주석을 작성한다.

## 권장 구조

화면 이동과 시스템 기능은 상위 조정자가 담당하고, 실제 View는 전달된 상태와 callback만 소비한다.

```text
Siboya/Features/Home
├── View
│   ├── ContentView.swift
│   ├── HomeView.swift
│   ├── ScriptPreviewView.swift
│   └── TaedamPreparationView.swift
├── Model
│   ├── HomeScreenModel.swift
│   ├── ScriptSelectionDTO.swift
│   ├── ScriptPreviewRoute.swift
│   └── ScriptPreviewFlowModel.swift
└── Service
    └── TaedamPermissionAuthorizer.swift
```

View 파일은 사용자의 폴더 규칙에 따라 모두 `Siboya/Features/Home/View` 아래에 둔다. 화면 조정용 모델과 권한 서비스도 Home 기능 내부에 둔다.

## 선택과 데이터 조회

### `ScriptSelectionDTO`

Home 카드와 행이 현재 전달하는 `scriptID`, `scriptVersion`을 하나의 값으로 묶는다.

```swift
struct ScriptSelectionDTO: Equatable, Sendable {
    let scriptID: UUID
    let scriptVersion: Int
}
```

### `ScriptPreviewRoute`

미리보기 화면을 여는 데 필요한 값만 보관한다.

```swift
struct ScriptPreviewRoute: Identifiable, Equatable, Sendable {
    let sessionInput: TaedamSessionInputDTO
    let artworkSeries: ScriptArtworkSeries

    var id: String {
        "\(sessionInput.script.scriptID.uuidString)-\(sessionInput.script.scriptVersion)"
    }
}
```

### `HomeScreenModel` 확장

`load(repository:)`에서 읽은 유효한 프로필과 대본 문서를 화면 상태와 함께 보관한다. Home에서 대본을 선택하면 다음 순서로 `ScriptPreviewRoute`를 만든다.

1. `scriptID`와 `scriptVersion`이 모두 같은 대본과 배열 인덱스를 찾는다.
2. trim 후 비어 있지 않은 `BabyProfile.nickname`이 있는지 확인한다.
3. `TaedamScriptContent.makeSessionInput(babyNickname:)`으로 태명을 한 번 치환한다.
4. 대본 배열 인덱스로 `ScriptArtworkSeries.cycling(forZeroBasedIndex:)`를 만든다.
5. 완성된 세션 입력과 이미지 시리즈를 `ScriptPreviewRoute`로 반환한다.

프로필 또는 정확한 버전의 대본이 없으면 `nil`을 반환한다. `ContentView`는 이 경우 navigation destination을 만들지 않으며 Alert나 새로고침을 표시하지 않는다.

## 전체 화면 이동

`ContentView`가 앱 조립과 Home 흐름의 navigation 상태를 소유한다.

```text
NavigationStack
└── HomeView
    └── 대본 선택
        └── ScriptPreviewRoute 생성 성공
            └── ScriptPreviewView push
```

- `HomeView`와 기존 Home 컴포넌트는 지금처럼 UUID와 버전을 callback으로 전달한다.
- `ContentView`가 callback을 `ScriptSelectionDTO`로 바꾸고 `HomeScreenModel`에 route 생성을 요청한다.
- route 생성에 성공했을 때만 시스템 `NavigationStack` destination으로 `ScriptPreviewView`를 push한다.
- 미리보기의 뒤로가기는 별도 버튼을 그리지 않고 시스템 navigation bar의 `chevron.backward`와 interactive pop gesture를 사용한다.
- Home의 탭 bar는 미리보기 destination에 표시하지 않는다.

## `ScriptPreviewView`

`ScriptPreviewView`는 `ScriptPreviewRoute`와 권한 서비스를 입력받아 기존 네 컴포넌트를 조립한다.

### 레이아웃

1. 화면 배경은 `Color(.systemBackground)`을 사용한다.
2. 하나의 세로 `ScrollView`에 `ScriptPreviewHero`, `ScriptPreviewDuration`, `ScriptPreviewBody`를 순서대로 배치한다.
3. Hero는 `TitleImageNBack`을 상단 정렬 배경으로, `TitleImageNThumbnail`을 132×132pt 대표 이미지로 사용한다.
4. 본문은 좌우 20pt 안쪽에 두고 입력 문장 수와 Dynamic Type에 따라 세로로 확장한다.
5. `ScriptPreviewBottomBar`는 `.safeAreaInset(edge: .bottom)`으로 고정한다.
6. 뒤로가기 외의 navigation title은 표시하지 않는다.

### 표시 값

- Hero: route의 이미지 시리즈, `targetGestationalWeek`, `title`
- 소요 시간: `estimatedDurationSeconds`
- 본문: `sentences`, `bucketListPrompt`, `bucketListGuide`
- 하단 버튼: 준비자세 표시 callback

준비하기를 연속으로 눌러도 sheet는 하나만 표시한다.

## `TaedamPreparationView`

준비자세 View는 태명, 권한 요청 진행 여부, 닫기와 시작 callback만 받는 순수 View다.

### 표시

- 시스템 `.sheet`와 약 87% 높이의 `.fraction(0.87)` detent를 사용해 Figma처럼 화면 상단 일부를 남긴다.
- 시스템 dim 배경과 drag indicator를 사용한다.
- 우측 상단에 `xmark` 닫기 버튼을 둔다.
- 중앙 상단 이미지는 사용자가 등록한 `img_profile`을 사용한다. 에셋 조회 실패 시 같은 크기의 중립색 박스를 표시한다.
- 제목은 `태담 준비하기`다.
- 안내 문구는 다음처럼 태명을 주입한다.

```text
아내의 배에 손을 얹고
{babyNickname}와 교감할 준비가 되면
시작 버튼을 눌러주세요
```

- 하단에는 기존 `PrimaryButton`을 `시작하기` 제목으로 고정한다.
- 권한 요청 중에는 시작 버튼을 비활성화해 중복 요청을 막는다.

닫기 버튼과 drag dismiss는 동일하게 sheet만 닫는다. 권한 요청, 세션 이동 또는 카운트다운은 시작하지 않으며 미리보기 View와 route는 그대로 유지한다.

## 권한 서비스

`TaedamPermissionAuthorizing`은 View와 Apple 권한 API를 분리한다.

```swift
enum TaedamPermissionIssue: Equatable, Sendable {
    case microphone
    case speechRecognition
}

enum TaedamPermissionResult: Equatable, Sendable {
    case granted
    case denied(TaedamPermissionIssue)
}

protocol TaedamPermissionAuthorizing: Sendable {
    func requestRequiredPermissions() async -> TaedamPermissionResult
}
```

실제 구현은 iOS 26.5 SDK에서 권장되는 다음 API를 사용한다.

- 마이크 상태: `AVAudioApplication.shared.recordPermission`
- 마이크 요청: `AVAudioApplication.requestRecordPermission`
- Speech 상태: `SFSpeechRecognizer.authorizationStatus()`
- Speech 요청: `SFSpeechRecognizer.requestAuthorization(_:)`

마이크를 먼저 확인하고 허용된 경우에만 Speech를 확인한다. 상태가 `undetermined` 또는 `notDetermined`이면 시스템 요청을 표시한다. 거부 또는 제한 상태는 해당 권한 종류를 담은 `.denied`로 반환한다.

프로젝트의 생성 Info.plist 설정에는 다음 키를 Debug와 Release 구성 모두에 추가한다.

```text
NSMicrophoneUsageDescription = 태담 진행과 버킷리스트 음성 입력을 위해 마이크 접근이 필요합니다.
NSSpeechRecognitionUsageDescription = 말한 약속을 텍스트로 변환하기 위해 음성 인식 접근이 필요합니다.
```

기존 사용자의 `DEVELOPMENT_TEAM` 설정과 다른 프로젝트 변경은 그대로 보존한다.

## `ScriptPreviewFlowModel`

권한 요청과 sheet·세션 전환 순서를 메인 액터에서 관리한다.

### 상태

- `isPreparationPresented`: 준비자세 sheet 표시 여부
- `isRequestingPermission`: 권한 확인·요청 진행 여부
- `permissionAlertIssue`: 표시할 마이크 또는 Speech 권한 안내
- `shouldStartSessionAfterDismissal`: 권한 승인 후 sheet 종료를 기다리는 상태
- `isSessionPresented`: 기존 `TaedamScreen` 전체 화면 표시 여부

### 전이

```text
미리보기
└── 준비하기
    └── 준비자세 sheet
        ├── 닫기 또는 drag dismiss → 미리보기 유지
        └── 시작하기
            ├── 요청 중 → 추가 입력 무시
            ├── 마이크 거부 → 마이크 설정 Alert
            ├── Speech 거부 → Speech 설정 Alert
            └── 모두 승인
                ├── 세션 시작 대기 표시
                ├── sheet dismiss
                └── sheet onDismiss 이후 TaedamScreen 표시
```

권한이 승인되어도 sheet가 화면에 있거나 사라지는 중에는 세션을 표시하지 않는다. `.sheet(onDismiss:)`가 호출된 뒤에만 `isSessionPresented`를 활성화해 `TaedamScreen`의 3초 카운트다운이 한 번만 시작되게 한다.

설정 앱에서 돌아와도 자동 시작하지 않는다. 사용자가 준비자세 sheet에서 시작하기를 다시 선택할 때 권한을 다시 확인한다.

## 권한 안내 Alert

Figma의 glass Alert는 SwiftUI 시스템 `.alert`로 구현해 시스템 접근성과 버튼 동작을 유지한다.

### 마이크

```text
음성기능을 사용하시려면 [설정
> 개인정보보호 > 마이크]에서
태담앱의 접근을 허용해 주세요.
```

### Speech

```text
음성 인식 기능을 사용하시려면 설정에서 태담앱의 음성 인식 접근을 허용해 주세요.
```

- `닫기`: Alert만 닫고 준비자세 sheet를 유지한다.
- `설정`: `UIApplication.openSettingsURLString`을 열고 Alert를 닫는다.
- 설정 이동 실패 시에도 sheet를 유지하며 자동 세션 이동은 하지 않는다.

## `TaedamScreen` 연결

- `ScriptPreviewView`는 권한 승인과 sheet 종료가 모두 완료되면 `.fullScreenCover`로 기존 `TaedamScreen(input:)`을 표시한다.
- 동일한 `TaedamSessionInputDTO`를 미리보기, 준비자세와 태담 화면 전환 전체에서 유지한다.
- `TaedamScreen`의 뒤로가기 또는 완료 callback은 full-screen cover를 닫고 같은 미리보기로 돌아온다.
- 기존 `TaedamScreen`의 카운트다운, 대본 자동 진행과 문장 선택 로직은 수정하지 않는다.

## 오류와 중복 입력 정책

- 선택 대본 또는 프로필 누락: 미리보기 navigation을 시작하지 않는다.
- Thumbnail, Back 또는 `img_profile` 누락: 해당 프레임만 박스로 대체한다.
- 준비하기 중복 선택: 하나의 sheet만 유지한다.
- 시작하기 중복 선택: 첫 권한 요청이 끝날 때까지 무시한다.
- 권한 거부: 해당 Alert를 표시하고 sheet를 유지한다.
- 설정 앱 복귀: 자동 시작하지 않는다.
- 권한 승인: sheet가 완전히 닫힌 후 세션을 한 번만 표시한다.

## 접근성

- 미리보기는 기존 semantic font와 컴포넌트 접근성 계약을 유지한다.
- 시스템 navigation bar, sheet, drag indicator와 Alert를 사용해 VoiceOver와 키보드 동작을 보존한다.
- `img_profile`, Back 이미지와 Thumbnail은 장식 이미지로 처리한다.
- 준비자세 안내는 제목과 본문 순서로 읽히며 시작·닫기 버튼에 명확한 접근성 label을 제공한다.
- 권한 요청 중인 시작 버튼은 비활성 상태를 VoiceOver에도 전달한다.

## 테스트 전략

### 선택과 route 생성

- 같은 UUID라도 버전이 다르면 정확한 버전만 선택한다.
- 대본 JSON 인덱스에 따라 이미지 시리즈가 결정된다.
- 프로필 태명이 문장, 빈칸 문장과 생각힌트에 치환된다.
- 프로필 또는 선택 대본이 없으면 route를 만들지 않는다.

### 흐름 상태

- 준비하기를 여러 번 선택해도 sheet는 하나만 열린다.
- 권한 요청 중 시작하기 재선택을 무시한다.
- 마이크·Speech 거부 결과가 각각 올바른 Alert 상태를 만든다.
- 권한 승인 직후에는 세션이 열리지 않고 sheet `onDismiss` 이후에만 열린다.
- sheet를 직접 닫으면 세션을 시작하지 않는다.
- 설정 Alert를 닫거나 설정 앱을 연 뒤에도 자동 시작하지 않는다.

### View와 회귀

- 미리보기 View가 route의 네 컴포넌트 입력을 그대로 사용한다.
- 준비자세 View가 태명을 포함한 안내 문구와 `img_profile`을 사용한다.
- 전체 `SiboyaTests`, SwiftLint와 iOS Simulator Debug 빌드를 실행한다.
- iPhone 17 Pro 기준 미리보기, 준비자세 sheet와 권한 Alert를 실행해 Figma 구조와 비교한다.

## 완료 조건

1. `ScriptPreviewView.swift`와 `TaedamPreparationView.swift`가 `Siboya/Features/Home/View` 아래에 존재한다.
2. Home 카드와 행 선택이 정확한 대본·버전의 미리보기로 이동한다.
3. SwiftData 태명이 미리보기와 준비자세 안내에 반영된다.
4. 기존 네 미리보기 컴포넌트가 실제 전체 View에 조립된다.
5. 준비하기는 준비자세 sheet만 열고 직접 권한이나 카운트다운을 시작하지 않는다.
6. 시작하기가 마이크와 Speech 권한을 확인하며 요청 중 중복 입력을 막는다.
7. 거부 시 닫기·설정 Alert가 표시되고 설정 복귀 후 자동 시작하지 않는다.
8. 모두 허용된 경우 sheet 종료 후에만 기존 `TaedamScreen`이 한 번 표시된다.
9. Debug와 Release 모두 권한 사용 설명 키를 가진다.
10. 신규·수정 Swift 코드와 테스트에 이해 가능한 한국어 주석이 있다.
11. 사용자 소유의 프로젝트와 에셋 변경이 보존된다.
12. 집중 테스트, 전체 테스트, SwiftLint와 Debug 빌드가 통과한다.
