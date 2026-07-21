# Home(태담 탭) 기능 스펙

- **상태**: approved
- **작성일**: 2026-07-21
- **최종 수정일**: 2026-07-21
- **적용 범위**: Home의 주차별 추천 태담과 카테고리별 대본 목록
- **공통 계약**: [태담 공통 데이터 계약](./taedam-common-contracts.md)
- **디자인 기준**: [Figma Home](https://www.figma.com/design/20KajaVVEkuuENa1HdSXux/C4---%EC%B1%8C%EB%A6%B0%EC%A7%80-%EC%8B%AD%EC%98%A4%EC%95%BC?node-id=1009-12231)

## 1. 목적

사용자가 현재 임신 주차에 맞는 추천 태담을 먼저 확인하고, 카테고리별 대본 목록에서 원하는 대본을 골라 대본·생각힌트 미리보기로 이동하게 한다.

이 문서에서 **Home**은 앱의 `태담` 탭 첫 화면을 뜻한다. Home은 대본을 탐색하고 선택하는 화면이며 태담 세션이나 버킷리스트를 생성하지 않는다.

## 2. 현재 코드와 View 담당 경계

- 최신 `develop`의 `ContentView`는 아직 `Text("Siboya")`만 표시하므로 Home 구현은 시작 전 상태다.
- 아기 프로필 조회는 병합된 `TaedamRepository.fetchBabyProfile()`을 사용한다.
- 번들 대본은 PR #8로 병합된 `BundledTaedamScriptLoader.load()`와 `TaedamScriptContent`를 기준으로 한다.
- 주차별 추천 헤드라인과 추천 대본 ID는 `home-weekly-content.json`을 기준으로 한다.
- `ScriptRepository`와 `ScriptSelectionDTO`는 SSD에 정의된 통합 경계지만 현재 원격 코드에는 없다. 연결 담당자가 공통 타입을 추가하기 전까지 View에서 존재하는 타입처럼 참조하지 않는다.
- Home View는 전달받은 화면 상태를 그리고 탭 이벤트를 상위 ViewModel·Coordinator에 알리는 역할만 담당한다. `ModelContext` 생성, JSON 디코딩, SwiftData 저장·수정은 View 안에서 처리하지 않는다.
- Home ViewModel 또는 상위 조정자가 `BabyProfile`, 주차별 Home 콘텐츠와 번들 대본을 읽어 표시용 상태를 만든다. View는 태명, 추천 설명, 대본 목록과 선택 callback만 받도록 구성한다.

## 3. 화면 구성과 책임

### 사용자·추천 영역

- `BabyProfile.nickname`을 화면의 Large Title로 표시한다.
- `BabyProfile.gestationalWeek`와 `BundledTaedamScriptLoader.load().scripts` 결과를 이용해 이번 주 추천 대본을 결정한다.
- 추천 영역에는 `이번주 추천`, 현재 주차에 대한 추천 설명, 대본 대표 이미지와 대본 제목을 표시한다.
- 추천 설명은 `home-weekly-content.json`에서 `BabyProfile.gestationalWeek`가 같은 항목의 `headline`을 표시한다.
- `recommendedScriptID`와 같은 `scripts[].id`를 가진 대본을 추천 카드에 표시한다.
- 현재 20~40주 항목은 번들 대본 6개의 기존 UUID를 JSON 순서대로 반복 연결한다.
- 연결된 대본을 찾지 못하면 해당 추천 카드만 숨기며 오류 UI를 표시하지 않는다.
- 추천 카드를 선택하면 해당 대본의 `ScriptSelectionDTO`를 대본·생각힌트 미리보기에 전달한다.

### 카테고리별 대본 영역

- 전체 대본을 `category`로 묶어 카테고리별 섹션으로 표시한다.
- 카테고리와 카테고리 안의 대본 순서는 번들 JSON의 최초 등장 순서를 유지한다.
- 각 대본 행에는 대표 이미지, 대본 제목과 대상 임신 주차를 표시한다.
- 대본 행을 선택하면 해당 대본의 `ScriptSelectionDTO`를 대본·생각힌트 미리보기에 전달한다.
- 목록은 세로로 스크롤하며 하단 탭 바는 화면 하단에 유지한다.
- 하단 탭 바에는 `태담`과 `약속`을 표시하고 이 화면에서는 `태담`을 선택 상태로 표시한다.

## 4. 추천 대본 선정 정책

1. `BabyProfile.gestationalWeek`와 같은 Home 주차 항목을 정확히 하나 선택한다.
2. 해당 항목의 `recommendedScriptID`와 같은 `scripts[].id`를 가진 대본을 추천 카드에 표시한다.
3. 20주부터 번들 대본의 JSON 배열 순서를 기준으로 6개 UUID를 반복 사용한다. 26주, 32주, 38주에서 첫 번째 대본으로 다시 순환한다.
4. ID에 대응하는 대본이 없으면 해당 추천 카드만 숨긴다.
5. 추천 대본도 아래 카테고리 목록에서 제외하지 않는다.

## 5. 화면 입출력

| 구분 | 데이터 |
|---|---|
| 입력 | 없음 |
| 사용자 조회 | `TaedamRepository.fetchBabyProfile()` |
| Home 콘텐츠 조회 | `HomeWeeklyContentLoader.load().weeks` |
| 대본 조회 | `BundledTaedamScriptLoader.load().scripts`; 추후 `ScriptRepository.fetchScripts()`로 감쌀 수 있음 |
| 표시 | 태명, 이번 주 추천, 카테고리 이름, 대본 이미지·제목·대상 주차 |
| 선택 결과 | 목표 계약은 `ScriptSelectionDTO`; 현재 공통 코드에 타입 추가 필요 |

## 6. 표시 상태

- **loading**: 아기 프로필, 주차별 Home JSON과 번들 대본 JSON을 로드·검증한다.
- **loaded**: 성공적으로 읽고 검증한 태명, 주차별 헤드라인, 추천 대본과 카테고리별 대본만 표시한다.

번들 정적 데이터이므로 별도의 오류 문구, 팝업이나 `새로고침` 버튼을 제공하지 않는다. 프로필, Home 주차 항목, 추천 대본 연결 또는 개별 대본이 없거나 유효하지 않으면 해당 데이터에 의존하는 영역만 숨기고 나머지 정상 데이터는 계속 표시한다. 표시할 데이터가 하나도 없으면 탭과 화면 기본 구조만 유지한다.

## 7. 사용자 행동

1. 추천 카드 또는 대본 행을 탭하면 View는 해당 대본의 `scriptID`와 `scriptVersion`을 선택 callback으로 전달한다.
2. 상위 ViewModel·Coordinator가 `ScriptSelectionDTO`를 만들고 대본·생각힌트 미리보기 화면을 push한다. 공통 타입이 추가되기 전에는 callback의 두 원시 값을 사용할 수 있다.
3. 같은 항목을 연속 탭해도 미리보기 화면을 중복으로 열지 않는다.

## 8. Figma와 현재 데이터 차이

| 항목 | Figma Home | 현재 번들 JSON·Assets | 구현 원칙 |
|---|---|---|---|
| 임신 주차 | 카드와 행에 `22주차` | 6개 대본 모두 `20주차`이며 테스트도 20주차를 기대 | JSON 값을 표시하므로 현재는 `20주차`를 표시한다 |
| 추천 설명 | `아빠의 낮은 목소리가 잘 들리는 시기` | 주차별 Home JSON의 20주차 `headline` | 현재 프로필 주차와 같은 JSON 값을 표시한다 |
| 추천 대본 연결 | 추천 카드 존재 | 기존 6개 대본 UUID를 20~40주에 순환 연결 | JSON의 ID로 대본을 찾고 연결 실패 시 해당 카드만 숨긴다 |
| 카테고리·대본 | `멀리멀리 대모험` 아래 `오후의 동네 산책`, `조용한 도서관 구석에서`, `시끌시끌 공원` | 두 제목은 `밖으로 한 걸음`이며 `시끌시끌 공원`은 없음 | JSON의 카테고리와 대본 목록을 그대로 표시한다 |
| 대표 이미지 | Figma 이미지 존재 | JSON에 asset 이름은 있으나 해당 imageset은 브랜치에 없음 | 이미지가 없으면 공통 `script_artwork_placeholder`를 표시하고 데이터 로딩 실패로 처리하지 않는다 |

화면 모양은 Figma를 따르고 위 콘텐츠 차이는 JSON을 우선한다. View는 데이터가 바뀌어도 다시 구현하지 않도록 동적 목록과 주입된 표시값으로 만든다.

## 9. 불변 조건

1. Home은 대본, 프로필 또는 `BucketListItem`을 생성·수정·삭제하지 않는다.
2. 빈 `category`나 유효하지 않은 대본은 해당 항목만 표시하지 않는다.
3. 동일한 `category` 문자열은 하나의 섹션으로 표시한다.
4. 추천 카드와 목록 행은 같은 `ScriptSelectionDTO` 생성 규칙을 사용한다.
5. 새로 저장된 버킷리스트는 Home의 추천 대본이나 카테고리 구성에 영향을 주지 않는다.
