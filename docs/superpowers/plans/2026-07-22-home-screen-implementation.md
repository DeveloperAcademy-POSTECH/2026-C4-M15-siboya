# Home Screen Implementation Plan

> 설계 기준: `docs/superpowers/specs/2026-07-22-home-screen-design.md`

## 목표

번들 Home/대본 데이터와 SwiftData의 아기 프로필을 표시 상태로 변환하고, 역할별 이미지 에셋을 사용하는 Home 화면을 Figma 구조에 맞춰 완성한다.

## 1. 이미지 시리즈 계약을 테스트로 고정

**수정 파일**

- `SiboyaTests/Home/HomeComponentsTests.swift`
- `Siboya/Features/Home/Model/HomeArtworkSeries.swift`
- `Siboya/Features/Home/Model/HomeScriptItem.swift`
- `Siboya/Features/Home/Component/HomeRecommendationCard.swift`
- `Siboya/Features/Home/Component/HomeScriptRow.swift`

**순서**

1. 1·7번 시리즈의 `TitleImageN`, `TitleImageNCard` 이름과 8번째 순환을 기대하는 테스트를 먼저 작성한다.
2. 테스트가 컴파일 또는 assertion 단계에서 실패하는지 확인한다.
3. `HomeArtworkSeries`와 역할별 계산 프로퍼티를 최소 구현한다.
4. `HomeScriptItem`이 원시 에셋명 대신 시리즈를 보관하도록 변경한다.
5. 추천 카드는 card 이름, 행은 기본 이름을 사용하도록 바꾸고 기존 preview와 테스트 픽스처를 갱신한다.
6. 집중 테스트가 통과하는지 확인한다.

## 2. Home 표시 상태 변환을 TDD로 구현

**추가 파일**

- `SiboyaTests/Home/HomeViewStateTests.swift`
- `Siboya/Features/Home/Model/HomeViewState.swift`

**순서**

1. 21개 주차 이미지가 1~7을 세 번 반복하는 테스트를 작성한다.
2. 여섯 대본의 행 이미지, 카테고리 순서와 내부 대본 순서를 검증한다.
3. 현재 주차 추천 ID 연결, 추천 대본의 목록 유지, 연결 실패 시 추천만 숨기는 시나리오를 작성한다.
4. 프로필 누락, 빈 제목·카테고리 제외 시나리오를 작성한다.
5. 실패를 확인한 뒤 `HomeRecommendationState`, `HomeScriptCategory`, `HomeViewState`, `HomeViewStateBuilder`를 최소 구현한다.
6. 집중 테스트가 통과하는지 확인한다.

## 3. 데이터 로딩 모델을 연결

**추가 파일**

- `Siboya/Features/Home/Model/HomeScreenModel.swift`

**수정 파일**

- `SiboyaTests/Home/HomeViewStateTests.swift`

**순서**

1. 저장소 프로필과 번들 문서를 읽었을 때 화면 상태가 갱신되는 테스트를 먼저 작성한다.
2. `@MainActor`, `@Observable` 기반 `HomeScreenModel`을 구현한다.
3. 프로필·Home 문서·대본 문서 로딩 실패를 각각 독립적인 `nil`로 변환해 부분 화면 정책을 유지한다.
4. 모델 집중 테스트가 통과하는지 확인한다.

## 4. Home 화면과 하단 탭 바 조립

**추가 파일**

- `Siboya/Features/Home/Component/HomeBottomTabBar.swift`
- `Siboya/Features/Home/View/HomeView.swift`

**수정 파일**

- `Siboya/Features/Home/View/ContentView.swift`

**순서**

1. Home 탭 바의 태담·약속 선택 전달을 검증 가능한 함수로 두고 단위 테스트를 추가한다.
2. Figma의 20pt 좌우 여백, 텍스트 계층, 230pt 추천 카드, 카테고리 간격을 `HomeView`에서 구성한다.
3. 탭 바를 safe-area inset으로 고정하고 태담 선택 상태 및 약속 callback을 구현한다.
4. `ContentView`가 환경 `ModelContext`로 저장소를 만들고 SCRUM-28의 `ensureBabyProfile`을 멱등적으로 호출한 다음 `HomeScreenModel`을 연결하도록 변경한다.
5. 정상·부분 빈 상태 preview를 추가하고 모든 수정 Swift 코드에 한국어 주석을 동기화한다.

## 5. 전체 검증과 변경 범위 점검

1. Home 집중 테스트를 실행한다.
2. 전체 `SiboyaTests`를 실행한다.
3. iOS Simulator 대상 Debug 빌드를 실행한다.
4. SwiftLint가 저장소에 구성되어 있으면 실행한다.
5. `rg`와 diff로 새 Swift 선언·분기·상태 변경의 한국어 주석을 점검한다.
6. `project.pbxproj`와 `img_profile`의 기존 사용자 변경이 작업 diff/커밋에 포함되지 않았는지 확인한다.
