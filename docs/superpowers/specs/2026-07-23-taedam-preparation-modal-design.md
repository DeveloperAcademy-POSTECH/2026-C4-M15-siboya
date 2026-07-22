# 태담 준비자세 모달 설계

## 목적과 기준

대본 미리보기의 `준비하기`에서 표시되는 준비자세 bottom sheet를 SSD와 Figma `준비자세` 노드 `1009:12106`에 맞게 완성한다. 기존 `ScriptPreviewFlowModel`의 권한·화면 전환 계약은 유지하고, 이번 범위는 준비자세 표시 컴포넌트와 모달 조립을 명확히 분리하는 데 집중한다.

## 확인한 플로우

1. 미리보기의 `준비하기`는 준비자세 sheet만 한 번 표시한다.
2. 닫기 버튼과 grabber drag dismiss는 권한이나 세션을 시작하지 않고 동일한 미리보기로 돌아간다.
3. 준비자세의 `시작하기`는 상위 callback으로 권한 확인을 요청한다.
4. 권한 요청 중에는 시작 버튼을 비활성화하고 로딩 상태를 표시한다.
5. 권한 거부 시 sheet를 유지한 채 설정 안내 Alert를 표시한다.
6. 권한 승인 시 sheet를 먼저 닫고, `onDismiss` 이후에만 기존 `TaedamScreen`을 표시한다.

View는 마이크·Speech API와 카운트다운을 직접 호출하지 않는다. `ScriptPreviewFlowModel`과 `TaedamPermissionAuthorizing`이 이 책임을 계속 담당한다.

## 접근안 비교

### 1. 단일 View 수치 조정

기존 `TaedamPreparationView` 안에서 이미지, 안내, 버튼을 함께 수정한다. 파일 수는 적지만 각 요소의 규격과 동작을 독립적으로 검증하기 어렵다.

### 2. 표시 컴포넌트 분리 — 채택

이미지, 안내, 시작 버튼을 각각 순수 SwiftUI 컴포넌트로 분리한다. 모달 View는 sheet 내부 배치와 닫기 callback만 담당하고, 미리보기와 권한 흐름은 기존 구현을 재사용한다. 사용자 요청의 `Home/View`와 `Home/Component` 경계를 유지하면서 Figma 수치를 테스트 가능한 계약으로 만들 수 있다.

### 3. 모달 전용 Coordinator 추가

준비자세 전용 상태 모델을 새로 만들 수 있으나 이미 `ScriptPreviewFlowModel`이 sheet, 권한, 세션 순서를 관리한다. 동일 상태가 두 곳으로 나뉘므로 이번 범위에는 적용하지 않는다.

## 컴포넌트 구조

### `TaedamPreparationArtwork`

- 위치: `Siboya/Features/Home/Component/TaedamPreparationArtwork.swift`
- 입력: Asset Catalog 이름
- 기본 에셋: `img_profile`
- Figma 크기: 너비 `90pt`, 높이 `88pt`
- 실제 이미지는 비율을 유지해 프레임 안에 맞춘다.
- 에셋이 없으면 같은 크기의 중립색 rounded rectangle을 표시한다.
- 장식 이미지이므로 VoiceOver에서 숨긴다.

### `TaedamPreparationGuidance`

- 위치: `Siboya/Features/Home/Component/TaedamPreparationGuidance.swift`
- 입력: `babyNickname`
- 제목: `태담 준비하기`, `28pt Bold`
- 안내: `22pt Regular`, semantic secondary color, 가운데 정렬
- 제목과 안내 간격: `8pt`
- 안내 문구:

```text
아내의 배에 손을 얹고
{babyNickname}와 교감할 준비가 되면
시작 버튼을 눌러주세요
```

### `TaedamPreparationStartButton`

- 위치: `Siboya/Features/Home/Component/TaedamPreparationStartButton.swift`
- 입력: `isLoading`, `action`
- 제목: `시작하기`, `16pt Semibold`
- 높이: `52pt`, capsule, `Color.primaryRed`
- 로딩 중에는 `ProgressView`를 표시하고 중복 탭을 막는다.
- 접근성 label과 처리 중 value를 제공한다.

## 모달 View 조립

`TaedamPreparationView`는 `Siboya/Features/Home/View`에 유지한다.

- 시스템 `.sheet`와 `.fraction(0.95)` detent를 사용한다. 시스템 fraction은 안전 영역을 제외한 최대 detent를 기준으로 하므로, 이 값이 전체 화면에서 Figma의 약 87% 높이를 재현한다.
- 시스템 dim과 drag indicator를 유지한다.
- 우측 상단 닫기는 iOS 26 glass button과 `xmark`를 사용한다. 시스템 chrome 여백과 `22pt` label을 조합해 외곽과 터치 영역을 약 `44×44pt`로 유지한다.
- header 아래 `52pt` 뒤에 `TaedamPreparationArtwork`를 배치한다.
- 이미지 아래 `67pt` 뒤에 `TaedamPreparationGuidance`를 배치한다.
- 시작 버튼은 좌우 `20pt`, 하단 `22pt` 여백으로 고정한다.
- sheet 배경은 `Color(.systemBackground)`을 사용한다.

고정 값은 일반 글자 크기에서 Figma의 좌표를 맞춘다. 유연한 spacer가 먼저 줄어들게 해 큰 글자에서도 제목·안내와 버튼의 충돌을 줄인다.

## 데이터와 이벤트

```text
ScriptPreviewRoute.babyNickname
  → TaedamPreparationView
    → TaedamPreparationGuidance

닫기 / drag dismiss
  → ScriptPreviewFlowModel.dismissPreparation()

시작하기
  → ScriptPreviewFlowModel.requestPermissions()
    → denied: 설정 Alert, sheet 유지
    → granted: sheet dismiss
      → onDismiss
        → TaedamScreen 표시
```

## 오류와 접근성

- `img_profile` 누락은 화면 실패가 아니며 placeholder로 대체한다.
- 빈 태명은 상위 route 생성 단계에서 차단하는 기존 계약을 유지한다.
- 권한 요청 중 추가 시작 입력은 View와 flow model 양쪽에서 차단한다.
- 닫기 버튼은 `준비자세 닫기`, 시작 버튼은 `시작하기` 접근성 label을 제공한다.
- semantic background와 label color를 사용해 다크 모드에 대응한다.

## 테스트와 완료 조건

1. 세 컴포넌트의 Figma 크기·간격·문구·색상·로딩 계약을 단위 테스트한다.
2. `TaedamPreparationView`가 Figma 배치 상수와 전달받은 태명을 유지하는지 검증한다.
3. 실제 Home → 미리보기 → 준비자세 sheet 경로에서 제목, 안내, 시작·닫기 버튼을 확인한다.
4. 닫은 뒤 같은 미리보기로 돌아오는지 UI 테스트한다.
5. 기존 권한 승인·거부·sheet dismissal 단위 테스트에 회귀가 없어야 한다.
6. 전체 `SiboyaTests`, SwiftLint와 Debug Simulator 빌드가 통과해야 한다.
7. 신규·수정 Swift 코드와 테스트에는 역할과 이유를 설명하는 한국어 주석을 작성한다.
8. 사용자 소유 `project.pbxproj`와 `img_profile` staged 변경은 수정하거나 커밋하지 않는다.
