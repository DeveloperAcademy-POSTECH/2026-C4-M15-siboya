# Script Preview Components Design

## 목적

Home에서 대본·생각힌트 미리보기 화면을 조립하기 전에 Figma와 SSD의 표시 규칙을 독립적인 SwiftUI 컴포넌트로 구현한다. 이번 범위는 순수 표시와 사용자 callback 전달까지이며, 전체 화면 이동·SwiftData 조회·준비자세 모달·권한 요청은 포함하지 않는다.

## 기준 자료와 우선순위

1. 레이아웃, 이미지 배치, 텍스트 계층과 하단 버튼 구조는 Figma `대본&생각힌트 미리보기` 노드 `1009:11964`를 따른다.
2. 실제 주차, 제목, 소요 시간, 대본 문장, 빈칸 문장과 생각힌트는 `ScriptPreviewDTO` 값을 따른다.
3. Figma 샘플 문구와 번들 JSON이 다르면 `ScriptPreviewDTO` 값을 표시한다.
4. 새로 작성하거나 수정하는 Swift 코드에는 타입·프로퍼티·함수·핵심 레이아웃과 분기 이유를 설명하는 한국어 주석을 작성한다.

## 이미지 시리즈와 공통 표시 로직

현재 Home 전용 이름인 `HomeArtworkSeries`를 대본 도메인의 공통 `ScriptArtworkSeries`로 변경한다. 기존 1~7 순환 규칙은 그대로 유지하며 표시 위치별 에셋 이름을 다음처럼 계산한다.

| 표시 위치 | 에셋 이름 예시 |
|---|---|
| Home 대본 행 | `TitleImage1` |
| Home 추천 카드 | `TitleImage1Card` |
| 미리보기 132pt 대표 이미지 | `TitleImage1Thumbnail` |
| 미리보기 상단 배경 | `TitleImage1Back` |

- `TitleImage1~7Thumbnail`은 396×396px 이미지가 1x 슬롯에 등록되어 있으며 132×132pt 프레임에 축소 표시한다.
- `TitleImage1~7Back`은 402×396px 이미지가 1x 슬롯에 등록되어 있으며 화면 상단에 정렬한다.
- 기존 `HomeArtworkView`는 대본 공통 `ScriptArtworkView`로 변경한다. Home과 미리보기 모두 같은 이미지 존재 확인과 동일 크기 박스 fallback을 사용한다.
- 등록되지 않은 이미지 이름이나 공백 이름은 데이터 로딩 실패로 취급하지 않고 해당 이미지 영역만 중립색 박스로 대체한다.

## 컴포넌트 구성

### `ScriptPreviewHero`

- `ScriptArtworkSeries`, 대상 임신 주차와 제목을 입력받는다.
- `TitleImageNBack`을 상단 정렬 배경으로 표시하고 아래로 갈수록 `Color(.systemBackground)`에 섞이는 그라데이션을 둔다.
- `TitleImageNThumbnail`을 132×132pt, 모서리 반경 32pt로 표시한다.
- 대표 이미지 아래에 `N주차`와 대본 제목을 semantic font로 표시한다.
- 뒤로가기 버튼은 이 컴포넌트에 포함하지 않는다. 전체 View가 `NavigationStack`의 시스템 navigation bar를 사용한다.

### `ScriptPreviewDuration`

- `estimatedDurationSeconds: Int?`를 입력받는다.
- 값이 있으면 60초 단위로 올림해 `약 N분`을 표시한다. 예를 들어 35초는 `약 1분`, 61초는 `약 2분`이다.
- 값이 `nil`이면 소요 시간 영역 전체를 표시하지 않는다.
- `소요시간` caption과 계산된 시간을 하나의 세로 텍스트 묶음으로 가운데 정렬한다.
- 텍스트 묶음의 좌우에는 1pt 세로 separator를 두며, 각 선은 두 텍스트를 함께 감싸도록 묶음의 전체 높이에 자동으로 맞춘다.
- 가로 separator는 사용하지 않는다.

### `ScriptPreviewBody`

- `[ScriptSentenceDTO]`, `bucketListPrompt`, `bucketListGuide`를 입력받는다.
- 일반 문장은 상위 계층이 검증해 전달한 배열 순서를 그대로 유지해 표시한다. `ScriptSentenceDTO.index`를 기준으로 컴포넌트 내부에서 다시 정렬하지 않는다.
- 일반 문장 뒤에는 시각적 간격을 두고 빈칸 문장을 표시한다.
- 마지막에는 Figma와 SSD대로 `💡` 컬러 이모지를 앞뒤에 유지한 생각힌트를 표시한다.
- VoiceOver에는 장식용 이모지를 반복해서 읽히지 않고 `생각힌트: {bucketListGuide}`로 전달한다.
- 본문은 `Color.secondary`와 semantic body font를 사용해 Dynamic Type과 다크 모드에 대응한다.

### `ScriptPreviewBottomBar`

- `onPrepare: () -> Void` callback을 입력받는다.
- 스크롤 내용과 버튼 사이에 투명색에서 시스템 배경색으로 이어지는 세로 그라데이션을 표시한다.
- 기존 공통 `PrimaryButton`을 `준비하기` 제목으로 재사용한다.
- 버튼은 callback만 전달하며 준비자세 모달, 권한 요청이나 카운트다운을 직접 시작하지 않는다.

## 데이터 흐름

```text
ScriptPreviewDTO + ScriptArtworkSeries
├── ScriptPreviewHero
├── ScriptPreviewDuration
├── ScriptPreviewBody
└── ScriptPreviewBottomBar → onPrepare
```

전체 미리보기 View를 구현할 때 상위 조정자가 선택한 대본의 JSON 배열 위치를 기준으로 `ScriptArtworkSeries`를 결정하고, 태명이 치환된 `ScriptPreviewDTO`와 함께 컴포넌트에 전달한다. 이번 컴포넌트 작업에서는 JSON 조회, 프로필 조회와 시리즈 선택을 수행하지 않는다.

## 오류·빈 값 정책

- Thumbnail 또는 Back 에셋 누락: 해당 프레임만 동일 크기의 박스로 표시한다.
- 소요 시간 누락: 소요 시간 컴포넌트를 숨긴다.
- 빈 문장이나 잘못된 DTO: 상위 로더·상태 생성기의 검증 책임이며 컴포넌트가 오류 UI나 새로고침을 만들지 않는다.
- Home 기존 이미지 이름과 선택 callback 동작은 공통 타입 이름 변경 후에도 유지한다.

## 접근성

- 주차, 제목, 본문, 생각힌트와 버튼은 semantic font를 사용한다.
- 대표 이미지와 배경은 장식 이미지로 취급해 VoiceOver 순서를 방해하지 않는다.
- 생각힌트는 `생각힌트: {내용}`이라는 하나의 접근성 요소로 제공한다.
- `PrimaryButton`의 기존 접근성 label과 최소 터치 높이를 유지한다.

## 테스트와 Preview

- `ScriptArtworkSeries`가 1번과 7번의 행·카드·Thumbnail·Back 이름을 정확히 계산하고 8번째에서 1번으로 순환하는지 검증한다.
- 35초, 60초와 61초가 각각 `약 1분`, `약 1분`, `약 2분`이 되는지 검증한다.
- `nil` 소요 시간은 표시 값이 없는지 검증한다.
- 본문이 입력 문장 배열 순서를 유지하고 일반 문장 → 빈칸 문장 → 생각힌트 순서로 표시되는지 검증한다.
- `준비하기` 선택이 `onPrepare`를 정확히 한 번 호출하는지 검증한다.
- 등록 에셋, 누락 에셋, 긴 제목·본문, 다크 모드와 접근성 글자 크기 Preview를 제공한다.
- Home 집중 테스트와 전체 `SiboyaTests`, SwiftLint, iOS Simulator Debug 빌드를 실행해 공통 이미지 타입 변경의 회귀를 확인한다.

## 완료 조건

1. 네 컴포넌트가 `Siboya/Features/Home/Component` 아래에 역할별 파일로 존재한다.
2. 132pt 대표 이미지는 `TitleImage1~7Thumbnail`, 상단 배경은 `TitleImage1~7Back`을 사용한다.
3. 생각힌트에는 `💡` 이모지를 유지한다.
4. Home 화면의 기존 이미지와 선택 동작이 변하지 않는다.
5. 모든 신규·수정 Swift 코드와 테스트에 이해 가능한 한국어 주석이 있다.
6. 집중 테스트, 전체 테스트, SwiftLint와 시뮬레이터 빌드가 통과한다.
