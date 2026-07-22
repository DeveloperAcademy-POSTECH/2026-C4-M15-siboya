# Home Weekly Content Implementation Plan

**Goal:** 번들에 포함된 20~40주 Home 헤드라인을 기존 태담 대본 6개와 순환 연결하고, View 구현 전에 타입 안전한 모델·로더·테스트를 준비한다.

**Architecture:** Home 전용 주차 데이터는 `Siboya/Resources/Home/home-weekly-content.json`에 둔다. 대본 제목·이미지·본문은 복제하지 않고 `recommendedScriptID`로 `taedam-scripts.json`을 참조한다. 현재 대본이 6개이므로 20주부터 대본 JSON 배열 순서대로 UUID를 반복 사용한다.

**Tech Stack:** Swift 6, Foundation `Codable`, Swift Testing, Xcode 26.5, iOS 26.5

## 확정 조건

- Figma는 화면 표현의 기준이고 JSON은 문구·주차·목록·식별자의 기준이다.
- 20~40주 모든 주차에 정확히 하나의 Home 콘텐츠를 둔다.
- `recommendedScriptID`는 필수 UUID이며 `null`을 허용하지 않는다.
- 6개 대본의 기존 UUID를 다시 발급하지 않고 그대로 사용한다.
- 20~25주에 대본 1~6을 연결하고 26주, 32주, 38주에서 대본 1부터 다시 순환한다.
- Home JSON에 대본 제목, 이미지 이름, 문장, 생각힌트를 중복 저장하지 않는다.
- 이번 단계에서는 Home·미리보기·준비자세 View를 구현하지 않는다.
- 푸시는 사용자 확인을 받은 뒤 `feature/SCRUM-27-home-preview-preparation` 브랜치에만 수행한다.

## 데이터 누락 정책

- 앱 번들 정적 데이터이므로 네트워크 오류 UI와 새로고침 버튼을 제공하지 않는다.
- 프로필, 주차 항목, 추천 대본 연결 또는 개별 대본이 없거나 유효하지 않으면 해당 데이터에 의존하는 영역만 숨긴다.
- 정상적으로 읽고 검증한 데이터는 다른 항목의 실패와 관계없이 계속 표시한다.
- Home에서 유효하게 연결된 대본만 선택할 수 있게 하므로, 대본 조회가 실패한 경우 미리보기와 준비자세를 열지 않는다.

## 작업 범위

### 1. 테스트로 데이터 계약 고정

파일: `SiboyaTests/Home/HomeWeeklyContentDocumentTests.swift`

- [x] 20~40주가 순서대로 한 번씩 존재하는지 검사한다.
- [x] 모든 헤드라인이 비어 있지 않은지 검사한다.
- [x] 21개 추천 ID가 번들 대본 6개 ID를 순서대로 반복한 배열과 같은지 검사한다.
- [x] 정확한 주차 조회와 범위 밖 조회를 검사한다.
- [x] `recommendedScriptID`가 UUID로 디코딩되는지 검사한다.

### 2. 모델과 로더 추가

파일:

- `Siboya/Features/Home/Model/HomeWeeklyContentDocument.swift`
- `Siboya/Features/Home/Service/BundledHomeWeeklyContentLoader.swift`

- [x] `HomeWeeklyContentDocument`와 `HomeWeeklyContent`를 정의한다.
- [x] `recommendedScriptID`를 필수 `UUID`로 정의한다.
- [x] 임신 주차로 항목을 찾는 `content(forGestationalWeek:)`를 제공한다.
- [x] `Home` 하위 디렉터리와 번들 루트 fallback을 지원하는 로더를 추가한다.

### 3. 20~40주 JSON 추가

파일: `Siboya/Resources/Home/home-weekly-content.json`

- [x] 기획 Notion의 20~40주 헤드라인을 저장한다.
- [x] 기존 6개 대본 UUID를 21개 항목에 순환 연결한다.
- [x] `taedam-scripts.json`은 수정하지 않는다.

### 4. 검증과 커밋

- [x] 집중 테스트 `HomeWeeklyContentDocumentTests`를 통과시킨다.
- [x] 전체 `SiboyaTests`를 통과시킨다.
- [x] SwiftLint 신규 경고가 없는지 확인한다.
- [ ] 문서와 데이터 계층 변경을 로컬 커밋한다.
- [ ] 변경 범위와 테스트 결과를 사용자에게 보여주고 푸시 승인을 받는다.
- [ ] 승인 후 SCRUM-27 브랜치에 푸시한다.

## 완료 조건

- `home-weekly-content.json`만 수정해 주차별 헤드라인과 추천 대본 연결을 바꿀 수 있다.
- 모든 추천 ID가 실제 번들 대본 한 개와 정확히 연결된다.
- 데이터 누락 시 오류 UI 없이 유효한 데이터만 노출한다는 정책이 기능 스펙과 공통 계약에 동일하게 반영되어 있다.
- View 구현 파일은 변경하지 않는다.
