# Script Preview Top Safe Area Design

## 목적

`ScriptPreviewHero`가 상단 safe area 아래에서 시작하지 않고 디바이스 화면의 물리적 최상단부터 표시되게 한다. `ScriptPreviewView`에서도 같은 full-bleed 배치를 사용하면서 시스템 뒤로가기 버튼과 하단 준비하기 버튼의 기존 동작은 유지한다.

## 적용 범위

- `Siboya/Features/Home/Component/ScriptPreviewHero.swift`
- `Siboya/Features/Home/View/ScriptPreviewView.swift`
- 관련 Home 미리보기 컴포넌트·View 테스트

권한, sheet, `TaedamScreen`, 대본 데이터와 이미지 에셋 매핑은 변경하지 않는다.

## 레이아웃 설계

1. `ScriptPreviewHero`는 상단 safe area를 무시하는 full-bleed 컴포넌트임을 명시한다.
2. Hero의 `TitleImageNBack` 배경과 132pt Thumbnail을 포함한 전체 Hero 레이아웃은 화면 좌표의 최상단부터 시작한다.
3. `ScriptPreviewView`의 세로 `ScrollView`도 top safe area까지 확장해 Hero의 full-bleed 계약이 실제 화면에서 잘리지 않게 한다.
4. NavigationStack의 시스템 뒤로가기 버튼은 제거하지 않고 Hero 위에 오버레이된 상태로 유지한다.
5. navigation bar 배경은 Hero가 최상단까지 보이도록 투명하게 유지한다.
6. 하단 `safeAreaInset`과 `ScriptPreviewBottomBar`는 기존처럼 하단 safe area를 존중한다.
7. 본문, 소요시간, sheet, Alert와 full-screen cover의 구조와 상태 전이는 변경하지 않는다.

## 구현 방향

- `ScriptPreviewHero`는 top safe area 무시 여부를 컴포넌트 계약으로 드러내고, body에 `.ignoresSafeArea(edges: .top)`을 적용한다.
- `ScriptPreviewView`는 ScrollView에 `.ignoresSafeArea(edges: .top)`을 적용하고 navigation bar 배경을 숨긴다.
- 음수 padding이나 기기별 safe-area 높이 계산은 사용하지 않는다. 시스템 safe-area API가 기기별 상태바·Dynamic Island 차이를 처리하게 한다.
- 변경된 Swift 코드와 테스트에는 역할과 레이아웃 이유를 설명하는 한국어 주석을 작성한다.

## 테스트

1. `ScriptPreviewHero`가 top safe area 무시 계약을 제공하는지 검증한다.
2. `ScriptPreviewView`가 같은 계약으로 ScrollView를 최상단까지 확장하는지 검증한다.
3. 기존 Thumbnail 132pt, Back 상단 정렬, Dynamic Type 높이 확장 테스트가 계속 통과하는지 확인한다.
4. 전체 `SiboyaTests`, SwiftLint와 Debug Simulator 빌드를 실행한다.

## 완료 조건

1. Hero 배경이 상단 safe area 아래가 아닌 화면 최상단에서 시작한다.
2. 실제 `ScriptPreviewView`에서도 동일한 위치가 유지된다.
3. 시스템 뒤로가기 버튼은 Hero 위에서 계속 동작한다.
4. 하단 준비하기 버튼은 기존 safe area 배치를 유지한다.
5. 기존 미리보기·권한·세션 흐름에 회귀가 없다.
